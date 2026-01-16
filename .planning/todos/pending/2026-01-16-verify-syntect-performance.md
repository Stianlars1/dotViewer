---
created: 2026-01-16T12:00
title: Verify Syntect performance
area: performance
files:
  - QuickLookPreview/PreviewContentView.swift
  - Shared/SyntaxHighlighter.swift
---

## Problem

Phase 03-03 implemented Syntect-based syntax highlighting to replace the slow HighlightSwift (JavaScriptCore) library. The code is complete but awaiting human verification at a checkpoint.

Need to verify:
1. Highlighting speed: <100ms per file (ideally <50ms)
2. Rapid navigation: Smooth at 140 BPM (~430ms between files)
3. Visual quality: No regressions in highlighting appearance

## Solution

1. Build and run the app
2. Open Console.app, filter for "dotViewer"
3. Navigate to source files, press Space to preview
4. Watch timing logs in Console
5. Test rapid arrow-key navigation through 10+ files
6. Report results to resume checkpoint:
   - "approved" — Performance meets requirements
   - "too slow" — Need to investigate fallback (03-04)
