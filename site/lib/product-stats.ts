import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

type FileTypeEntry = {
  displayName?: string;
  extensions?: string[];
  filenames?: string[];
};

export type ProductStats = {
  extensions: number;
  fileTypes: number;
  filenameMappings: number;
  grammars: number;
};

export type SupportedFileTypeRecord = {
  id: string;
  displayName: string;
  extensions: string[];
  filenames: string[];
  mappingCount: number;
};

const moduleDir = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(moduleDir, "..", "..");
const defaultFileTypesPath = path.join(repoRoot, "dotViewer", "Shared", "DefaultFileTypes.json");
const treeSitterQueriesPath = path.join(repoRoot, "dotViewer", "HighlightXPC", "TreeSitterQueries");

function safeReadJson(filePath: string): FileTypeEntry[] {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8")) as FileTypeEntry[];
  } catch {
    return [];
  }
}

function safeCountScmFiles(dirPath: string): number {
  try {
    return fs.readdirSync(dirPath).filter((file) => file.endsWith(".scm")).length;
  } catch {
    return 0;
  }
}

export function getProductStats(): ProductStats {
  const entries = safeReadJson(defaultFileTypesPath);
  const extensions = new Set<string>();
  const filenames = new Set<string>();

  for (const entry of entries) {
    for (const ext of entry.extensions ?? []) {
      extensions.add(ext.toLowerCase());
    }

    for (const filename of entry.filenames ?? []) {
      filenames.add(filename.toLowerCase());
    }
  }

  return {
    extensions: extensions.size,
    fileTypes: entries.length,
    filenameMappings: filenames.size,
    grammars: safeCountScmFiles(treeSitterQueriesPath),
  };
}

export function getSupportedFileTypes(): SupportedFileTypeRecord[] {
  const entries = safeReadJson(defaultFileTypesPath);

  return entries
    .map((entry) => {
      const extensions = [...new Set((entry.extensions ?? []).map((value) => value.toLowerCase()))].sort();
      const filenames = [...new Set((entry.filenames ?? []).map((value) => value.toLowerCase()))].sort();
      const displayName = entry.displayName?.trim() || "Unnamed file type";

      return {
        id: `${displayName}__${extensions.join(",")}__${filenames.join(",")}`,
        displayName,
        extensions,
        filenames,
        mappingCount: extensions.length + filenames.length,
      };
    })
    .sort((left, right) => {
      const nameOrder = left.displayName.localeCompare(right.displayName, undefined, {
        sensitivity: "base",
      });
      if (nameOrder !== 0) {
        return nameOrder;
      }

      return right.mappingCount - left.mappingCount;
    });
}
