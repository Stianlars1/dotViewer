# dotViewer Code Review Implementation Plan

**Date:** 2025-01-22
**Source:** CODE_REVIEW_2025-01-22.md

---

## Implementation Phases

### Phase 1: Ship-Blocking Fixes (Priority 1)

#### 1.1 Document @unchecked Sendable Justifications
**Files to modify:**
- `Shared/DiskCache.swift`
- `Shared/SharedSettings.swift`
- `Shared/HighlightCache.swift`
- `Shared/FileTypeRegistry.swift`

**Changes:** Add documentation comments above each `@unchecked Sendable` conformance explaining the thread-safety mechanism used (NSLock, serial queue, etc.).

#### 1.2 Add Error Logging to Cache Operations
**File:** `Shared/DiskCache.swift`

**Changes:**
- Replace `try?` with `do-catch` blocks that log errors
- Add error logging for cleanup failures
- Log orphaned file detection

#### 1.3 Fix ThemeManager Main Thread Access
**File:** `QuickLookPreview/PreviewContentView.swift`

**Changes:** Capture theme value on main thread before entering async context:
```swift
let theme = await MainActor.run { ThemeManager.shared.selectedTheme }
```

---

### Phase 2: Quality Improvements (Priority 2)

#### 2.1 Add Input Validation to Custom Extensions
**File:** `dotViewer/AddCustomExtensionSheet.swift`

**Validations to add:**
- Reject path traversal attempts (`..`, `/`)
- Reject reserved extensions (`.app`, `.framework`, etc.)
- Enforce length limits (1-20 characters)
- Reject empty strings after cleaning
- Reject extensions with spaces or special characters

#### 2.2 Create Constants File
**New file:** `Shared/Constants.swift`

**Contents:**
```swift
enum CacheConstants {
    static let maxSizeBytes: Int = 100 * 1024 * 1024  // 100MB
    static let maxEntries: Int = 500
    static let cleanupInterval: Int = 10
}

enum PreviewConstants {
    static let maxLines: Int = 5000
    static let defaultMaxFileSize: Int = 500 * 1024  // 500KB
}

enum LanguageDetectionConstants {
    static let contentSampleSize: Int = 500
}
```

#### 2.3 Expand Environment File Detection
**File:** `QuickLookPreview/PreviewContentView.swift`

**Additional patterns:**
- `.env.example`, `.env.template`, `.env.sample`
- `.aws/credentials`, `.aws/config`
- `id_rsa`, `id_ed25519`, `id_dsa`
- `*.pem`, `*.key`, `*.p12`, `*.pfx`
- `credentials.json`, `secrets.yaml`

#### 2.4 Move Cleanup to Async Operation
**File:** `Shared/DiskCache.swift`

**Changes:**
- Remove inline cleanup from write lock
- Spawn cleanup asynchronously on writeQueue
- Add minimum time between cleanups (throttling)

---

### Phase 3: Technical Debt (Priority 3)

#### 3.1 Add XCTest Unit Tests
**New files:**
- `dotViewerTests/DiskCacheTests.swift`
- `dotViewerTests/LanguageDetectorTests.swift`
- `dotViewerTests/CustomExtensionValidationTests.swift`
- `dotViewerTests/HighlightCacheTests.swift`

#### 3.2 Standardize Error Handling
**Guideline document:** Add `CONTRIBUTING.md` with error handling patterns

**Rules:**
- Use `do-catch` when error recovery is possible
- Use `try?` only when failure is acceptable AND logged
- Use `guard` for preconditions
- Never use `try!` except for compile-time constants with documentation

#### 3.3 Add Path Sanitization
**Files:**
- `Shared/DiskCache.swift`
- `QuickLookPreview/PreviewViewController.swift`

**Changes:**
- Validate paths don't contain `..` components
- Ensure paths are within expected directories
- Log suspicious path attempts

---

## Verification Steps

After each phase:

1. **Build verification:**
   ```bash
   xcodebuild -scheme dotViewer -configuration Debug build
   ```

2. **Quick Look test:**
   - Preview files in `TestFiles/` directory
   - Verify syntax highlighting works
   - Test theme switching

3. **Cache behavior:**
   - Monitor disk usage during rapid previewing
   - Verify no UI stuttering during cleanup

4. **Extension validation:**
   - Try adding invalid extensions (should be rejected)
   - Try adding valid extensions (should work)

---

## Risk Assessment

| Change | Risk | Mitigation |
|--------|------|------------|
| Cache error logging | Low | Log-only, no behavior change |
| ThemeManager thread fix | Medium | Test thoroughly in async contexts |
| Extension validation | Low | Only affects new extensions |
| Constants consolidation | Low | Refactor only, same values |
| Async cleanup | Medium | Test under load |

---

## Rollback Plan

Each phase can be reverted independently via git:
```bash
git revert <commit-hash>
```

Feature branches recommended:
- `fix/sendable-documentation`
- `fix/cache-error-logging`
- `fix/theme-thread-safety`
- `feat/extension-validation`
- `refactor/constants`
- `fix/async-cleanup`

---

## Success Criteria

- [ ] All Priority 1 issues addressed
- [ ] Build succeeds with no new warnings
- [ ] Existing functionality unchanged
- [ ] Performance not degraded
- [ ] Code review checklist items marked complete
