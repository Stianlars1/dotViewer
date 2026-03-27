import type { Metadata } from "next";
import "./globals.css";
import { getSiteConfig } from "../lib/site-config";

const { siteUrl } = getSiteConfig();

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "dotViewer — Preview markdown, config, and code files in Quick Look",
  description:
    "Preview markdown, config, and code files Finder does not handle well. Inspect technical files instantly in Quick Look instead of opening an editor.",
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: "dotViewer",
    description:
      "A better Quick Look experience for markdown, config, logs, and code files on macOS.",
    url: siteUrl,
    siteName: "dotViewer",
    type: "website",
    images: [
      {
        url: "/opengraph-image",
        width: 1200,
        height: 630,
        alt: "dotViewer website preview",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "dotViewer",
    description:
      "Preview markdown, config, and code files Finder does not handle well.",
    images: ["/opengraph-image"],
  },
  applicationName: "dotViewer",
  category: "developer tools",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
