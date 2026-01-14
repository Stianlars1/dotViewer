# dotViewer v1.0 QA Findings

## Bugs (Must Fix)

### BUG-000: CRITICAL - Large files take 1+ minute to open
- **Severity**: CRITICAL - BLOCKER FOR RELEASE
- **Status**: ✅ **FIXED**
- **File**: `QuickLookPreview/PreviewViewController.swift:78-86`
- **Description**: Opening `package-lock.json` (11,000+ lines) takes 1-1.5 minutes
- **Root Cause**: Line 79 called `content.components(separatedBy: .newlines)` which creates an array of ALL lines BEFORE any optimization checks. This is O(n) on the entire file content.
- **Fix Applied**: Lines 78-86 now use efficient UTF-8 byte scanning to count newlines without memory allocation:
  ```swift
  let newlineByte = UInt8(ascii: "\n")
  var totalLineCount = 1
  for byte in content.utf8 {
      if byte == newlineByte { totalLineCount += 1 }
  }
  ```
- **Verified**: Large files (75,000+ lines) now load in < 2 seconds

### BUG-001: .env security warning banner not showing
- **Severity**: High
- **Status**: ✅ **WORKS** (test methodology issue)
- **File**: `QuickLookPreview/PreviewContentView.swift:71`
- **Description**: The security warning banner does not appear for `.env` files containing sensitive data (API keys, private keys, tokens)
- **Expected**: Orange banner saying "This file may contain sensitive data (API keys, passwords)"
- **Resolution**: Banner DOES show in full Quick Look preview (Spacebar). It is intentionally hidden in Finder's compact preview pane (`!isCompactMode` check at line 71) to save space.
- **Note**: This is correct behavior - compact mode hides non-essential UI elements

### BUG-002: .vimrc has no syntax highlighting colors
- **Severity**: Low
- **Status**: ⏸️ **DEFERRED** (library limitation)
- **File**: `Shared/LanguageDetector.swift`
- **Description**: `.vimrc` is correctly detected as "Vim Script" but content shows no color differentiation
- **Expected**: Keywords (`set`, `syntax`), values, and comments in different colors
- **Actual**: All text is white/gray monochrome
- **Root Cause**: HighlightSwift/highlight.js has limited Vim script support
- **Decision**: Defer to future release - not blocking for v1.0

---

## Enhancements (Nice to Have)

### ENH-001: Add syntax highlighting for .gitignore comments
- **Priority**: Low
- **Description**: `.gitignore` files show as plain text. GitHub highlights comments (`#`) differently.
- **Suggestion**: Map `.gitignore` to a language that highlights `#` comments, or create custom gitignore highlighting

### ENH-002: Add .npmrc to security warning files
- **Priority**: Medium
- **Description**: `.npmrc` often contains auth tokens but doesn't show security warning
- **File**: `QuickLookPreview/PreviewContentView.swift`
- **Suggestion**: Add `.npmrc` to `isEnvFile` check or create separate `isSensitiveFile` check

---

## Test Results Summary

### Batch 1: Home Directory Dotfiles
| Test | File | Result |
|------|------|--------|
| 1.1 | `.zshrc` | PASS |
| 1.2 | `.gitconfig` | PASS |
| 1.3 | `.vimrc` | PARTIAL (BUG-002) |
| 1.4 | `.npmrc` | PASS |

### Batch 2: History Files (Skip Highlighting)
| Test | File | Result |
|------|------|--------|
| 2.1 | `.zsh_history` | PASS |
| 2.2 | `.viminfo` | PASS |

### Batch 3: Project Files
| Test | File | Result |
|------|------|--------|
| 3.1 | `.env` | PASS (banner shows in Spacebar preview) |
| 3.2 | `.gitignore` | PASS |
| 3.3 | `package.json` | PASS |

---

## Testing Progress
- [x] Batch 1: Home directory dotfiles
- [x] Batch 2: History files
- [x] Batch 3: Project files
- [ ] Batch 4: Markdown rendering
- [ ] Batch 5: Edge cases
- [ ] Batch 6: Theme cycling
- [ ] Batch 7: Settings persistence
- [ ] Batch 8: Performance
