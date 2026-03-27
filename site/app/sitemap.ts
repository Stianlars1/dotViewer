import type { MetadataRoute } from "next";
import { getSiteConfig } from "../lib/site-config";

export default function sitemap(): MetadataRoute.Sitemap {
  const { siteUrl } = getSiteConfig();

  return [
    {
      url: siteUrl,
      changeFrequency: "weekly",
      priority: 1,
    },
    {
      url: `${siteUrl}/download`,
      changeFrequency: "daily",
      priority: 0.9,
    },
  ];
}
