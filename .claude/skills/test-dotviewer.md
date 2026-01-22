---
name: test-dotviewer
description: Performance test the dotViewer Quick Look extension
---

# dotViewer Performance Testing Skill

## What This Skill Does
Runs comprehensive performance tests on the dotViewer Quick Look extension and generates a report.

## Test Protocol

### 1. Environment Cleanup

```bash
# Kill Quick Look processes
pkill -9 qlmanage 2>/dev/null
pkill -9 QuickLookUIService 2>/dev/null

# Clear highlight cache for cold start test
rm -rf ~/Library/Containers/com.stianlars1.dotViewer.QuickLookPreview/Data/Library/Application\ Support/HighlightCache/*

# Reset Quick Look daemon
qlmanage -r
qlmanage -r cache
```

### 2. Test Files

Located in `TestFiles/perf-test/`:
| File | Size | Type |
|------|------|------|
| large-zsh-history.zsh | 80KB | Shell |
| large-cli.zsh | 27KB | Shell |
| large-claude.json | 26KB | JSON |
| large-readme.md | 21KB | Markdown |
| large-changelog.sh | 17KB | Shell |

### 3. Test Scenarios

#### Cold Cache Test
1. Clear cache completely (step 1)
2. Run: `qlmanage -p [file]`
3. Monitor Console.app with filter: `[dotViewer`
4. Record: Time from PREVIEW START to visible

#### Warm Cache Test
1. Run same file again immediately
2. Verify instant load (cache hit)
3. Check for "Disk HIT" in Debug builds

#### Finder Column -> Quick Look Sync Test
1. Select file in Finder column view
2. Wait for preview to render
3. Press spacebar for Quick Look
4. Verify Quick Look is instant (shared cache)

### 4. Log Analysis

Filter Console.app for:
- `[dotViewer E2E]` - Extension invocation (Release + Debug)
- `[dotViewer PERF]` - Detailed timing (Debug only)
- `[dotViewer Cache]` - Cache hits/misses (Release: Init logs only, Debug: all)

Using macOS log command:
```bash
# Show all dotViewer logs from last 2 minutes
/usr/bin/log show --predicate 'eventMessage CONTAINS "dotViewer"' --last 2m

# Show only QuickLookPreview process logs
/usr/bin/log show --predicate 'process == "QuickLookPreview"' --last 2m | grep -E '(dotViewer|E2E|Cache|PERF)'
```

### 5. Report Format

| File | Size | Cold Time | Cached Time | Highlighter | Status |
|------|------|-----------|-------------|-------------|--------|
| large-zsh-history.zsh | 80KB | Xs | Xs | Fast | Pass/Fail |
| large-cli.zsh | 27KB | Xs | Xs | Fast | Pass/Fail |
| large-claude.json | 26KB | Xs | Xs | Fast | Pass/Fail |

### 6. Success Criteria

| Metric | Target |
|--------|--------|
| 80KB file cold | <3s |
| 80KB file cached | <0.5s |
| 27KB file cold | <1.5s |
| 27KB file cached | <0.3s |
| All files | Syntax highlighting visible |
| Finder -> Quick Look | Cache shared (instant) |

### 7. Verification Checklist

- [ ] App installed at `/Applications/dotViewer.app` (NOT nested)
- [ ] Extension registered: `pluginkit -m -p com.apple.quicklook.preview | grep dotviewer`
- [ ] Console.app shows `[dotViewer E2E]` logs
- [ ] Test files render with syntax highlighting
- [ ] Cache file created: `ls ~/Library/Containers/com.stianlars1.dotViewer.QuickLookPreview/Data/Library/Application\ Support/HighlightCache/`
- [ ] Second view is faster than first (cache hit)

### 8. Common Issues

**Extension not loading:**
- Launch main app first to register extension
- Run `qlmanage -r` to reset daemon

**Cache not working:**
- Check cache directory exists
- Verify theme setting is consistent
- Cache key includes: path, modDate, theme, language

**Slow performance:**
- Check if FastSyntaxHighlighter is being used (Debug logs)
- Very large files (>2000 lines) skip highlighting
- Unknown languages fall back to slower HighlightSwift

### 9. Build Options

```bash
# Release build (for production testing)
./scripts/release.sh 1.0.0 --skip-notarize --skip-dmg

# Debug build (for detailed logging)
xcodebuild -project dotViewer.xcodeproj -scheme "dotViewer (macOS)" -configuration Debug

# Install from build
rm -rf /Applications/dotViewer.app
cp -R build/export/dotViewer.app /Applications/
qlmanage -r
```
