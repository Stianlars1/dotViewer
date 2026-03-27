import localFont from "next/font/local";

export const funnelDisplay = localFont({
  src: [
    {
      path: "./FunnelDisplay[wght].woff2",
      style: "normal",
    },
  ],
  display: "swap",
  variable: "--font-funnel-display",
});
