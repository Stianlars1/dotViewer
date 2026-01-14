# Testing Patterns

**Analysis Date:** 2026-01-14

## Test Framework

**Runner:**
- No automated test framework configured
- No XCTest targets in project

**Assertion Library:**
- Not applicable (no automated tests)

**Run Commands:**
```bash
# No automated test commands available
# Manual QA process documented in QA_FINDINGS.md
```

## Test File Organization

**Location:**
- No test files found
- No `Tests/` or `*Tests.swift` files

**Naming:**
- Not applicable

**Structure:**
- Manual QA documented in `QA_FINDINGS.md`
- Production readiness audit in `PRODUCTION_READY.md`

## Test Structure

**Current Approach:**
- Manual testing via Quick Look preview
- QA findings tracked in markdown documentation
- No automated test suites

**Manual QA Pattern:**
```markdown
### BUG-XXX: Issue description
- **Severity**: Critical/High/Medium/Low
- **Status**: ✅ FIXED / ⏸️ DEFERRED / 🔴 OPEN
- **File**: `path/to/file.swift`
- **Description**: What happens
- **Root Cause**: Why it happens
- **Fix Applied**: How it was fixed
- **Verified**: How fix was confirmed
```

## Mocking

**Framework:**
- Not applicable (no automated tests)

**Patterns:**
- Not applicable

**What Would Need Mocking:**
- File system operations
- UserDefaults/App Groups
- HighlightSwift library
- Quick Look framework callbacks

## Fixtures and Factories

**Test Data:**
- Not applicable (no automated tests)

**Sample Files for Manual Testing:**
- Various file types in user's file system
- Large files for performance testing (75,000+ lines)
- `.env` files for security banner testing

## Coverage

**Requirements:**
- No coverage requirements
- No coverage tooling configured

**Configuration:**
- Not applicable

**View Coverage:**
- Not applicable

## Test Types

**Unit Tests:**
- Not implemented
- Candidates: `FileTypeRegistry`, `LanguageDetector`, `SharedSettings`

**Integration Tests:**
- Not implemented
- Candidates: Settings sync, theme switching

**E2E Tests:**
- Manual Quick Look preview testing
- Documented in `QA_FINDINGS.md`

## Quality Assurance Process

**Manual Testing Workflow:**
1. Build and run app in Xcode
2. Test Quick Look preview on various file types
3. Verify settings sync between app and extension
4. Check performance on large files
5. Document findings in `QA_FINDINGS.md`

**Critical Test Cases (Manual):**
- Large file handling (>1000 lines, >75000 lines)
- Binary file detection
- Encoding detection (UTF-8, UTF-16, Latin-1)
- Security banner for `.env` files
- Theme switching (auto/light/dark)
- Extension status detection

## Common Patterns

**Type Safety Instead of Tests:**
- Heavy use of Swift's type system for correctness
- Enums for state machines: `FileTypeCategory`, `NavigationItem`
- Codable conformance for serialization safety

**Thread Safety Mechanisms:**
- `NSLock` for SharedSettings access
- `LockedValue<T>` wrapper for continuation safety
- `@unchecked Sendable` with explicit synchronization

**Example from `ExtensionStatusChecker.swift`:**
```swift
// Thread-safe flag to ensure continuation resumes only once
let didResume = LockedValue(false)

let resumeOnce: (Bool) -> Void = { enabled in
    let alreadyResumed = didResume.withLock { value in
        if value { return true }
        value = true
        return false
    }
    guard !alreadyResumed else { return }
    continuation.resume(returning: enabled)
}
```

**Input Validation:**
- `SharedSettings` clamps values: `max(8, min(72, newValue))`
- File size limits enforced before processing
- Extension name validation on add

## Recommendations for Future Testing

**High Priority:**
1. Unit tests for `SharedSettings` thread safety
2. Unit tests for `FileTypeRegistry` O(1) lookup guarantees
3. Unit tests for `LanguageDetector` detection logic

**Medium Priority:**
4. Integration tests for settings sync
5. Integration tests for theme switching
6. Snapshot tests for preview rendering

**Test Infrastructure Needed:**
- XCTest target configuration
- Mock framework (or manual mocks)
- Test fixtures for various file types

---

*Testing analysis: 2026-01-14*
*Update when test patterns change*
