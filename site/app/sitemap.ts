import type { MetadataRoute } from "next";
import { getSiteConfig } from "../lib/site-config";

export default function sitemap(): MetadataRoute.Sitemap {
  const { siteUrl } = getSiteConfig();

  return [
    {
      url: siteUrl,
      priority: 1,
    },
  ];
}
