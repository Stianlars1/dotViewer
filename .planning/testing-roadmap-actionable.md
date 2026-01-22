# dotViewer Testing Roadmap - Actionable Plan
## From 0% to 85% Code Coverage in 8 Weeks

**Status:** CRITICAL - No automated tests exist
**Current Coverage:** 0% (manual E2E only)
**Target Coverage:** 85% (174 automated tests)
**Time Investment:** 185 hours (23 hours/week)

---

## Week-by-Week Execution Plan

### Week 1: Foundation Setup (23 hours)

**Goal:** Establish test infrastructure and safety net

#### Day 1-2: Project Setup (8 hours)
```bash
# 1. Add test targets to Xcode project
# File > New > Target > macOS Unit Testing Bundle
# - Target name: dotViewerTests
# - Add @testable import dotViewer

# 2. Create test directory structure
mkdir -p dotViewerTests/{Unit,Integration,Security,Performance,Fixtures}

# 3. Add first test file
touch dotViewerTests/Unit/HighlightCacheTests.swift

# 4. Configure test scheme
# Product > Scheme > Edit Scheme > Test > Add dotViewerTests

# 5. Run empty test suite to verify setup
xcodebuild test -scheme dotViewer -destination 'platform=macOS'
```

#### Day 3-5: Critical Path Tests (15 hours)

**HighlightCache Tests (10 tests, 8 hours):**
```swift
// dotViewerTests/Unit/HighlightCacheTests.swift
class HighlightCacheTests: XCTestCase {
    ✓ testMemoryCacheHit_ReturnsImmediately
    ✓ testDiskCacheHit_PromotesToMemory
    ✓ testCacheMiss_ReturnsNil
    ✓ testLRUEviction_RemovesOldestWhenFull
    ✓ testCacheKey_ChangesWhenPathChanges
    ✓ testCacheKey_ChangesWhenThemeChanges
    ✓ testCacheKey_IsDeterministic
    ✓ testConcurrentReads_ThreadSafe
    ✓ testConcurrentWrites_ThreadSafe
    ✓ testClearMemory_PreservesDisk
}
```

**DiskCache Validation Tests (5 tests, 4 hours):**
```swift
// dotViewerTests/Unit/DiskCacheValidationTests.swift
class DiskCacheValidationTests: XCTestCase {
    ✓ testIsValidCacheKey_64HexChars_Valid
    ✓ testIsValidCacheKey_PathTraversal_Invalid
    ✓ testIsValidCacheKey_NonHex_Invalid
    ✓ testIsValidCacheKey_WrongLength_Invalid
    ✓ testIsValidCacheKey_DoubleDot_Invalid
}
```

**Cache Integration Tests (3 tests, 3 hours):**
```swift
// dotViewerTests/Integration/CacheIntegrationTests.swift
class CacheIntegrationTests: XCTestCase {
    ✓ testCacheMiss_HighlightAndStore
    ✓ testDiskHit_PromotesToMemory
    ✓ testThemeChange_InvalidatesBothCaches
}
```

**Deliverable:** 18 tests, ~25% coverage, safety net established

---

### Week 2: Security & Validation (20 hours)

**Goal:** Automate all security finding validations

#### Day 1-2: Sensitive File Detection (8 hours)
```swift
// dotViewerTests/Security/SensitiveFileDetectionTests.swift (9 tests)
class SensitiveFileDetectionTests: XCTestCase {
    ✓ testIsEnvFile_DotEnv_ReturnsTrue
    ✓ testIsEnvFile_DotEnvLocal_ReturnsTrue
    ✓ testIsEnvFile_Credentials_ReturnsTrue
    ✓ testIsEnvFile_AWSCredentials_ReturnsTrue
    ✓ testIsEnvFile_SSHPrivateKey_ReturnsTrue
    ✓ testIsEnvFile_PEMFile_ReturnsTrue
    ✓ testIsEnvFile_RegularFile_ReturnsFalse
    ✓ testEnvFileBanner_DisplayedForSensitiveFiles
    ✓ testEnvFileBanner_NotDisplayedForRegularFiles
}
```

#### Day 3: Extension Validation (6 hours)
```swift
// dotViewerTests/Security/ExtensionValidationTests.swift (6 tests)
class CustomExtensionValidationTests: XCTestCase {
    ✓ testValidateExtension_PathTraversal_Rejected
    ✓ testValidateExtension_TooLong_Rejected
    ✓ testValidateExtension_InvalidChars_Rejected
    ✓ testValidateExtension_ReservedExtension_Rejected
    ✓ testValidateExtension_Valid_Accepted
    ✓ testValidateExtension_EmptyAfterCleaning_Rejected
}
```

#### Day 4: Cache & Log Security (6 hours)
```swift
// dotViewerTests/Security/CacheValidationTests.swift (6 tests)
// Already covered in Week 1

// dotViewerTests/Security/LogSanitizationTests.swift (3 tests)
class LogSanitizationTests: XCTestCase {
    ✓ testPerfLog_Production_DoesNotLogPaths
    ✓ testPerfLog_Debug_LogsPaths
    ✓ testNSLog_NeverLogsPaths
}
```

**Deliverable:** 18 additional tests, ~40% coverage, all security findings validated

---

### Week 3: Language Detection (25 hours)

**Goal:** Ensure correct highlighting for all file types

#### Day 1-2: Extension Mapping (8 hours)
```swift
// dotViewerTests/Unit/LanguageDetectorTests.swift
class LanguageDetectorExtensionTests: XCTestCase {
    ✓ testDetect_JavaScript_FromMultipleExtensions
    ✓ testDetect_TypeScript_FromMTS_CTS_TS
    ✓ testDetect_Swift_FromSwift
    ✓ testDetect_Go_FromGo
    ✓ testDetect_Rust_FromRs
    ✓ testDetect_Python_FromPy
    ✓ testDetect_Ruby_FromRb
    ✓ testDetect_Shell_FromSh_Bash_Zsh
    ✓ testDetect_CaseInsensitive
    ✓ testDetect_UnknownExtension_ReturnsNil
}
```

#### Day 3: Dotfile Detection (7 hours)
```swift
class LanguageDetectorDotfileTests: XCTestCase {
    ✓ testDetect_GitConfig_ReturnsINI
    ✓ testDetect_Bashrc_ReturnsBash
    ✓ testDetect_EnvFile_ReturnsProperties
    ✓ testDetect_DockerIgnore_ReturnsBash
    ✓ testDetect_Npmrc_ReturnsINI
    ✓ testDetect_Dockerfile_ReturnsDockerfile
    ✓ testDetect_Makefile_ReturnsMakefile
    ✓ testDetect_Gemfile_ReturnsRuby
}
```

#### Day 4-5: Content-Based Detection (10 hours)
```swift
class LanguageDetectorContentTests: XCTestCase {
    ✓ testDetectFromContent_JSON_ObjectPattern
    ✓ testDetectFromContent_JSON_ArrayPattern
    ✓ testDetectFromContent_XML_DocTypePattern
    ✓ testDetectFromContent_XML_TagPattern
    ✓ testDetectFromContent_YAML_KeyColonPattern
    ✓ testDetectFromContent_INI_SectionPattern
    ✓ testDetectFromContent_Shell_ExportPattern
    ✓ testDetectFromContent_Properties_KeyValuePattern
    ✓ testDetectFromShebang_Python
    ✓ testDetectFromShebang_Node
    ✓ testDetectFromShebang_Bash
}
```

**Deliverable:** 29 additional tests, ~55% coverage, language detection verified

---

### Week 4: Performance Testing (20 hours)

**Goal:** Validate cache performance and cleanup

#### Day 1-2: Cache Performance (8 hours)
```swift
// dotViewerTests/Performance/CachePerformanceTests.swift
class CachePerformanceTests: XCTestCase {
    ✓ testMemoryCache_Get_CompletesUnder1ms
    ✓ testDiskCache_Get_CompletesUnder50ms
    ✓ testDiskCache_Cleanup_EnforcesMaxSize100MB
    ✓ testDiskCache_Cleanup_EnforcesMaxEntries500
    ✓ testDiskCache_Cleanup_RemovesOldestFirst
    ✓ testDiskCache_Cleanup_RateLimited30Seconds
}
```

#### Day 3: Highlighting Performance (6 hours)
```swift
class HighlightingPerformanceTests: XCTestCase {
    ✓ testHighlight_80KBFile_CompletesUnder2Seconds
    ✓ testHighlight_2000LineFile_Skipped
    ✓ testHighlight_Timeout_ReturnsPlainText
}
```

#### Day 4: Stress Tests (6 hours)
```swift
class RapidNavigationStressTests: XCTestCase {
    ✓ testRapidNavigation_140BPM_NoCrashes
    ✓ testRapidNavigation_CacheHitRate_Above80Percent
    ✓ testRapidNavigation_MemoryStable
}
```

**Deliverable:** 12 additional tests, ~65% coverage, performance validated

---

### Week 5: Additional Unit Tests (23 hours)

**Goal:** Complete unit test coverage for remaining components

#### Day 1-2: SyntaxHighlighter Tests (10 hours)
```swift
// dotViewerTests/Unit/SyntaxHighlighterTests.swift (12 tests)
class SyntaxHighlighterTests: XCTestCase {
    ✓ testHighlight_UsesFast_WhenSupported
    ✓ testHighlight_UsesFallback_WhenUnsupported
    ✓ testColorCache_HitOnSameTheme
    ✓ testColorCache_InvalidatesOnThemeChange
    ✓ testColorCache_InvalidatesOnAppearanceChange
    ✓ testColorCache_ThreadSafe
    ✓ testResolveColors_AutoMode_Light
    ✓ testResolveColors_AutoMode_Dark
    ✓ testResolveColors_NamedTheme
    ✓ testResolveColors_BlackoutMode
    ✓ testHighlight_FallsBackToPlainText_OnError
    ✓ testHighlight_HandlesEmptyCode
}
```

#### Day 3-4: FastSyntaxHighlighter Tests (10 hours)
```swift
// dotViewerTests/Unit/FastSyntaxHighlighterTests.swift (10 tests)
class FastSyntaxHighlighterTests: XCTestCase {
    ✓ testIsSupported_Swift_ReturnsTrue
    ✓ testIsSupported_Go_ReturnsTrue
    ✓ testIsSupported_PHP_ReturnsFalse
    ✓ testHighlight_Swift_Keywords
    ✓ testHighlight_Swift_Strings
    ✓ testHighlight_Swift_Comments
    ✓ testHighlight_JSON_Syntax
    ✓ testHighlight_Bash_Variables
    ✓ testHighlight_LargeFile_CompletesUnder2Seconds
    ✓ testHighlight_EmptyCode_ReturnsEmpty
}
```

#### Day 5: DiskCache Remaining Tests (3 hours)
```swift
// dotViewerTests/Unit/DiskCacheTests.swift (remaining tests)
class DiskCacheSerializationTests: XCTestCase {
    ✓ testRTFSerialization_PreservesAttributes
    ✓ testRTFDeserialization_HandlesCorruption
    ✓ testRTFRoundTrip_IsLossless
    ✓ testGet_RemovesCorruptedFile
    ✓ testSet_CreatesDirectoryIfMissing
}
```

**Deliverable:** 27 additional tests, ~75% coverage

---

### Week 6: E2E Test Framework (23 hours)

**Goal:** Set up automated E2E testing infrastructure

#### Day 1-2: E2E Framework Setup (10 hours)
```bash
# 1. Add E2E test target
# File > New > Target > macOS UI Testing Bundle
# - Target name: dotViewerE2ETests

# 2. Create helper scripts
cat > dotViewerE2ETests/setup_test_env.sh << 'EOF'
#!/bin/bash
# Build and install app
xcodebuild build -scheme dotViewer -configuration Debug
rm -rf /Applications/dotViewer.app
cp -R build/Debug/dotViewer.app /Applications/
qlmanage -r
sleep 2
EOF

# 3. Create E2E test base class
touch dotViewerE2ETests/QuickLookE2ETestCase.swift
```

#### Day 3-5: Extension Lifecycle & Rendering Tests (13 hours)
```swift
// dotViewerE2ETests/QuickLookExtensionE2ETests.swift
class QuickLookExtensionE2ETests: QuickLookE2ETestCase {
    // Extension Lifecycle (3 tests, 5 hours)
    ✓ testExtension_LoadsAfterInstallation
    ✓ testExtension_RegistersWithPluginKit
    ✓ testExtension_SurvivesXPCRestart

    // Preview Rendering (5 tests, 8 hours)
    ✓ testQuickLook_RendersSwiftFile
    ✓ testQuickLook_RendersMarkdownFile
    ✓ testQuickLook_RendersSensitiveFile_ShowsBanner
    ✓ testQuickLook_RendersTruncatedFile_ShowsWarning
    ✓ testQuickLook_RendersLargeFile
}
```

**Deliverable:** 8 E2E tests, infrastructure for automated Quick Look testing

---

### Week 7: E2E Performance & Error Handling (20 hours)

**Goal:** Complete E2E test suite

#### Day 1-2: Performance E2E (10 hours)
```swift
// dotViewerE2ETests/PerformanceE2ETests.swift
class PerformanceE2ETests: QuickLookE2ETestCase {
    ✓ testQuickLook_80KBFile_LoadsUnder3Seconds
    ✓ testQuickLook_CachedFile_LoadsUnder500ms
    ✓ testQuickLook_RapidNavigation_NoCrashes
}
```

#### Day 3: Theme Switching E2E (5 hours)
```swift
class ThemeSwitchingE2ETests: QuickLookE2ETestCase {
    ✓ testQuickLook_ThemeSwitch_UpdatesLivePreview
    ✓ testQuickLook_AutoTheme_FollowsSystemAppearance
}
```

#### Day 4: Error Handling E2E (5 hours)
```swift
class ErrorHandlingE2ETests: QuickLookE2ETestCase {
    ✓ testQuickLook_CorruptedFile_ShowsError
    ✓ testQuickLook_PermissionDenied_ShowsError
    ✓ testQuickLook_BinaryFile_HandlesGracefully
}
```

**Deliverable:** 8 additional E2E tests, ~80% coverage

---

### Week 8: Integration Tests & CI/CD (23 hours)

**Goal:** Complete integration tests and automate CI/CD

#### Day 1-2: Integration Tests (12 hours)
```swift
// dotViewerTests/Integration/FileLoadingIntegrationTests.swift (5 tests)
class FileLoadingIntegrationTests: XCTestCase {
    ✓ testPipeline_NewFile_ColdCache
    ✓ testPipeline_ExistingFile_WarmCache
    ✓ testPipeline_LargeFile_SkipsHighlighting
    ✓ testPipeline_BinaryFile_HandlesGracefully
    ✓ testPipeline_TruncatedFile_ShowsWarning
}

// dotViewerTests/Integration/ThemeIntegrationTests.swift (4 tests)
class ThemeIntegrationTests: XCTestCase {
    ✓ testThemeSwitch_InvalidatesCache
    ✓ testThemeSwitch_ReHighlightsContent
    ✓ testAutoTheme_SwitchesWithAppearance
    ✓ testThemeSwitch_UpdatesBackgroundColor
}

// dotViewerTests/Integration/LanguageHighlightingIntegrationTests.swift (7 tests)
class LanguageHighlightingIntegrationTests: XCTestCase {
    ✓ testDetectAndHighlight_JavaScript
    ✓ testDetectAndHighlight_TypeScript
    ✓ testDetectAndHighlight_Swift
    ✓ testDetectAndHighlight_Dotfile_Bashrc
    ✓ testDetectAndHighlight_Shebang_Python
    ✓ testDetectAndHighlight_ContentBased_JSON
    ✓ testDetectAndHighlight_Unknown_PlainText
}
```

#### Day 3-5: CI/CD Setup (11 hours)

**GitHub Actions Workflow:**
```yaml
# .github/workflows/tests.yml
name: Tests
on: [push, pull_request]
jobs:
  unit-tests:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: xcodebuild test -scheme dotViewer -testPlan UnitTests
      - run: xcrun llvm-cov report > coverage.txt
      - run: |
          COVERAGE=$(grep "TOTAL" coverage.txt | awk '{print $NF}' | sed 's/%//')
          if (( $(echo "$COVERAGE < 85.0" | bc -l) )); then exit 1; fi

  integration-tests:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: xcodebuild test -scheme dotViewer -testPlan IntegrationTests

  e2e-tests:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: ./dotViewerE2ETests/setup_test_env.sh
      - run: xcodebuild test -scheme dotViewer -testPlan E2ETests
```

**Pre-commit Hook:**
```bash
#!/bin/bash
# .git/hooks/pre-commit
xcodebuild test -scheme dotViewer -testPlan UnitTests || exit 1

COVERAGE=$(xcrun llvm-cov report | grep "TOTAL" | awk '{print $NF}' | sed 's/%//')
if (( $(echo "$COVERAGE < 85.0" | bc -l) )); then
    echo "Error: Coverage $COVERAGE% is below threshold 85%"
    exit 1
fi
```

**Deliverable:** 16 integration tests, CI/CD pipeline, 85% coverage achieved

---

## Success Metrics Dashboard

### Coverage Progress

| Week | Tests Added | Total Tests | Coverage | Status |
|------|------------|-------------|----------|--------|
| 1 | 18 | 18 | 25% | Safety net established |
| 2 | 18 | 36 | 40% | Security validated |
| 3 | 29 | 65 | 55% | Language detection verified |
| 4 | 12 | 77 | 65% | Performance tested |
| 5 | 27 | 104 | 75% | Core components complete |
| 6 | 8 | 112 | 78% | E2E infrastructure ready |
| 7 | 8 | 120 | 80% | E2E suite complete |
| 8 | 16 | 136 | 85% | **TARGET ACHIEVED** |

### Test Pyramid Health

```
Week 1:  Inverted (0% unit, 0% integration, 100% manual E2E)
Week 8:  Healthy  (69% unit, 16% integration, 15% automated E2E)
```

**Pyramid Health Score:** 0/10 → 9/10

---

## Daily Standup Template

```markdown
### Testing Progress - Day X of Week Y

**Yesterday:**
- [ ] Tests implemented: X
- [ ] Coverage gained: X%
- [ ] Blockers: None/[describe]

**Today:**
- [ ] Tests to implement: [list]
- [ ] Target coverage: X%
- [ ] Estimated hours: X

**Blockers:**
- [ ] None / [describe]
```

---

## Quick Start Commands

### Run All Tests
```bash
xcodebuild test -scheme dotViewer -destination 'platform=macOS'
```

### Run Specific Test Plan
```bash
xcodebuild test -scheme dotViewer -testPlan UnitTests
xcodebuild test -scheme dotViewer -testPlan IntegrationTests
xcodebuild test -scheme dotViewer -testPlan E2ETests
```

### Check Coverage
```bash
xcodebuild test -scheme dotViewer -enableCodeCoverage YES
xcrun llvm-cov report -instr-profile=$(find . -name '*.profdata') \
  $(find . -name 'dotViewer')
```

### Run Single Test Class
```bash
xcodebuild test -scheme dotViewer \
  -only-testing:dotViewerTests/HighlightCacheTests
```

### Generate Coverage HTML Report
```bash
xcrun llvm-cov show -instr-profile=$(find . -name '*.profdata') \
  $(find . -name 'dotViewer') -format=html > coverage.html
open coverage.html
```

---

## Emergency Test Fixes

### Test Failing? Debug Checklist

1. **Isolate the failure:**
   ```bash
   xcodebuild test -only-testing:dotViewerTests/FailingTestClass/testMethodName
   ```

2. **Check test isolation:**
   - Clear cache before each test: `cache.clearAll()`
   - Reset singletons: `SharedSettings.shared.reset()`
   - Clean up file system state

3. **Add debug logging:**
   ```swift
   print("DEBUG: cache key = \(cacheKey)")
   print("DEBUG: result = \(result)")
   ```

4. **Run in Xcode debugger:**
   - Set breakpoint in test
   - Inspect variable state
   - Step through execution

---

## Resources

**Test Documentation:**
- [XCTest Framework Reference](https://developer.apple.com/documentation/xctest)
- [Testing Swift Code](https://developer.apple.com/videos/play/wwdc2023/10175/)
- [ViewInspector for SwiftUI](https://github.com/nalexn/ViewInspector)

**Code Coverage:**
- [Xcode Code Coverage](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/chapters/07-code_coverage.html)
- [llvm-cov Documentation](https://llvm.org/docs/CommandGuide/llvm-cov.html)

**CI/CD:**
- [GitHub Actions for Xcode](https://github.com/actions/runner-images/blob/main/images/macos/macos-14-Readme.md)
- [Fastlane Testing](https://docs.fastlane.tools/actions/scan/)

---

## Completion Checklist

### Week 1
- [ ] Test targets added to Xcode project
- [ ] 18 tests implemented (cache, validation, integration)
- [ ] 25% coverage achieved
- [ ] All tests passing in CI/CD

### Week 2
- [ ] Security tests implemented (sensitive files, validation)
- [ ] 18 additional tests passing
- [ ] 40% coverage achieved
- [ ] Security findings automated

### Week 3
- [ ] Language detection tests complete
- [ ] 29 additional tests passing
- [ ] 55% coverage achieved
- [ ] All file types tested

### Week 4
- [ ] Performance tests implemented
- [ ] 12 additional tests passing
- [ ] 65% coverage achieved
- [ ] Benchmarks established

### Week 5
- [ ] SyntaxHighlighter & FastSyntaxHighlighter tests complete
- [ ] 27 additional tests passing
- [ ] 75% coverage achieved
- [ ] Core components fully tested

### Week 6
- [ ] E2E framework established
- [ ] 8 E2E tests passing
- [ ] 78% coverage achieved
- [ ] Quick Look automation working

### Week 7
- [ ] E2E performance & error tests complete
- [ ] 8 additional E2E tests passing
- [ ] 80% coverage achieved
- [ ] E2E suite comprehensive

### Week 8
- [ ] Integration tests complete
- [ ] 16 additional tests passing
- [ ] 85% coverage achieved ✓
- [ ] CI/CD pipeline active
- [ ] Pre-commit hooks enforcing coverage
- [ ] **TESTING ROADMAP COMPLETE**

---

**Next Phase:** Refactor God Class (PreviewContentView: 1471 lines) with test coverage safety net in place.
