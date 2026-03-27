import localFont from "next/font/local";

export const geistSans = localFont({
  src: "./Geist[wght].woff2",
  display: "swap",
  variable: "--font-geist-sans",
});

// Variable font option
export const geistMono = localFont({
  src: "./GeistMono[wght].woff2",
  display: "swap",
  variable: "--font-geist-mono",
});
