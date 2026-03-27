import type { Metadata } from "next";
import "./globals.css";
import { getSiteConfig } from "../lib/site-config";
import { CREATOR_NAME, CREATOR_URL } from "../lib/structured-data";
import { dmSans, geistMono, geistSans } from "../lib/fonts";

const { siteUrl } = getSiteConfig();

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: "dotViewer for macOS - Preview dotfiles, config files, markdown, and code in Quick Look",
    template: "%s | dotViewer",
  },
  description:
    "Preview `.gitignore`, `.env`, markdown, config files, plain text documents, logs, and source code in Finder Quick Look with dotViewer for macOS.",
  keywords: [
    "dotViewer",
    "macOS Quick Look extension",
    "preview dotfiles on macOS",
    "preview config files in Finder",
    "markdown Quick Look macOS",
    "preview .gitignore",
    "preview .env file",
    "Finder code preview",
    "plain text document preview macOS",
    "Quick Look source code",
  ],
  authors: [{ name: CREATOR_NAME, url: CREATOR_URL }],
  creator: CREATOR_NAME,
  publisher: CREATOR_NAME,
  category: "developer tools",
  applicationName: "dotViewer",
  alternates: {
    canonical: "/",
  },
  manifest: "/manifest.webmanifest",
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-image-preview": "large",
      "max-snippet": -1,
      "max-video-preview": -1,
    },
  },
  openGraph: {
    title: "dotViewer for macOS",
    description:
      "Preview dotfiles, config files, markdown, plain text documents, logs, and code files in Finder Quick Look.",
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
    title: "dotViewer for macOS",
    description:
      "Preview dotfiles, config files, markdown, plain text documents, logs, and code files in Finder Quick Look.",
    images: ["/opengraph-image"],
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className={`${geistMono.variable} ${geistSans.variable} ${dmSans.variable}`}>
        {children}
      </body>
    </html>
  );
}
