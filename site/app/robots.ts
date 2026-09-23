import type { MetadataRoute } from "next";
import { getSiteConfig } from "../lib/site-config";

export default function robots(): MetadataRoute.Robots {
  const { siteUrl } = getSiteConfig();

  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/api/", "/stats"],
    },
    host: siteUrl,
    sitemap: `${siteUrl}/sitemap.xml`,
  };
}
