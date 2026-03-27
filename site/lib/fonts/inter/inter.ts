// src/fonts/inter/inter.ts
import localFont from "next/font/local";

// Variable font option (if you prefer to use the variable font version)
export const inter = localFont({
  src: [
    {
      path: "./InterVariable.woff2",
      style: "normal",
    },
    {
      path: "./InterVariable-Italic.woff2",
      style: "italic",
    },
  ],
  display: "swap",
  variable: "--font-inter",
});
