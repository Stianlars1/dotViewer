export type SupportRoutingLimitation = {
  badge: string;
  details: string;
  extensions: string[];
  id: string;
  summary: string;
  title: string;
};

export type SupportedFileRoutingLimitation = SupportRoutingLimitation & {
  matchedExtensions: string[];
};

const supportRoutingLimitations: SupportRoutingLimitation[] = [
  {
    id: "typescript-ts",
    badge: "macOS limitation",
    title: "System handler wins",
    extensions: ["ts"],
    summary:
      "dotViewer ships TypeScript support, but Finder Quick Look usually routes .ts files to macOS as MPEG-2 transport stream video instead.",
    details:
      "The shipped mapping exists, but macOS keeps the preview path. Use .cts or .mts when you need dotViewer to preview TypeScript in Finder.",
  },
  {
    id: "html-native-preview",
    badge: "macOS limitation",
    title: "Native HTML preview wins",
    extensions: ["htm", "html", "xhtml"],
    summary:
      "dotViewer ships HTML-family mappings, but macOS keeps the native HTML Quick Look renderer for these files.",
    details:
      "The shipped mapping exists, but Finder still prefers the system web preview instead of dotViewer's source-oriented view.",
  },
];

const limitationByExtension = new Map<string, SupportRoutingLimitation>();

for (const limitation of supportRoutingLimitations) {
  for (const extension of limitation.extensions) {
    limitationByExtension.set(extension, limitation);
  }
}

export function getSupportRoutingLimitation(
  extension: string | null | undefined,
): SupportRoutingLimitation | null {
  if (!extension) {
    return null;
  }

  return limitationByExtension.get(extension.trim().toLowerCase()) ?? null;
}

export function getRoutingLimitationsForExtensions(
  extensions: string[],
): SupportedFileRoutingLimitation[] {
  const grouped = new Map<string, SupportedFileRoutingLimitation>();

  for (const extension of extensions) {
    const limitation = getSupportRoutingLimitation(extension);
    if (!limitation) {
      continue;
    }

    const existing = grouped.get(limitation.id);
    if (existing) {
      existing.matchedExtensions.push(extension);
      continue;
    }

    grouped.set(limitation.id, {
      ...limitation,
      matchedExtensions: [extension],
    });
  }

  return [...grouped.values()].map((limitation) => ({
    ...limitation,
    matchedExtensions: [...new Set(limitation.matchedExtensions)].sort(),
  }));
}
