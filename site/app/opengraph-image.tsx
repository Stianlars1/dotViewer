import { ImageResponse } from "next/og";

export const size = {
  width: 1200,
  height: 630,
};

export const contentType = "image/png";

export default function OpenGraphImage() {
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          position: "relative",
          overflow: "hidden",
          background:
            "radial-gradient(circle at top left, rgba(92, 155, 255, 0.22), transparent 28%), linear-gradient(180deg, #f9fbff 0%, #eef4fb 55%, #f7fbff 100%)",
          color: "#0f172a",
          fontFamily: "SF Pro Display, Arial, sans-serif",
        }}
      >
        <div
          style={{
            position: "absolute",
            top: 76,
            left: -30,
            width: 280,
            height: 280,
            borderRadius: 999,
            background: "radial-gradient(circle, rgba(24,104,255,0.18), transparent 72%)",
          }}
        />
        <div
          style={{
            display: "flex",
            width: "100%",
            padding: "72px 78px",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <div style={{ display: "flex", flexDirection: "column", maxWidth: 680 }}>
            <div
              style={{
                fontSize: 28,
                letterSpacing: "0.12em",
                textTransform: "uppercase",
                color: "rgba(15, 23, 42, 0.54)",
              }}
            >
              dotViewer
            </div>
            <div
              style={{
                marginTop: 22,
                fontSize: 72,
                lineHeight: 0.96,
                letterSpacing: "-0.07em",
                fontWeight: 700,
              }}
            >
              Preview markdown, config, and code files Finder doesn&apos;t handle well.
            </div>
            <div
              style={{
                marginTop: 24,
                fontSize: 30,
                lineHeight: 1.35,
                color: "rgba(15, 23, 42, 0.7)",
                maxWidth: 620,
              }}
            >
              Inspect technical files instantly in Quick Look instead of opening an editor.
            </div>
          </div>

          <div
            style={{
              width: 260,
              height: 260,
              borderRadius: 72,
              background:
                "radial-gradient(circle at top left, rgba(255,255,255,0.9), rgba(255,255,255,0.66) 22%, transparent 42%), linear-gradient(180deg, #f9fbff 0%, #ebf2ff 100%)",
              border: "1px solid rgba(15,23,42,0.08)",
              boxShadow: "0 30px 80px rgba(15, 23, 42, 0.12)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <div
              style={{
                width: 182,
                height: 182,
                borderRadius: 56,
                background:
                  "linear-gradient(180deg, rgba(79,150,255,0.22), rgba(79,150,255,0.1))",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <div
                style={{
                  width: 110,
                  height: 110,
                  borderRadius: 999,
                  border: "18px solid #1762ff",
                  background: "#ffffff",
                  boxShadow: "0 10px 30px rgba(23,98,255,0.14)",
                }}
              />
            </div>
          </div>
        </div>
      </div>
    ),
    size,
  );
}
