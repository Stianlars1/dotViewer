from PIL import Image, ImageDraw, ImageFilter
import numpy as np

SRC = "/Users/stian/Developer/macOS Apps/v1/dotViewer/dotViewer/Assets.xcassets/AppIcon.appiconset/dotViewer_logo_1024.png"
OUT_DIR = "output/imagegen"

img = Image.open(SRC).convert("RGBA")
arr = np.asarray(img).astype(np.float32) / 255.0
h, w = arr.shape[:2]
Y = np.arange(h)[:, None]
X = np.arange(w)[None, :]

r = arr[..., 0]
g = arr[..., 1]
b = arr[..., 2]
mx = np.maximum(np.maximum(r, g), b)
mn = np.minimum(np.minimum(r, g), b)
# HSV-like saturation/value
sat = np.where(mx > 0, (mx - mn) / mx, 0)
val = mx

# 1) Estimate lens center using dark blue region (fallback thresholds)
blue_dom = (b > r) & (b > g)
mask_dark = blue_dom & (mx < 0.35)
mask_dark &= (Y > 150) & (Y < 700) & (X > 200) & (X < 820)
ys, xs = np.where(mask_dark)
if len(xs) == 0:
    mask_dark = blue_dom & (mx < 0.45)
    mask_dark &= (Y > 150) & (Y < 700) & (X > 200) & (X < 820)
    ys, xs = np.where(mask_dark)
if len(xs) == 0:
    mask_dark = blue_dom & (mx < 0.55)
    mask_dark &= (Y > 150) & (Y < 700) & (X > 200) & (X < 820)
    ys, xs = np.where(mask_dark)
if len(xs) == 0:
    raise SystemExit("Failed to detect lens center")

cx = xs.mean()
cy = ys.mean()

# 2) Inner lens radius from dark pixels (use 90th percentile to avoid handle)
d = np.sqrt((xs - cx) ** 2 + (ys - cy) ** 2)
r_inner = float(np.quantile(d, 0.9))

# 3) Outer ring radius from bright low-sat pixels (upper/mid area)
mask_bright = (val > 0.85) & (sat < 0.25) & (Y < 750)
ys2, xs2 = np.where(mask_bright)
if len(xs2) == 0:
    r_outer = r_inner + 40.0
else:
    d2 = np.sqrt((xs2 - cx) ** 2 + (ys2 - cy) ** 2)
    r_outer = float(np.quantile(d2, 0.95))

# Lens mask
D = np.sqrt((X - cx) ** 2 + (Y - cy) ** 2)
mask_lens = D <= r_inner

# 4) Eye mask: detect bright eye white, then build ellipse
band = (np.abs(Y - cy) <= 150)
eye_white = mask_lens & band & (val > 0.82) & (sat < 0.35)
ys3, xs3 = np.where(eye_white)
if len(xs3) > 0:
    x_min, x_max = int(xs3.min()), int(xs3.max())
    y_min, y_max = int(ys3.min()), int(ys3.max())
else:
    # fallback bbox around center
    x_min, x_max = int(cx - 230), int(cx + 230)
    y_min, y_max = int(cy - 130), int(cy + 130)

pad = 10
x_min = max(0, x_min - pad)
x_max = min(w - 1, x_max + pad)
y_min = max(0, y_min - pad)
y_max = min(h - 1, y_max + pad)

ellipse = Image.new("L", (w, h), 0)
draw = ImageDraw.Draw(ellipse)
draw.ellipse([x_min, y_min, x_max, y_max], fill=255)
mask_eye = (np.asarray(ellipse) > 0) & mask_lens

# 5) Code blocks mask
mask_code = mask_lens & (~mask_eye) & (val > 0.45) & (sat > 0.25)
# Clean small noise
code_img = Image.fromarray((mask_code * 255).astype(np.uint8), mode="L")
code_img = code_img.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
mask_code = np.asarray(code_img) > 0

# 6) Brackets mask (outside lens, left/right regions)
mask_outside = D > (r_outer + 15)
mask_lr = (X < (cx - 300)) | (X > (cx + 300))
mask_y = (Y > (cy - 190)) & (Y < (cy + 240))
mask_color = (val > 0.4) & (sat > 0.2) & (b > r * 1.05) & (g > r * 0.7)
mask_brackets = mask_outside & mask_lr & mask_y & mask_color
# soften edges
br_img = Image.fromarray((mask_brackets * 255).astype(np.uint8), mode="L")
br_img = br_img.filter(ImageFilter.MaxFilter(3))
mask_brackets = np.asarray(br_img) > 0

# 7) Handle mask via k-means in wedge region
angles = np.degrees(np.arctan2(Y - cy, X - cx))
angles = (angles + 360) % 360
mask_wedge = (angles > 36) & (angles < 70) & (D > (r_outer + 10)) & (D < (r_outer + 260))
# sample pixels
pixels = arr[mask_wedge][..., :3]
if pixels.shape[0] > 0:
    rng = np.random.default_rng(1)
    if pixels.shape[0] > 60000:
        idx = rng.choice(pixels.shape[0], 60000, replace=False)
        pixels_sample = pixels[idx]
    else:
        pixels_sample = pixels
    # k-means k=3
    k = 3
    centers = pixels_sample[rng.choice(pixels_sample.shape[0], k, replace=False)]
    for _ in range(12):
        dists = ((pixels_sample[:, None, :] - centers[None, :, :]) ** 2).sum(axis=2)
        labels = dists.argmin(axis=1)
        for i in range(k):
            if np.any(labels == i):
                centers[i] = pixels_sample[labels == i].mean(axis=0)
    # classify all wedge pixels
    all_pixels = pixels
    dists_all = ((all_pixels[:, None, :] - centers[None, :, :]) ** 2).sum(axis=2)
    labels_all = dists_all.argmin(axis=1)
    # determine background cluster as middle brightness
    brightness = centers.max(axis=1)
    order = np.argsort(brightness)
    bg_cluster = int(order[1])  # middle
    handle_labels = set([int(order[0]), int(order[2])])
    handle_mask_wedge = np.isin(labels_all, list(handle_labels))
    mask_handle = np.zeros((h, w), dtype=bool)
    mask_handle[mask_wedge] = handle_mask_wedge
else:
    mask_handle = np.zeros((h, w), dtype=bool)

# Expand handle mask slightly and keep only bottom-right quadrant
handle_img = Image.fromarray((mask_handle * 255).astype(np.uint8), mode="L")
handle_img = handle_img.filter(ImageFilter.MaxFilter(5))
mask_handle = np.asarray(handle_img) > 0
# Keep handle constrained to the wedge to avoid leaking into the right bracket.
mask_handle &= mask_wedge
mask_handle &= (X > (cx + 80)) & (Y > (cy + 80))

# 8) Magnifying glass mask: circle + handle, minus eye/code
mask_glass = (D <= (r_outer + 6)) | mask_handle
mask_glass &= (~mask_eye)
mask_glass &= (~mask_code)

# Helper to save layer

def save_layer(mask: np.ndarray, name: str):
    out = np.array(img)
    alpha = (mask.astype(np.uint8) * 255)
    out[..., 3] = alpha
    Image.fromarray(out).save(f"{OUT_DIR}/{name}.png")

save_layer(mask_eye, "layer-eye")
save_layer(mask_code, "layer-code-blocks")
save_layer(mask_glass, "layer-magnifying-glass")
save_layer(mask_brackets, "layer-code-curly-brackets")
# Split brackets into left (code) and right (curly) layers for convenience.
save_layer(mask_brackets & (X < cx), "layer-code-bracket")
save_layer(mask_brackets & (X > cx), "layer-curly-bracket")
