import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "dotViewer",
    short_name: "dotViewer",
    description: "Preview markdown, config, and code files Finder does not handle well.",
    start_url: "/",
    scope: "/",
    display: "standalone",
    background_color: "#f8fbff",
    theme_color: "#f8fbff",
    icons: [
      {
        src: "/brand/dotviewer-icon-light.png",
        sizes: "1024x1024",
        type: "image/png",
      },
    ],
  };
}
