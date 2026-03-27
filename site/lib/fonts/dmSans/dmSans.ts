// src/fonts/dmSans/dmSans.ts
import localFont from "next/font/local";

// Variable font option
export const dmSans = localFont({
  src: [
    {
      path: "./DMSans[opsz,wght].woff2",
      style: "normal",
    },
    {
      path: "./DMSans-Italic[opsz,wght].woff2",
      style: "italic",
    },
  ],
  display: "swap",
  variable: "--font-dm-sans",
});
