#!/usr/bin/env python3
"""Sample Python file for testing RTF preview (Experiment 1).

Preview this file in Finder to test whether Quick Look renders RTF
with a native NSTextView that supports Cmd+C.
"""

import os
import sys
from pathlib import Path


class FileProcessor:
    """Processes files with various transformations."""

    def __init__(self, root_dir: str):
        self.root = Path(root_dir)
        self.processed = 0
        self.errors = []

    def process_all(self) -> dict:
        """Walk the directory tree and process each file."""
        results = {"total": 0, "success": 0, "failed": 0}

        for path in self.root.rglob("*"):
            if path.is_file():
                results["total"] += 1
                try:
                    self._process_single(path)
                    results["success"] += 1
                except Exception as e:
                    results["failed"] += 1
                    self.errors.append((str(path), str(e)))

        return results

    def _process_single(self, path: Path) -> None:
        """Process a single file."""
        size = path.stat().st_size
        if size > 10_000_000:
            raise ValueError(f"File too large: {size} bytes")

        content = path.read_text(encoding="utf-8")
        lines = content.splitlines()
        self.processed += 1
        print(f"Processed {path.name}: {len(lines)} lines, {size} bytes")


def main():
    if len(sys.argv) < 2:
        print("Usage: python sample.py <directory>")
        sys.exit(1)

    processor = FileProcessor(sys.argv[1])
    results = processor.process_all()

    print(f"\nResults: {results}")
    if processor.errors:
        print(f"Errors ({len(processor.errors)}):")
        for path, error in processor.errors:
            print(f"  {path}: {error}")


if __name__ == "__main__":
    main()
