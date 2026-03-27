import type { MetadataRoute } from "next";
import { getSiteConfig } from "../lib/site-config";

export default function robots(): MetadataRoute.Robots {
  const { siteUrl } = getSiteConfig();

  return {
    rules: {
      userAgent: "*",
      allow: "/",
    },
    host: siteUrl,
    sitemap: `${siteUrl}/sitemap.xml`,
  };
}
