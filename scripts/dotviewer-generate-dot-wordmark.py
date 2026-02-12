#!/usr/bin/env python3
"""
Generate a custom dot-based wordmark as transparent SVG + PNG.

Usage:
  python3 scripts/dotviewer-generate-dot-wordmark.py
  python3 scripts/dotviewer-generate-dot-wordmark.py --text "dotViewer"
  python3 scripts/dotviewer-generate-dot-wordmark.py --text "MyBrand" --target-width 3840
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


GLYPHS: dict[str, tuple[str, ...]] = {
    " ": (
        "000",
        "000",
        "000",
        "000",
        "000",
        "000",
        "000",
    ),
    ".": (
        "000",
        "000",
        "000",
        "000",
        "000",
        "011",
        "011",
    ),
    "-": (
        "00000",
        "00000",
        "00000",
        "11111",
        "00000",
        "00000",
        "00000",
    ),
    "_": (
        "00000",
        "00000",
        "00000",
        "00000",
        "00000",
        "00000",
        "11111",
    ),
    "a": (
        "01110",
        "10001",
        "10001",
        "11111",
        "10001",
        "10001",
        "10001",
    ),
    "b": (
        "11110",
        "10001",
        "10001",
        "11110",
        "10001",
        "10001",
        "11110",
    ),
    "c": (
        "01110",
        "10001",
        "10000",
        "10000",
        "10000",
        "10001",
        "01110",
    ),
    "d": (
        "00001",
        "00001",
        "01111",
        "10001",
        "10001",
        "10001",
        "01111",
    ),
    "e": (
        "01110",
        "10001",
        "11111",
        "10000",
        "10000",
        "10001",
        "01110",
    ),
    "f": (
        "00111",
        "00100",
        "11110",
        "00100",
        "00100",
        "00100",
        "00100",
    ),
    "g": (
        "01111",
        "10001",
        "10001",
        "01111",
        "00001",
        "10001",
        "01110",
    ),
    "h": (
        "10000",
        "10000",
        "10110",
        "11001",
        "10001",
        "10001",
        "10001",
    ),
    "i": (
        "00100",
        "00000",
        "01100",
        "00100",
        "00100",
        "00100",
        "01110",
    ),
    "j": (
        "00010",
        "00000",
        "00110",
        "00010",
        "00010",
        "10010",
        "01100",
    ),
    "k": (
        "10001",
        "10010",
        "10100",
        "11000",
        "10100",
        "10010",
        "10001",
    ),
    "l": (
        "01100",
        "00100",
        "00100",
        "00100",
        "00100",
        "00100",
        "01110",
    ),
    "m": (
        "0000000",
        "0000000",
        "1101101",
        "1010011",
        "1010011",
        "1010011",
        "1010011",
    ),
    "n": (
        "00000",
        "00000",
        "10110",
        "11001",
        "10001",
        "10001",
        "10001",
    ),
    "o": (
        "01110",
        "10001",
        "10001",
        "10001",
        "10001",
        "10001",
        "01110",
    ),
    "p": (
        "11110",
        "10001",
        "10001",
        "11110",
        "10000",
        "10000",
        "10000",
    ),
    "q": (
        "01111",
        "10001",
        "10001",
        "01111",
        "00001",
        "00001",
        "00001",
    ),
    "r": (
        "00000",
        "00000",
        "10110",
        "11001",
        "10000",
        "10000",
        "10000",
    ),
    "s": (
        "01111",
        "10000",
        "10000",
        "01110",
        "00001",
        "00001",
        "11110",
    ),
    "t": (
        "00100",
        "00100",
        "11111",
        "00100",
        "00100",
        "00100",
        "00011",
    ),
    "u": (
        "00000",
        "00000",
        "10001",
        "10001",
        "10001",
        "10011",
        "01101",
    ),
    "v": (
        "00000",
        "00000",
        "10001",
        "10001",
        "10001",
        "01010",
        "00100",
    ),
    "w": (
        "0000000",
        "0000000",
        "1000101",
        "1000101",
        "1010101",
        "1010101",
        "0100010",
    ),
    "x": (
        "00000",
        "00000",
        "10001",
        "01010",
        "00100",
        "01010",
        "10001",
    ),
    "y": (
        "00000",
        "00000",
        "10001",
        "10001",
        "01111",
        "00001",
        "01110",
    ),
    "z": (
        "00000",
        "00000",
        "11111",
        "00010",
        "00100",
        "01000",
        "11111",
    ),
    "V": (
        "10001",
        "10001",
        "10001",
        "10001",
        "10001",
        "01010",
        "00100",
    ),
    "?": (
        "01110",
        "10001",
        "00010",
        "00100",
        "00100",
        "00000",
        "00100",
    ),
}


VARIANTS = {
    "blue": {
        "name": "blue",
        "fill": "url(#dotFillBlue)",
        "stroke": "#9CD8FF",
        "stroke_width_factor": 0.11,
        "highlight_fill": "#FFFFFF",
        "highlight_opacity": 0.24,
        "glow_filter": "url(#dotGlowBlue)",
        "defs": """
  <linearGradient id="dotFillBlue" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" stop-color="#9BD8FF"/>
    <stop offset="56%" stop-color="#4A98FF"/>
    <stop offset="100%" stop-color="#2E68F0"/>
  </linearGradient>
  <filter id="dotGlowBlue" x="-120%" y="-120%" width="340%" height="340%">
    <feDropShadow dx="0" dy="0" stdDeviation="1.25" flood-color="#56A8FF" flood-opacity="0.56"/>
  </filter>
""",
    },
    "white": {
        "name": "white",
        "fill": "#FFFFFF",
        "stroke": "#F3F7FF",
        "stroke_width_factor": 0.09,
        "highlight_fill": "#FFFFFF",
        "highlight_opacity": 0.34,
        "glow_filter": "url(#dotGlowWhite)",
        "defs": """
  <filter id="dotGlowWhite" x="-120%" y="-120%" width="340%" height="340%">
    <feDropShadow dx="0" dy="0" stdDeviation="1.25" flood-color="#FFFFFF" flood-opacity="0.25"/>
  </filter>
""",
    },
}


def get_glyph(char: str) -> tuple[str, ...]:
    if char in GLYPHS:
        return GLYPHS[char]
    lower = char.lower()
    if lower in GLYPHS:
        return GLYPHS[lower]
    return GLYPHS["?"]


def layout_dots(
    text: str,
    pitch: float,
    letter_spacing_cols: float,
    padding: float,
) -> tuple[list[tuple[float, float]], int, int]:
    dots: list[tuple[float, float]] = []
    cursor_x = padding
    row_count = 7
    max_row_pixels = row_count * pitch

    for index, char in enumerate(text):
        glyph = get_glyph(char)
        glyph_width = max(len(row) for row in glyph)

        for row_idx, row in enumerate(glyph):
            for col_idx, cell in enumerate(row):
                if cell == "1":
                    dots.append(
                        (
                            cursor_x + (col_idx * pitch) + (pitch / 2.0),
                            padding + (row_idx * pitch) + (pitch / 2.0),
                        )
                    )

        cursor_x += (glyph_width * pitch)
        if index < len(text) - 1:
            cursor_x += (letter_spacing_cols * pitch)

    width = int(round(cursor_x + padding))
    height = int(round(max_row_pixels + (padding * 2)))
    return dots, width, height


def build_svg(
    dots: list[tuple[float, float]],
    width: int,
    height: int,
    radius: float,
    variant: dict[str, str | float],
) -> str:
    stroke_width = radius * float(variant["stroke_width_factor"])
    glow_filter = variant["glow_filter"]

    circles = []
    highlights = []
    for x, y in dots:
        circles.append(
            (
                f'  <circle cx="{x:.2f}" cy="{y:.2f}" r="{radius:.2f}" '
                f'fill="{variant["fill"]}" stroke="{variant["stroke"]}" '
                f'stroke-width="{stroke_width:.2f}" filter="{glow_filter}"/>'
            )
        )
        highlights.append(
            (
                f'  <circle cx="{x - (radius * 0.24):.2f}" cy="{y - (radius * 0.30):.2f}" '
                f'r="{radius * 0.35:.2f}" fill="{variant["highlight_fill"]}" '
                f'opacity="{variant["highlight_opacity"]}"/>'
            )
        )

    circle_markup = "\n".join(circles)
    highlight_markup = "\n".join(highlights)

    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}">\n'
        "  <defs>\n"
        f'{variant["defs"]}'
        "  </defs>\n"
        "  <g>\n"
        f"{circle_markup}\n"
        "  </g>\n"
        "  <g>\n"
        f"{highlight_markup}\n"
        "  </g>\n"
        "</svg>\n"
    )


def convert_svg_to_png(svg_path: Path, png_path: Path, target_width: int | None) -> bool:
    converter = shutil.which("rsvg-convert")
    if not converter:
        return False

    command = [converter, str(svg_path), "-f", "png", "-o", str(png_path)]
    if target_width and target_width > 0:
        command.extend(["-w", str(target_width)])

    subprocess.run(command, check=True)
    return True


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--text", default="dotViewer", help="Text to render.")
    parser.add_argument(
        "--out-dir",
        default="icon/wordmark-dots",
        help="Output directory for generated assets.",
    )
    parser.add_argument(
        "--prefix",
        default="dotviewer-wordmark-dotfont",
        help="Filename prefix for generated files.",
    )
    parser.add_argument(
        "--dot-pitch",
        type=float,
        default=56.0,
        help="Distance between dot centers in the glyph grid.",
    )
    parser.add_argument(
        "--dot-radius-factor",
        type=float,
        default=0.34,
        help="Dot radius as factor of dot pitch.",
    )
    parser.add_argument(
        "--letter-spacing",
        type=float,
        default=1.25,
        help="Letter spacing measured in dot columns.",
    )
    parser.add_argument(
        "--padding",
        type=float,
        default=72.0,
        help="Transparent padding around wordmark.",
    )
    parser.add_argument(
        "--target-width",
        type=int,
        default=4096,
        help="PNG export width in pixels (preserves aspect ratio).",
    )
    parser.add_argument(
        "--no-png",
        action="store_true",
        help="Skip PNG conversion and only emit SVG.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    dots, width, height = layout_dots(
        text=args.text,
        pitch=args.dot_pitch,
        letter_spacing_cols=args.letter_spacing,
        padding=args.padding,
    )
    radius = args.dot_pitch * args.dot_radius_factor

    generated = []
    for variant_name, variant in VARIANTS.items():
        svg_name = f"{args.prefix}-{variant_name}.svg"
        svg_path = out_dir / svg_name
        svg_content = build_svg(
            dots=dots,
            width=width,
            height=height,
            radius=radius,
            variant=variant,
        )
        svg_path.write_text(svg_content, encoding="utf-8")
        generated.append(svg_path)

        if not args.no_png:
            png_name = f"{args.prefix}-{variant_name}.png"
            png_path = out_dir / png_name
            try:
                converted = convert_svg_to_png(svg_path, png_path, args.target_width)
            except subprocess.CalledProcessError as error:
                print(
                    f"Failed to convert {svg_name} to PNG: {error}",
                    file=sys.stderr,
                )
                return 1

            if converted:
                generated.append(png_path)
            else:
                print("rsvg-convert not found; PNG export skipped.", file=sys.stderr)
                break

    print("Generated assets:")
    for path in generated:
        print(f"- {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
