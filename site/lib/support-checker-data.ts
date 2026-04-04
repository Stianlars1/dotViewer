import { getSupportRoutingLimitation } from "./support-limitations";
import type {
  SupportRoutingLimitation,
  SupportedFileRoutingLimitation,
} from "./support-limitations";
import type { SupportedFileTypeRecord } from "./product-stats";

export type MatchKind = "extension" | "filename" | "name";

export type SearchMatch = {
  exact: boolean;
  kind: MatchKind;
  matchedValue: string;
  record: SupportedFileTypeRecord;
  score: number;
};

export function normalizeValue(value: string) {
  return value.trim().toLowerCase();
}

function basenameOf(value: string) {
  const segments = value.split(/[\\/]/);
  return segments[segments.length - 1] ?? value;
}

export function filenameCandidates(rawValue: string) {
  const basename = basenameOf(normalizeValue(rawValue));
  const candidates = new Set<string>();

  if (!basename) {
    return [];
  }

  candidates.add(basename);
  if (basename.startsWith(".")) {
    candidates.add(basename.slice(1));
  } else {
    candidates.add(`.${basename}`);
  }

  return [...candidates].filter(Boolean);
}

export function extensionCandidates(rawValue: string) {
  const normalized = normalizeValue(rawValue);
  const basename = basenameOf(normalized);
  const candidates = new Set<string>();

  if (!basename) {
    return [];
  }

  if (basename.startsWith(".")) {
    const withoutDot = basename.slice(1);
    if (!withoutDot) {
      return [];
    }

    const parts = withoutDot.split(".");
    for (let index = 0; index < parts.length; index += 1) {
      const candidate = parts.slice(index).join(".");
      if (candidate) {
        candidates.add(candidate);
      }
    }

    return [...candidates];
  }

  const parts = basename.split(".");
  if (parts.length === 1) {
    candidates.add(basename);
    return [...candidates];
  }

  for (let index = 1; index < parts.length; index += 1) {
    const candidate = parts.slice(index).join(".");
    if (candidate) {
      candidates.add(candidate);
    }
  }

  return [...candidates];
}

export function buildMatches(records: SupportedFileTypeRecord[], rawQuery: string) {
  const query = normalizeValue(rawQuery);
  const basename = basenameOf(query);
  const queryWithoutDot = query.replace(/^\./, "");
  const extensions = extensionCandidates(rawQuery);
  const filenames = filenameCandidates(rawQuery);

  if (!query) {
    return [];
  }

  const matches: SearchMatch[] = [];

  for (const record of records) {
    const displayName = record.displayName.toLowerCase();
    const exactFilename = record.filenames.find((filename) => {
      const normalizedFilename = filename.toLowerCase();
      return (
        filenames.includes(normalizedFilename) ||
        filenames.includes(normalizedFilename.replace(/^\./, ""))
      );
    });
    if (exactFilename) {
      matches.push({
        exact: true,
        kind: "filename",
        matchedValue: exactFilename,
        record,
        score: 520,
      });
      continue;
    }

    const exactExtension = record.extensions.find((extension) => extensions.includes(extension));
    if (exactExtension) {
      matches.push({
        exact: true,
        kind: "extension",
        matchedValue: `.${exactExtension}`,
        record,
        score: 470,
      });
      continue;
    }

    if (displayName === query || displayName === queryWithoutDot) {
      matches.push({
        exact: true,
        kind: "name",
        matchedValue: record.displayName,
        record,
        score: 430,
      });
      continue;
    }

    const partialFilename = record.filenames.find((filename) => {
      const normalizedFilename = filename.toLowerCase();
      return (
        normalizedFilename.includes(basename) ||
        normalizedFilename.replace(/^\./, "").includes(basename)
      );
    });
    if (partialFilename) {
      matches.push({
        exact: false,
        kind: "filename",
        matchedValue: partialFilename,
        record,
        score: partialFilename.startsWith(basename) ? 280 : 240,
      });
      continue;
    }

    const partialExtension = record.extensions.find((extension) => {
      return (
        extension.includes(queryWithoutDot) ||
        extensions.some((candidate) => extension.includes(candidate))
      );
    });
    if (partialExtension) {
      matches.push({
        exact: false,
        kind: "extension",
        matchedValue: `.${partialExtension}`,
        record,
        score: partialExtension.startsWith(queryWithoutDot) ? 260 : 220,
      });
      continue;
    }

    if (displayName.includes(query) || displayName.includes(queryWithoutDot)) {
      matches.push({
        exact: false,
        kind: "name",
        matchedValue: record.displayName,
        record,
        score: displayName.startsWith(queryWithoutDot) ? 210 : 180,
      });
    }
  }

  return matches.sort((left, right) => {
    if (left.score !== right.score) {
      return right.score - left.score;
    }

    if (left.record.mappingCount !== right.record.mappingCount) {
      return right.record.mappingCount - left.record.mappingCount;
    }

    return left.record.displayName.localeCompare(right.record.displayName);
  });
}

export function matchDescription(match: SearchMatch) {
  if (match.kind === "extension") {
    return `Matched shipped extension ${match.matchedValue}`;
  }

  if (match.kind === "filename") {
    return `Matched exact filename ${match.matchedValue}`;
  }

  return `Matched file type name ${match.matchedValue}`;
}

export function visibleValues(values: string[], prefix = "") {
  const visible = values.slice(0, 6);
  const hiddenCount = values.length - visible.length;

  return { hiddenCount, visible: visible.map((value) => `${prefix}${value}`) };
}

export function routingLimitationForMatch(
  match: SearchMatch | null,
  rawQuery: string,
  recordRoutingLimitations: SupportedFileRoutingLimitation[],
): SupportRoutingLimitation | null {
  if (!match || !match.exact || recordRoutingLimitations.length === 0) {
    return null;
  }

  const candidates = extensionCandidates(rawQuery);
  const limitedExtension = recordRoutingLimitations
    .flatMap((limitation) => limitation.matchedExtensions)
    .find((extension) => candidates.includes(extension));

  return getSupportRoutingLimitation(limitedExtension ?? null);
}
