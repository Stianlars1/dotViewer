import fs from "node:fs";
import path from "node:path";

type FileTypeEntry = {
  extensions?: string[];
  filenames?: string[];
};

function repoPath(...segments: string[]) {
  return path.resolve(process.cwd(), "..", ...segments);
}

export type ProductStats = {
  extensions: number;
  fileTypes: number;
  filenameMappings: number;
  grammars: number;
};

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
  const entries = safeReadJson(repoPath("dotViewer", "Shared", "DefaultFileTypes.json"));
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
    grammars: safeCountScmFiles(repoPath("dotViewer", "HighlightXPC", "TreeSitterQueries")),
  };
}
