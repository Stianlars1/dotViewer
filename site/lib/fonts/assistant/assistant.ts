// src/fonts/assistant/assistant.ts
import localFont from "next/font/local";

export const assistant = localFont({
  src: [
    {
      path: "./assistant-v23-latin-200.woff2",
      weight: "200",
      style: "normal",
    },
    {
      path: "./assistant-v23-latin-300.woff2",
      weight: "300",
      style: "normal",
    },
    {
      path: "./assistant-v23-latin-regular.woff2",
      weight: "400",
      style: "normal",
    },
    {
      path: "./assistant-v23-latin-500.woff2",
      weight: "500",
      style: "normal",
    },
    {
      path: "./assistant-v23-latin-600.woff2",
      weight: "600",
      style: "normal",
    },
    {
      path: "./assistant-v23-latin-700.woff2",
      weight: "700",
      style: "normal",
    },
    {
      path: "./assistant-v23-latin-800.woff2",
      weight: "800",
      style: "normal",
    },
  ],
  display: "swap",
  variable: "--font-assistant",
});
