# Phase 3: Testing Strategy & Implementation Evaluation
## dotViewer macOS Quick Look Extension

**Date:** 2026-01-22
**Evaluator:** Test Automation Engineering Expert
**Codebase:** 7,082 lines across 23 Swift files
**Scope:** Unit, Integration, E2E, Security, Performance Testing

---

## Executive Summary

### Current State: CRITICAL TESTING GAPS IDENTIFIED

**Test Coverage:** 0% automated test coverage (no XCTest suite exists)
**Testing Strategy:** Manual E2E testing only via shell scripts
**TDD Compliance:** 0% (no test-first development evidence)
**Test Pyramid Balance:** Inverted (100% manual E2E, 0% unit/integration)

### Risk Assessment

| Risk Category | Severity | Impact |
|--------------|----------|---------|
| **Regression Risk** | CRITICAL | No automated safety net for refactoring |
| **Security Test Gap** | HIGH | No automated validation of 11 security findings |
| **Performance Test Gap** | HIGH | Manual-only validation of cache/highlighting |
| **Integration Blind Spots** | HIGH | Cache coordination, theme switching untested |
| **Architectural Risk** | MEDIUM | God Class (1471 lines) has zero test coverage |

---

## 1. Unit Test Coverage Analysis

### Critical Untested Components

#### 1.1 HighlightCache.swift (177 lines) - ZERO COVERAGE
**Risk Level:** CRITICAL
**Test Gap Impact:** Core caching logic unverified

**Untested Critical Paths:**
- ✗ Two-tier cache coordination (memory → disk promotion)
- ✗ LRU eviction algorithm (accessOrder array synchronization)
- ✗ Thread safety of `lock.withLock` blocks
- ✗ Cache key generation (SHA256 + theme + language)
- ✗ Cache invalidation on file modification
- ✗ Memory limit enforcement (20 entries max)

**Required Unit Tests:**
```swift
// HighlightCacheTests.swift (MISSING)
class HighlightCacheTests: XCTestCase {
    // Cache Hit Path
    func testMemoryCacheHit_ReturnsImmediately()
    func testDiskCacheHit_PromotesToMemory()
    func testCacheMiss_ReturnsNil()

    // LRU Eviction
    func testLRUEviction_RemovesOldestWhenFull()
    func testLRUEviction_UpdatesAccessOrder()
    func testLRUEviction_HandlesAccessOrderSync()

    // Cache Key Generation
    func testCacheKey_IncludesPath()
    func testCacheKey_IncludesModificationDate()
    func testCacheKey_IncludesTheme()
    func testCacheKey_IncludesLanguage()
    func testCacheKey_InvalidatesOnThemeChange()
    func testCacheKey_ResolvesAutoTheme()

    // Thread Safety
    func testConcurrentReads_ThreadSafe()
    func testConcurrentWrites_ThreadSafe()
    func testConcurrentReadWrite_ThreadSafe()

    // Integration with DiskCache
    func testSet_WritesToBothMemoryAndDisk()
    func testGet_PromotesDiskHitsToMemory()
    func testClearMemory_PreservesDisk()
    func testClearAll_ClearsMemoryAndDisk()
}
```

**Coverage Target:** 95% line coverage, 90% branch coverage

---

#### 1.2 DiskCache.swift (418 lines) - ZERO COVERAGE
**Risk Level:** CRITICAL
**Test Gap Impact:** Persistence layer failures = cache corruption

**Untested Critical Paths:**
- ✗ RTF serialization/deserialization correctness
- ✗ Cache key validation (isValidCacheKey) security
- ✗ Cleanup rate limiting (30s minimum interval)
- ✗ LRU cleanup under size/entry limits (100MB, 500 entries)
- ✗ Corrupted file recovery (async deletion)
- ✗ Cache migration on version change
- ✗ Async write queue ordering

**Required Unit Tests:**
```swift
// DiskCacheTests.swift (MISSING)
class DiskCacheTests: XCTestCase {
    // Serialization
    func testRTFSerialization_PreservesAttributes()
    func testRTFDeserialization_HandlesCorruption()
    func testRTFRoundTrip_IsLossless()

    // Cache Key Validation (SECURITY)
    func testIsValidCacheKey_Accepts64HexChars()
    func testIsValidCacheKey_RejectsPathTraversal()
    func testIsValidCacheKey_RejectsNonHex()
    func testIsValidCacheKey_RejectsWrongLength()

    // Cleanup Logic
    func testCleanup_EnforcesMaxEntries()
    func testCleanup_EnforcesMaxSize()
    func testCleanup_RemovesOldestFirst()
    func testCleanup_RateLimited30Seconds()
    func testCleanup_SkipsWhenUnderLimits()

    // Cache Migration
    func testMigration_ClearsOldVersion()
    func testMigration_WritesNewVersion()
    func testMigration_PreservesVersionFile()

    // Error Handling
    func testGet_RemovesCorruptedFile()
    func testSet_CreatesDirectoryIfMissing()
    func testClear_HandlesIOErrors()
}
```

**Coverage Target:** 90% line coverage, 85% branch coverage

---

#### 1.3 LanguageDetector.swift (470 lines) - ZERO COVERAGE
**Risk Level:** HIGH
**Test Gap Impact:** Incorrect highlighting, security misdetection

**Untested Critical Paths:**
- ✗ Extension mapping (148 mappings untested)
- ✗ Dotfile detection (253 mappings untested)
- ✗ Shebang parsing
- ✗ Content-based detection (JSON, XML, YAML, INI, shell)
- ✗ Sensitive file detection (skipHighlightingFiles set)

**Required Unit Tests:**
```swift
// LanguageDetectorTests.swift (MISSING)
class LanguageDetectorTests: XCTestCase {
    // Extension Mapping
    func testDetect_JavaScript_FromMultipleExtensions()
    func testDetect_TypeScript_FromMTS_CTS_TS()
    func testDetect_Swift_FromSwift()
    func testDetect_CaseInsensitive()

    // Dotfile Detection
    func testDetect_GitConfig_ReturnsINI()
    func testDetect_Bashrc_ReturnsBash()
    func testDetect_EnvFile_ReturnsProperties()
    func testDetect_DockerIgnore_ReturnsBash()

    // Shebang Detection
    func testDetectFromShebang_Python()
    func testDetectFromShebang_Node()
    func testDetectFromShebang_Bash()
    func testDetectFromShebang_Ruby()

    // Content-Based Detection
    func testDetectFromContent_JSON_ObjectPattern()
    func testDetectFromContent_JSON_ArrayPattern()
    func testDetectFromContent_XML_DocTypePattern()
    func testDetectFromContent_YAML_KeyColonPattern()
    func testDetectFromContent_INI_SectionPattern()
    func testDetectFromContent_Shell_ExportPattern()
    func testDetectFromContent_Properties_KeyValuePattern()

    // Sensitive File Detection
    func testDetect_VimInfo_ReturnsPlaintext()
    func testDetect_BashHistory_ReturnsPlaintext()
    func testDetect_ZshHistory_ReturnsPlaintext()

    // Display Names
    func testDisplayName_HandlesUnknownLanguage()
    func testDisplayName_ReturnsCapitalized()
}
```

**Coverage Target:** 85% line coverage, 80% branch coverage

---

#### 1.4 SyntaxHighlighter.swift (171 lines) - ZERO COVERAGE
**Risk Level:** HIGH
**Test Gap Impact:** Performance regressions, incorrect highlighting

**Untested Critical Paths:**
- ✗ Theme color cache double-checked locking
- ✗ FastSyntaxHighlighter vs HighlightSwift routing
- ✗ Theme resolution (10 themes + "auto" mode)
- ✗ Appearance detection (light/dark)
- ✗ Cache invalidation on theme/appearance change

**Required Unit Tests:**
```swift
// SyntaxHighlighterTests.swift (MISSING)
class SyntaxHighlighterTests: XCTestCase {
    // Highlighter Selection
    func testHighlight_Usesfast_WhenSupported()
    func testHighlight_UsesFallback_WhenUnsupported()

    // Theme Color Caching
    func testColorCache_HitOnSameTheme()
    func testColorCache_InvalidatesOnThemeChange()
    func testColorCache_InvalidatesOnAppearanceChange()
    func testColorCache_ThreadSafe()

    // Theme Resolution
    func testResolveColors_AutoMode_Light()
    func testResolveColors_AutoMode_Dark()
    func testResolveColors_NamedTheme()
    func testResolveColors_BlackoutMode()

    // Error Handling
    func testHighlight_FallsBackToPlainText_OnError()
}
```

**Coverage Target:** 90% line coverage, 85% branch coverage

---

#### 1.5 FastSyntaxHighlighter.swift - ZERO COVERAGE
**Risk Level:** MEDIUM
**Test Gap Impact:** Performance critical path unverified

**Untested Critical Paths:**
- ✗ Language support detection (19 languages)
- ✗ Token pattern matching (keywords, strings, comments, numbers)
- ✗ Regex performance on large files
- ✗ Color attribute application

**Required Unit Tests:**
```swift
// FastSyntaxHighlighterTests.swift (MISSING)
class FastSyntaxHighlighterTests: XCTestCase {
    // Language Support
    func testIsSupported_Swift_ReturnsTrue()
    func testIsSupported_Go_ReturnsTrue()
    func testIsSupported_PHP_ReturnsFalse()

    // Syntax Highlighting Accuracy
    func testHighlight_Swift_Keywords()
    func testHighlight_Swift_Strings()
    func testHighlight_Swift_Comments()
    func testHighlight_Swift_Numbers()
    func testHighlight_JSON_Syntax()
    func testHighlight_Bash_Variables()

    // Performance
    func testHighlight_LargeFile_CompletesUnder2Seconds()
}
```

**Coverage Target:** 80% line coverage, 75% branch coverage

---

### 1.6 Unit Test Summary

| Component | LOC | Tests Required | Current Coverage | Target Coverage |
|-----------|-----|----------------|------------------|-----------------|
| HighlightCache | 177 | 22 tests | 0% | 95% |
| DiskCache | 418 | 24 tests | 0% | 90% |
| LanguageDetector | 470 | 27 tests | 0% | 85% |
| SyntaxHighlighter | 171 | 12 tests | 0% | 90% |
| FastSyntaxHighlighter | ~200 | 10 tests | 0% | 80% |
| **TOTAL** | **1,436** | **95 tests** | **0%** | **88%** |

---

## 2. Integration Test Coverage Analysis

### Critical Integration Gaps

#### 2.1 Cache Coordination (Memory ↔ Disk)
**Risk:** Cache promotion failures, stale data

**Missing Tests:**
```swift
// CacheIntegrationTests.swift (MISSING)
class CacheIntegrationTests: XCTestCase {
    func testCacheMiss_HighlightAndStore()
    func testDiskHit_PromotesToMemory()
    func testThemeChange_InvalidatesBothCaches()
    func testFileModification_InvalidatesCache()
    func testMemoryEviction_PreservesDisk()
    func testCacheWarmup_PopulatesMemory()
}
```

---

#### 2.2 Theme Switching Integration
**Risk:** Stale highlighting after theme change

**Missing Tests:**
```swift
// ThemeIntegrationTests.swift (MISSING)
class ThemeIntegrationTests: XCTestCase {
    func testThemeSwitch_InvalidatesCache()
    func testThemeSwitch_ReHighlightsContent()
    func testAutoTheme_SwitchesWithAppearance()
    func testThemeSwitch_UpdatesBackgroundColor()
}
```

---

#### 2.3 File Loading → Highlighting → Caching Pipeline
**Risk:** Pipeline failures in production

**Missing Tests:**
```swift
// FileLoadingIntegrationTests.swift (MISSING)
class FileLoadingIntegrationTests: XCTestCase {
    func testPipeline_NewFile_ColdCache()
    func testPipeline_ExistingFile_WarmCache()
    func testPipeline_LargeFile_SkipsHighlighting()
    func testPipeline_BinaryFile_HandlesGracefully()
    func testPipeline_TruncatedFile_ShowsWarning()
}
```

---

#### 2.4 Language Detection → Highlighting Integration
**Risk:** Incorrect language = wrong highlighting

**Missing Tests:**
```swift
// LanguageHighlightingIntegrationTests.swift (MISSING)
class LanguageHighlightingIntegrationTests: XCTestCase {
    func testDetectAndHighlight_JavaScript()
    func testDetectAndHighlight_TypeScript()
    func testDetectAndHighlight_Swift()
    func testDetectAndHighlight_Dotfile_Bashrc()
    func testDetectAndHighlight_Shebang_Python()
    func testDetectAndHighlight_ContentBased_JSON()
    func testDetectAndHighlight_Unknown_PlainText()
}
```

---

### 2.5 Integration Test Summary

| Integration Scenario | Tests Required | Current Coverage |
|---------------------|----------------|------------------|
| Cache Coordination | 6 tests | 0% |
| Theme Switching | 4 tests | 0% |
| File Loading Pipeline | 5 tests | 0% |
| Language Detection | 7 tests | 0% |
| **TOTAL** | **22 tests** | **0%** |

---

## 3. End-to-End Test Analysis

### Current E2E Testing Infrastructure

#### 3.1 Existing E2E Tests (Manual)
**Location:** `/TestFiles/run_e2e_test.sh`
**Type:** Manual shell script with log streaming
**Coverage:** Basic file preview verification

**Current Capabilities:**
- ✓ QuickLook daemon reset (`qlmanage -r`)
- ✓ Log streaming (subsystem filter)
- ✓ Test file categorization (source, config, shell, docs)
- ✓ Build integration (`--build` flag)
- ✓ Quick mode testing (`--quick` flag)

**Limitations:**
- ✗ No automated assertions
- ✗ No pass/fail criteria
- ✗ No CI/CD integration
- ✗ No screenshot comparison
- ✗ No performance benchmarking
- ✗ Manual log analysis required

---

#### 3.2 Test Files Coverage

**Source Code Files:** 13 files (JS, TS, Python, Go, Rust, Swift, etc.)
**Config Files:** 7 files (JSON, YAML, XML, PLIST)
**Shell Scripts:** 3 files (Bash, Zsh)
**Documentation:** 1 file (Markdown)
**Sensitive Files:** 1 file (.env) - security test case

**Performance Test Files (perf-test/):**
| File | Size | Purpose |
|------|------|---------|
| large-zsh-history.zsh | 80KB | Stress test (max file size) |
| large-cli.zsh | 27KB | Medium file test |
| large-claude.json | 26KB | JSON parsing test |
| large-readme.md | 21KB | Markdown rendering test |
| large-changelog.sh | 17KB | Shell highlighting test |

---

#### 3.3 Missing E2E Scenarios

**Quick Look Extension Lifecycle:**
- ✗ Extension activation after installation
- ✗ Extension registration with `pluginkit`
- ✗ XPC service initialization
- ✗ Extension termination and restart
- ✗ Cache persistence across XPC restarts

**User Interaction Flows:**
- ✗ Finder Quick Look (spacebar) activation
- ✗ Finder preview pane rendering
- ✗ File selection changes (rapid navigation)
- ✗ Theme switching while preview open
- ✗ Settings changes propagation

**Error Scenarios:**
- ✗ Corrupted file handling
- ✗ Permission denied errors
- ✗ Network file system lag
- ✗ Out of memory conditions
- ✗ Cache directory inaccessible

---

### 3.4 Required E2E Test Automation

```swift
// E2ETestSuite.swift (MISSING)
class QuickLookExtensionE2ETests: XCTestCase {
    // Extension Lifecycle
    func testExtension_LoadsAfterInstallation()
    func testExtension_RegistersWithPluginKit()
    func testExtension_SurvivesXPCRestart()

    // Preview Rendering
    func testQuickLook_RendersSwiftFile()
    func testQuickLook_RendersMarkdownFile()
    func testQuickLook_RendersSensitiveFile_ShowsBanner()
    func testQuickLook_RendersTruncatedFile_ShowsWarning()

    // Performance
    func testQuickLook_80KBFile_LoadsUnder3Seconds()
    func testQuickLook_CachedFile_LoadsUnder500ms()
    func testQuickLook_RapidNavigation_NoCrashes()

    // Theme Switching
    func testQuickLook_ThemeSwitch_UpdatesLivePreview()

    // Error Handling
    func testQuickLook_CorruptedFile_ShowsError()
    func testQuickLook_PermissionDenied_ShowsError()
}
```

---

### 3.5 E2E Test Summary

| Category | Scenarios Required | Current Automated | Gap |
|----------|-------------------|-------------------|-----|
| Extension Lifecycle | 5 | 0 | 5 |
| Preview Rendering | 8 | 0 | 8 |
| Performance | 3 | 0 | 3 |
| Theme Switching | 2 | 0 | 2 |
| Error Handling | 3 | 0 | 3 |
| **TOTAL** | **21** | **0** | **21** |

---

## 4. Test Pyramid Adherence

### Current Pyramid (INVERTED)

```
                 /\
                /  \
               /    \
              /      \
             /________\
            E2E: 1 manual script

           Integration: 0 tests

          Unit: 0 tests
```

**Problem:** Inverted pyramid = slow, brittle, expensive testing

---

### Target Pyramid (Recommended)

```
                 /\
                /E2E\  (21 automated tests)
               /------\
              /        \
             /Integration\ (22 tests)
            /-------------\
           /               \
          /      Unit       \ (95 tests)
         /_________________\
```

**Target Distribution:**
- **Unit Tests:** 95 tests (69% of total)
- **Integration Tests:** 22 tests (16% of total)
- **E2E Tests:** 21 tests (15% of total)

**Pyramid Health Score:** 0/10 → Target: 9/10

---

## 5. Test Maintainability Analysis

### 5.1 Test Isolation
**Current:** N/A (no tests exist)
**Required for TDD:**
- Each test must be independent
- No shared state between tests
- Setup/teardown isolation
- Parallel execution safety

### 5.2 Mock/Stub Strategy
**Current:** No mocking framework detected
**Recommendations:**
```swift
// Mock framework required for testing
protocol HighlightCacheProtocol {
    func get(path: String, modDate: Date, theme: String, language: String?) -> AttributedString?
    func set(path: String, modDate: Date, theme: String, language: String?, highlighted: AttributedString)
}

// Mock implementation for testing
class MockHighlightCache: HighlightCacheProtocol {
    var getCalls: [(path: String, modDate: Date, theme: String, language: String?)] = []
    var setCalls: [(path: String, modDate: Date, theme: String, language: String?, highlighted: AttributedString)] = []
    var mockGetReturn: AttributedString?

    func get(path: String, modDate: Date, theme: String, language: String?) -> AttributedString? {
        getCalls.append((path, modDate, theme, language))
        return mockGetReturn
    }

    func set(path: String, modDate: Date, theme: String, language: String?, highlighted: AttributedString) {
        setCalls.append((path, modDate, theme, language, highlighted))
    }
}
```

### 5.3 Test Flakiness Risk
**Current Risk:** N/A (no tests to be flaky)
**Future Risk Areas:**
- Timing-dependent cache cleanup tests
- Async/await race conditions
- Appearance-based theme tests
- File system state dependencies

**Mitigation Strategies:**
- Use `XCTestExpectation` for async operations
- Mock `FileManager` for deterministic I/O
- Inject `Date` dependencies for time-based tests
- Use in-memory cache for unit tests

---

## 6. Test Quality Metrics

### 6.1 Assertion Density
**Current:** N/A
**Target:** 3-5 assertions per test (focused tests)

**Anti-patterns to Avoid:**
```swift
// BAD: Single assertion per test (too granular)
func testCacheKey() {
    XCTAssertNotNil(cache.cacheKey(...))
}

// GOOD: Focused test with multiple related assertions
func testCacheKey_IncludesAllMetadata() {
    let key1 = cache.cacheKey(path: "a", modDate: date1, theme: "light", language: "swift")
    let key2 = cache.cacheKey(path: "b", modDate: date1, theme: "light", language: "swift")
    let key3 = cache.cacheKey(path: "a", modDate: date2, theme: "light", language: "swift")
    let key4 = cache.cacheKey(path: "a", modDate: date1, theme: "dark", language: "swift")

    XCTAssertNotEqual(key1, key2) // Different paths
    XCTAssertNotEqual(key1, key3) // Different mod dates
    XCTAssertNotEqual(key1, key4) // Different themes
    XCTAssertEqual(key1.count, 64) // SHA256 hash length
}
```

---

### 6.2 Test Naming Conventions
**Required Standard:**
```swift
// Pattern: test[MethodName]_[Scenario]_[ExpectedResult]
func testGet_MemoryCacheHit_ReturnsImmediately()
func testGet_DiskCacheHit_PromotesToMemory()
func testGet_CacheMiss_ReturnsNil()
func testLRUEviction_WhenFull_RemovesOldest()
func testCacheKey_WhenThemeChanges_GeneratesDifferentKey()
```

---

### 6.3 Code Coverage Targets

| Component Type | Line Coverage | Branch Coverage |
|---------------|---------------|-----------------|
| Core Logic (Cache, Highlighter) | 95% | 90% |
| Utilities (LanguageDetector) | 85% | 80% |
| UI (PreviewContentView) | 70% | 60% |
| **Overall Target** | **85%** | **75%** |

**Current Coverage:** 0% → **Target:** 85% within Phase 3

---

## 7. Security Testing Requirements

### 7.1 Security Findings Requiring Test Coverage

#### DOTV-2026-002: Sensitive File Clipboard Copy
**Status:** Medium Risk, UI-only warning
**Test Gap:** No automated verification of warning banner

**Required Tests:**
```swift
// SecurityTests.swift (MISSING)
class SensitiveFileSecurityTests: XCTestCase {
    func testIsEnvFile_DotEnv_ReturnsTrue()
    func testIsEnvFile_DotEnvLocal_ReturnsTrue()
    func testIsEnvFile_Credentials_ReturnsTrue()
    func testIsEnvFile_AWSCredentials_ReturnsTrue()
    func testIsEnvFile_SSHPrivateKey_ReturnsTrue()
    func testIsEnvFile_PEMFile_ReturnsTrue()
    func testIsEnvFile_RegularFile_ReturnsFalse()

    // UI Integration
    func testEnvFileBanner_DisplayedForSensitiveFiles()
    func testEnvFileBanner_NotDisplayedForRegularFiles()
}
```

---

#### DOTV-2026-001: Path Exposure in Logs
**Status:** Low Risk, production logs sanitized
**Test Gap:** No automated verification of log sanitization

**Required Tests:**
```swift
class LogSanitizationTests: XCTestCase {
    func testPerfLog_Production_DoesNotLogPaths()
    func testPerfLog_Debug_LogsPaths()
    func testNSLog_NeverLogsPaths()
}
```

---

#### DOTV-2026-004: Cache Integrity Validation
**Status:** Low Risk, validation exists
**Test Gap:** No automated test of validation logic

**Required Tests:**
```swift
class CacheValidationTests: XCTestCase {
    func testIsValidCacheKey_64HexChars_Valid()
    func testIsValidCacheKey_PathTraversal_Invalid()
    func testIsValidCacheKey_NonHex_Invalid()
    func testIsValidCacheKey_WrongLength_Invalid()
    func testIsValidCacheKey_Slash_Invalid()
    func testIsValidCacheKey_DoubleDot_Invalid()
}
```

---

#### DOTV-2026-005: Custom Extension Validation
**Status:** Low Risk, comprehensive validation
**Test Gap:** No automated test of edge cases

**Required Tests:**
```swift
class CustomExtensionValidationTests: XCTestCase {
    func testValidateExtension_PathTraversal_Rejected()
    func testValidateExtension_TooLong_Rejected()
    func testValidateExtension_InvalidChars_Rejected()
    func testValidateExtension_ReservedExtension_Rejected()
    func testValidateExtension_Valid_Accepted()
    func testValidateExtension_EmptyAfterCleaning_Rejected()
}
```

---

### 7.2 Security Test Summary

| Security Finding | Test Coverage Required | Current Coverage |
|-----------------|------------------------|------------------|
| DOTV-2026-002 (Sensitive Files) | 9 tests | 0% |
| DOTV-2026-001 (Log Sanitization) | 3 tests | 0% |
| DOTV-2026-004 (Cache Validation) | 6 tests | 0% |
| DOTV-2026-005 (Extension Validation) | 6 tests | 0% |
| **TOTAL** | **24 tests** | **0%** |

---

## 8. Performance Testing Requirements

### 8.1 Performance Findings Requiring Test Coverage

#### Memory Cache Byte Limit Enforcement
**Requirement:** 100MB max, 500 entries max
**Test Gap:** No automated validation

**Required Tests:**
```swift
// PerformanceTests.swift (MISSING)
class CachePerformanceTests: XCTestCase {
    func testDiskCache_Cleanup_EnforcesMaxSize100MB()
    func testDiskCache_Cleanup_EnforcesMaxEntries500()
    func testDiskCache_Cleanup_RemovesOldestFirst()

    // Benchmark tests
    func testMemoryCache_Get_CompletesUnder1ms()
    func testDiskCache_Get_CompletesUnder50ms()
}
```

---

#### Cache Cleanup Rate Limiting (30s)
**Requirement:** Minimum 30s between cleanups
**Test Gap:** No automated test of rate limiter

**Required Tests:**
```swift
class CacheCleanupRateLimitingTests: XCTestCase {
    func testCleanup_RateLimited_SkipsWithin30s()
    func testCleanup_RateLimited_AllowsAfter30s()
    func testCleanup_WriteCount_ResetsAfterCleanup()
}
```

---

#### Highlighting Timeout (2s)
**Requirement:** Highlighting completes <2s or skips
**Test Gap:** No automated timeout verification

**Required Tests:**
```swift
class HighlightingPerformanceTests: XCTestCase {
    func testHighlight_80KBFile_CompletesUnder2Seconds()
    func testHighlight_2000LineFile_Skipped()
    func testHighlight_Timeout_ReturnPlainText()
}
```

---

#### Rapid File Navigation (140 BPM)
**Requirement:** Cache handles rapid switching without crashes
**Test Gap:** No stress test automation

**Required Tests:**
```swift
class RapidNavigationStressTests: XCTestCase {
    func testRapidNavigation_140BPM_NoCrashes()
    func testRapidNavigation_CacheHitRate_Above80Percent()
    func testRapidNavigation_MemoryStable()
}
```

---

### 8.2 Performance Test Summary

| Performance Requirement | Test Coverage Required | Current Coverage |
|------------------------|------------------------|------------------|
| Cache Size Limits | 3 tests | 0% |
| Cleanup Rate Limiting | 3 tests | 0% |
| Highlighting Timeout | 3 tests | 0% |
| Rapid Navigation | 3 tests | 0% |
| **TOTAL** | **12 tests** | **0%** |

---

## 9. TDD Practices Verification

### 9.1 TDD Compliance Score: 0/10

**Evidence of TDD:**
- ✗ No test files found
- ✗ No `@testable import` statements
- ✗ No test target in Xcode project
- ✗ No failing tests committed before implementation
- ✗ No test-first commit history

**Impact:**
- High risk of design-driven architecture (not test-driven)
- Difficult to refactor God Class (PreviewContentView: 1471 lines)
- No safety net for performance optimizations
- Security fixes lack regression protection

---

### 9.2 TDD Adoption Roadmap

#### Phase 1: Foundation (Week 1-2)
1. Add XCTest targets to Xcode project
2. Set up test infrastructure (mocks, fixtures)
3. Write 20 unit tests for critical paths (cache, validation)
4. Achieve 30% code coverage baseline

#### Phase 2: Core Coverage (Week 3-4)
5. Write 75 additional unit tests
6. Add 22 integration tests
7. Achieve 60% code coverage
8. Implement CI/CD test pipeline

#### Phase 3: Security & Performance (Week 5-6)
9. Add 24 security tests
10. Add 12 performance tests
11. Achieve 85% code coverage target
12. Add E2E automation framework

#### Phase 4: TDD Enforcement (Week 7-8)
13. Implement pre-commit hooks (requires tests)
14. Add code coverage gates (85% minimum)
15. Document TDD workflow for team
16. Refactor God Class with test coverage

---

## 10. Testing Gap Analysis & Recommendations

### 10.1 Critical Gaps Summary

| Gap Category | Severity | Tests Required | Effort (Hours) |
|-------------|----------|----------------|----------------|
| Unit Tests | CRITICAL | 95 | 80 |
| Integration Tests | HIGH | 22 | 30 |
| E2E Automation | HIGH | 21 | 40 |
| Security Tests | MEDIUM | 24 | 20 |
| Performance Tests | MEDIUM | 12 | 15 |
| **TOTAL** | - | **174 tests** | **185 hours** |

---

### 10.2 Prioritized Test Implementation Plan

#### Priority 1: Safety Net (Week 1-2, 40 hours)
**Goal:** Prevent regressions in critical paths

**Tests to Implement:**
1. HighlightCache unit tests (22 tests) - 15 hours
2. DiskCache security tests (6 tests) - 5 hours
3. Cache integration tests (6 tests) - 10 hours
4. Performance baseline tests (5 tests) - 10 hours

**Deliverable:** 39 tests, 40% coverage

---

#### Priority 2: Security Validation (Week 3, 20 hours)
**Goal:** Automate validation of all 11 security findings

**Tests to Implement:**
1. Sensitive file detection (9 tests) - 8 hours
2. Cache key validation (6 tests) - 4 hours
3. Extension validation (6 tests) - 4 hours
4. Log sanitization (3 tests) - 4 hours

**Deliverable:** 24 tests, security compliance automated

---

#### Priority 3: Language Detection (Week 4, 25 hours)
**Goal:** Ensure correct highlighting for all file types

**Tests to Implement:**
1. Extension mapping (10 tests) - 8 hours
2. Dotfile detection (8 tests) - 7 hours
3. Content-based detection (9 tests) - 10 hours

**Deliverable:** 27 tests, language detection verified

---

#### Priority 4: Performance Testing (Week 5, 20 hours)
**Goal:** Validate cache performance and cleanup

**Tests to Implement:**
1. Cache cleanup tests (6 tests) - 8 hours
2. Highlighting performance (3 tests) - 6 hours
3. Stress tests (3 tests) - 6 hours

**Deliverable:** 12 tests, performance validated

---

#### Priority 5: E2E Automation (Week 6-7, 40 hours)
**Goal:** Automate Quick Look extension testing

**Tests to Implement:**
1. Extension lifecycle (5 tests) - 12 hours
2. Preview rendering (8 tests) - 15 hours
3. Performance E2E (3 tests) - 8 hours
4. Error handling (3 tests) - 5 hours

**Deliverable:** 19 tests, E2E automation complete

---

#### Priority 6: Integration Tests (Week 8, 30 hours)
**Goal:** Verify component interactions

**Tests to Implement:**
1. File loading pipeline (5 tests) - 10 hours
2. Theme switching (4 tests) - 8 hours
3. Language highlighting integration (7 tests) - 12 hours

**Deliverable:** 16 tests, integration verified

---

### 10.3 Test Infrastructure Requirements

#### XCTest Target Setup
```bash
# Add test targets to dotViewer.xcodeproj
# - dotViewerTests (unit tests)
# - dotViewerIntegrationTests (integration tests)
# - dotViewerE2ETests (end-to-end tests)
```

#### Test Dependencies
```swift
// Package.swift additions required
.testTarget(
    name: "dotViewerTests",
    dependencies: ["dotViewer"]
)
```

#### CI/CD Integration
```yaml
# .github/workflows/tests.yml (MISSING)
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Tests
        run: xcodebuild test -scheme dotViewer -destination 'platform=macOS'
      - name: Code Coverage
        run: xcrun llvm-cov report --summary-only
```

---

## 11. Code Coverage Report (Current vs Target)

### 11.1 Current Coverage: 0%

**No automated tests exist. Manual coverage estimation based on E2E script:**
- E2E Manual Coverage: ~5% (basic file preview smoke test)
- Unit Coverage: 0%
- Integration Coverage: 0%
- Security Coverage: 0%
- Performance Coverage: 0%

---

### 11.2 Target Coverage: 85%

| Component | LOC | Current | Target | Tests Required |
|-----------|-----|---------|--------|----------------|
| HighlightCache.swift | 177 | 0% | 95% | 22 |
| DiskCache.swift | 418 | 0% | 90% | 24 |
| LanguageDetector.swift | 470 | 0% | 85% | 27 |
| SyntaxHighlighter.swift | 171 | 0% | 90% | 12 |
| FastSyntaxHighlighter.swift | ~200 | 0% | 80% | 10 |
| PreviewContentView.swift | 1471 | 0% | 70% | 35 |
| FileTypeRegistry.swift | ~300 | 0% | 85% | 15 |
| ThemeManager.swift | ~150 | 0% | 90% | 12 |
| SharedSettings.swift | ~200 | 0% | 85% | 10 |
| Logger.swift | ~100 | 0% | 80% | 7 |
| **TOTAL** | **~3,657** | **0%** | **85%** | **174** |

---

### 11.3 Coverage Roadmap

```
Week 1-2:  0% →  40%  (39 tests: Critical path safety net)
Week 3:   40% →  50%  (24 tests: Security validation)
Week 4:   50% →  60%  (27 tests: Language detection)
Week 5:   60% →  65%  (12 tests: Performance)
Week 6-7: 65% →  75%  (19 tests: E2E automation)
Week 8:   75% →  85%  (16 tests: Integration)
```

**Total Time Investment:** 185 hours (8 weeks @ 23 hours/week)

---

## 12. Test Automation Recommendations

### 12.1 Testing Framework Stack

**Unit & Integration Tests:**
- XCTest (Apple's native framework)
- XCTestExpectation (async/await support)
- ViewInspector (SwiftUI testing)

**E2E Tests:**
- XCUITest (macOS UI automation)
- Quick Look extension testing via `qlmanage` CLI
- Console log parsing for verification

**Performance Tests:**
- XCTMetric (XCTest performance API)
- Instruments profiling integration
- Custom benchmark harness for cache timing

**Code Coverage:**
- Xcode Code Coverage (built-in)
- xcov (human-readable coverage reports)
- Codecov.io (PR coverage diff visualization)

---

### 12.2 CI/CD Pipeline Integration

**Pre-commit Hooks:**
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Run unit tests
xcodebuild test -scheme dotViewer -destination 'platform=macOS' || exit 1

# Check coverage threshold
COVERAGE=$(xcrun llvm-cov report | grep "TOTAL" | awk '{print $NF}' | sed 's/%//')
if (( $(echo "$COVERAGE < 85.0" | bc -l) )); then
    echo "Error: Coverage $COVERAGE% is below threshold 85%"
    exit 1
fi
```

**Pull Request Checks:**
- All tests must pass
- Coverage must not decrease
- Performance benchmarks within 10% of baseline

**Nightly Builds:**
- Full E2E suite on physical hardware
- Performance regression detection
- Memory leak detection (Instruments)

---

### 12.3 Test Data Management

**Fixture Files:**
```
Tests/
├── Fixtures/
│   ├── sample.swift (250 lines, valid Swift)
│   ├── sample.json (5KB, valid JSON)
│   ├── large.zsh (80KB, stress test)
│   ├── corrupted.txt (invalid UTF-8)
│   ├── sensitive/.env (security test)
│   └── binary.bin (binary file test)
```

**Mock Data Generation:**
```swift
// TestHelpers.swift
extension AttributedString {
    static func mock(length: Int) -> AttributedString {
        var str = AttributedString(String(repeating: "x", count: length))
        str.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        return str
    }
}

extension Date {
    static func mockDate(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)!
    }
}
```

---

## 13. Testing Best Practices for macOS Quick Look Extensions

### 13.1 Extension-Specific Challenges

**Challenge 1: XPC Isolation**
- Quick Look runs in sandboxed XPC service
- Cannot access main app state directly
- Must test in isolation

**Solution:**
```swift
// Test in-process instead of XPC for unit tests
class HighlightCacheTests: XCTestCase {
    var cache: HighlightCache!

    override func setUp() {
        cache = HighlightCache()
        cache.clearAll() // Clean state for each test
    }
}
```

---

**Challenge 2: UI Testing in Quick Look**
- Quick Look UI is system-controlled
- Cannot launch Quick Look directly in UI tests

**Solution:**
```swift
// Test preview view in isolation
class PreviewContentViewTests: XCTestCase {
    func testPreviewView_RendersSwiftFile() {
        let state = PreviewState(
            content: "let x = 42",
            filename: "test.swift",
            language: "swift",
            // ...
        )

        let view = PreviewContentView(state: state)
        let hosting = NSHostingView(rootView: view)

        // Verify rendering
        XCTAssertNotNil(hosting)
    }
}
```

---

**Challenge 3: Cache Persistence Testing**
- Cache survives XPC termination
- Difficult to simulate in unit tests

**Solution:**
```swift
// Integration test with actual file system
class DiskCachePersistenceTests: XCTestCase {
    func testDiskCache_SurvivesReinitialization() {
        let cache1 = DiskCache.shared
        cache1.set(key: testKey, value: testData)

        // Simulate XPC restart by creating new instance
        // (In real app, DiskCache.shared is singleton)
        let cache2 = DiskCache.shared
        let retrieved = cache2.get(key: testKey)

        XCTAssertEqual(retrieved, testData)
    }
}
```

---

### 13.2 Testing SwiftUI Preview Views

**Challenge:** SwiftUI views are declarative, hard to test

**Solution: ViewInspector Framework**
```swift
import ViewInspector

extension PreviewContentView: Inspectable {}

class PreviewContentViewTests: XCTestCase {
    func testEnvFileBanner_DisplayedForSensitiveFiles() throws {
        let state = PreviewState(
            // ... sensitive file state
            filename: ".env"
        )

        let view = PreviewContentView(state: state)
        let banner = try view.inspect().find(EnvFileSecurityBanner.self)

        XCTAssertNotNil(banner)
    }
}
```

---

## 14. Recommendations Summary

### 14.1 Immediate Actions (Week 1)

1. **Create Test Targets** (2 hours)
   - Add `dotViewerTests` target to Xcode project
   - Configure test scheme
   - Add `@testable import dotViewer` to test files

2. **Implement Critical Path Tests** (20 hours)
   - HighlightCache: 10 tests (LRU, cache key, thread safety)
   - DiskCache: 8 tests (validation, cleanup)
   - Integration: 5 tests (cache coordination)

3. **Set Up CI/CD** (8 hours)
   - GitHub Actions workflow for automated testing
   - Code coverage reporting
   - Pre-commit hooks

---

### 14.2 Short-Term Goals (Month 1)

**Target:** 60% code coverage, 80 tests
- Complete all unit tests for core components
- Add security validation tests
- Implement language detection tests
- Set up performance benchmarking

---

### 14.3 Long-Term Goals (Quarter 1)

**Target:** 85% code coverage, 174 tests
- Complete E2E automation
- Full integration test suite
- Performance regression testing
- TDD workflow enforcement

---

## 15. Test Coverage Gaps - Detailed Breakdown

### 15.1 Untested Critical Paths

**HighlightCache:**
1. ✗ Memory cache LRU eviction edge cases (full → evict → re-add)
2. ✗ Disk cache promotion race conditions (concurrent gets)
3. ✗ Cache key collision handling (SHA256 unlikely but possible)
4. ✗ Theme change invalidation propagation
5. ✗ Memory pressure handling (no explicit limit enforcement)

**DiskCache:**
6. ✗ RTF serialization attribute preservation (colors, fonts)
7. ✗ Cleanup under concurrent writes (race condition)
8. ✗ Cache directory migration failures
9. ✗ Disk full error handling
10. ✗ File system permission errors

**LanguageDetector:**
11. ✗ Shebang parsing with unusual whitespace
12. ✗ Content-based detection false positives
13. ✗ Dotfile extension edge cases (.eslintrc.json.backup)
14. ✗ Binary file detection (UTF-8 validation)
15. ✗ Very large file language detection timeout

**SyntaxHighlighter:**
16. ✗ Appearance change during highlighting
17. ✗ Theme cache invalidation race conditions
18. ✗ HighlightSwift fallback error handling
19. ✗ Color cache thread safety under concurrent requests
20. ✗ Timeout handling for very large files

**PreviewContentView:**
21. ✗ Compact mode detection edge cases (349px width)
22. ✗ Markdown rendering mode switching
23. ✗ Truncation banner display logic
24. ✗ Sensitive file banner for edge case filenames
25. ✗ Background color updates on theme change

---

### 15.2 Integration Test Gaps

**Cache Coordination:**
1. ✗ Memory eviction → disk read → memory promotion cycle
2. ✗ Concurrent cache reads during cleanup
3. ✗ Theme change → cache invalidation → re-highlight pipeline

**File Loading Pipeline:**
4. ✗ Language detection → highlighting → caching full flow
5. ✗ Cache hit → skip highlighting optimization
6. ✗ File modification → cache invalidation → re-highlight

**Theme Management:**
7. ✗ Theme switch → appearance cache invalidation
8. ✗ Auto theme → system appearance change detection
9. ✗ Background color synchronization with syntax colors

**Settings Propagation:**
10. ✗ Settings change in main app → Quick Look extension update
11. ✗ Font size change → re-layout trigger
12. ✗ Line number toggle → view update

---

### 15.3 E2E Test Gaps

**Extension Lifecycle:**
1. ✗ First launch after installation (extension registration)
2. ✗ Extension crash recovery (XPC restart)
3. ✗ Multiple Quick Look windows (state isolation)

**User Workflows:**
4. ✗ Finder → Select file → Preview pane → Quick Look transition
5. ✗ Rapid file navigation (arrow keys, stress test)
6. ✗ Theme switch while Quick Look window open

**Performance:**
7. ✗ Cold cache first load (3s target)
8. ✗ Warm cache second load (0.5s target)
9. ✗ Cache hit rate during rapid navigation (>80%)

**Error Scenarios:**
10. ✗ Corrupted file graceful degradation
11. ✗ Network file system timeout handling
12. ✗ Out of disk space error

---

## 16. Final Recommendations

### 16.1 Testing Strategy Priorities

**Priority 1: Risk Mitigation (Week 1-2)**
- Focus on critical path tests (cache, validation)
- Prevent regressions during God Class refactoring
- Establish safety net before architectural changes

**Priority 2: Security Compliance (Week 3)**
- Automate validation of all 11 security findings
- Add regression tests for path traversal prevention
- Verify sensitive file detection edge cases

**Priority 3: Performance Validation (Week 4-5)**
- Benchmark cache hit rates
- Validate cleanup rate limiting
- Stress test rapid navigation (140 BPM)

**Priority 4: E2E Automation (Week 6-7)**
- Replace manual testing with automated suite
- Integrate with CI/CD pipeline
- Add screenshot comparison for UI regression

**Priority 5: Integration Verification (Week 8)**
- Test component interactions
- Validate theme switching propagation
- Verify settings synchronization

---

### 16.2 Success Metrics

**Code Coverage:**
- Week 2: 40% (critical path coverage)
- Month 1: 60% (unit + security coverage)
- Month 2: 85% (target coverage achieved)

**Test Count:**
- Week 2: 39 tests
- Month 1: 90 tests
- Month 2: 174 tests

**Test Pyramid Health:**
- Current: 0/10 (inverted pyramid)
- Target: 9/10 (healthy pyramid)

**CI/CD Integration:**
- Pre-commit hooks enforcing test passage
- PR coverage diff reporting
- Nightly E2E regression suite

---

### 16.3 Long-Term Testing Vision

**Shift-Left Testing:**
- TDD enforcement for all new features
- Test-first bug fixes
- Property-based testing for algorithms

**Continuous Quality:**
- Automated performance regression detection
- Security vulnerability scanning in CI/CD
- Mutation testing for test quality validation

**Team Enablement:**
- TDD training and kata sessions
- Code review checklist including test coverage
- Testing documentation and best practices guide

---

## Appendix A: Test File Structure

```
dotViewer/
├── dotViewerTests/
│   ├── Unit/
│   │   ├── HighlightCacheTests.swift (22 tests)
│   │   ├── DiskCacheTests.swift (24 tests)
│   │   ├── LanguageDetectorTests.swift (27 tests)
│   │   ├── SyntaxHighlighterTests.swift (12 tests)
│   │   ├── FastSyntaxHighlighterTests.swift (10 tests)
│   │   └── Helpers/
│   │       ├── MockHighlightCache.swift
│   │       ├── MockDiskCache.swift
│   │       └── TestFixtures.swift
│   ├── Integration/
│   │   ├── CacheIntegrationTests.swift (6 tests)
│   │   ├── ThemeIntegrationTests.swift (4 tests)
│   │   ├── FileLoadingIntegrationTests.swift (5 tests)
│   │   └── LanguageHighlightingIntegrationTests.swift (7 tests)
│   ├── Security/
│   │   ├── SensitiveFileDetectionTests.swift (9 tests)
│   │   ├── CacheValidationTests.swift (6 tests)
│   │   ├── ExtensionValidationTests.swift (6 tests)
│   │   └── LogSanitizationTests.swift (3 tests)
│   ├── Performance/
│   │   ├── CachePerformanceTests.swift (6 tests)
│   │   ├── HighlightingPerformanceTests.swift (3 tests)
│   │   └── StressTests.swift (3 tests)
│   └── Fixtures/
│       ├── sample.swift
│       ├── sample.json
│       ├── large.zsh
│       ├── corrupted.txt
│       └── sensitive/.env
├── dotViewerE2ETests/
│   ├── QuickLookExtensionE2ETests.swift (21 tests)
│   ├── PreviewRenderingE2ETests.swift
│   └── PerformanceE2ETests.swift
└── TestPlans/
    ├── UnitTests.xctestplan
    ├── IntegrationTests.xctestplan
    ├── E2ETests.xctestplan
    └── AllTests.xctestplan
```

---

## Appendix B: Example Test Implementation

### HighlightCacheTests.swift (Sample)

```swift
import XCTest
@testable import dotViewer

final class HighlightCacheTests: XCTestCase {
    var cache: HighlightCache!
    let testPath = "/path/to/test.swift"
    let testDate = Date()
    let testTheme = "xcodeDark"
    let testLanguage = "swift"

    override func setUp() {
        super.setUp()
        cache = HighlightCache()
        cache.clearAll()
    }

    override func tearDown() {
        cache.clearAll()
        cache = nil
        super.tearDown()
    }

    // MARK: - Cache Hit Tests

    func testMemoryCacheHit_ReturnsImmediately() {
        // Given
        let highlighted = AttributedString("test code")
        cache.set(path: testPath, modDate: testDate, theme: testTheme, language: testLanguage, highlighted: highlighted)

        // When
        let result = cache.get(path: testPath, modDate: testDate, theme: testTheme, language: testLanguage)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.description, highlighted.description)
    }

    func testCacheMiss_ReturnsNil() {
        // When
        let result = cache.get(path: testPath, modDate: testDate, theme: testTheme, language: testLanguage)

        // Then
        XCTAssertNil(result)
    }

    // MARK: - LRU Eviction Tests

    func testLRUEviction_RemovesOldestWhenFull() {
        // Given: Fill cache to capacity (20 entries)
        for i in 0..<20 {
            let path = "/path/file\(i).swift"
            cache.set(path: path, modDate: testDate, theme: testTheme, language: testLanguage, highlighted: AttributedString("code \(i)"))
        }

        // When: Add 21st entry
        let newPath = "/path/file20.swift"
        cache.set(path: newPath, modDate: testDate, theme: testTheme, language: testLanguage, highlighted: AttributedString("code 20"))

        // Then: First entry should be evicted
        let firstResult = cache.get(path: "/path/file0.swift", modDate: testDate, theme: testTheme, language: testLanguage)
        let lastResult = cache.get(path: newPath, modDate: testDate, theme: testTheme, language: testLanguage)

        XCTAssertNil(firstResult, "Oldest entry should be evicted")
        XCTAssertNotNil(lastResult, "Newest entry should exist")
    }

    // MARK: - Cache Key Generation Tests

    func testCacheKey_ChangesWhenPathChanges() {
        // Given
        let key1 = cache.cacheKey(path: "/path/a.swift", modDate: testDate, theme: testTheme, language: testLanguage)
        let key2 = cache.cacheKey(path: "/path/b.swift", modDate: testDate, theme: testTheme, language: testLanguage)

        // Then
        XCTAssertNotEqual(key1, key2)
    }

    func testCacheKey_ChangesWhenModificationDateChanges() {
        // Given
        let date1 = Date()
        let date2 = Date().addingTimeInterval(3600)

        let key1 = cache.cacheKey(path: testPath, modDate: date1, theme: testTheme, language: testLanguage)
        let key2 = cache.cacheKey(path: testPath, modDate: date2, theme: testTheme, language: testLanguage)

        // Then
        XCTAssertNotEqual(key1, key2)
    }

    func testCacheKey_ChangesWhenThemeChanges() {
        // Given
        let key1 = cache.cacheKey(path: testPath, modDate: testDate, theme: "xcodeDark", language: testLanguage)
        let key2 = cache.cacheKey(path: testPath, modDate: testDate, theme: "github", language: testLanguage)

        // Then
        XCTAssertNotEqual(key1, key2)
    }

    func testCacheKey_ChangesWhenLanguageChanges() {
        // Given
        let key1 = cache.cacheKey(path: testPath, modDate: testDate, theme: testTheme, language: "swift")
        let key2 = cache.cacheKey(path: testPath, modDate: testDate, theme: testTheme, language: "javascript")

        // Then
        XCTAssertNotEqual(key1, key2)
    }

    func testCacheKey_IsDeterministic() {
        // Given
        let key1 = cache.cacheKey(path: testPath, modDate: testDate, theme: testTheme, language: testLanguage)
        let key2 = cache.cacheKey(path: testPath, modDate: testDate, theme: testTheme, language: testLanguage)

        // Then
        XCTAssertEqual(key1, key2)
    }

    func testCacheKey_IsSHA256Length() {
        // Given
        let key = cache.cacheKey(path: testPath, modDate: testDate, theme: testTheme, language: testLanguage)

        // Then
        XCTAssertEqual(key.count, 64, "SHA256 hash should be 64 hex characters")
    }

    // MARK: - Thread Safety Tests

    func testConcurrentReads_ThreadSafe() {
        // Given
        let highlighted = AttributedString("test code")
        cache.set(path: testPath, modDate: testDate, theme: testTheme, language: testLanguage, highlighted: highlighted)

        // When: Concurrent reads from multiple threads
        let expectation = XCTestExpectation(description: "Concurrent reads complete")
        expectation.expectedFulfillmentCount = 100

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            let result = cache.get(path: testPath, modDate: testDate, theme: testTheme, language: testLanguage)
            XCTAssertNotNil(result)
            expectation.fulfill()
        }

        // Then: No crashes, all reads succeed
        wait(for: [expectation], timeout: 5.0)
    }

    func testConcurrentWrites_ThreadSafe() {
        // When: Concurrent writes from multiple threads
        let expectation = XCTestExpectation(description: "Concurrent writes complete")
        expectation.expectedFulfillmentCount = 100

        DispatchQueue.concurrentPerform(iterations: 100) { i in
            let path = "/path/file\(i).swift"
            cache.set(path: path, modDate: testDate, theme: testTheme, language: testLanguage, highlighted: AttributedString("code \(i)"))
            expectation.fulfill()
        }

        // Then: No crashes, all writes succeed
        wait(for: [expectation], timeout: 5.0)
    }
}
```

---

## Appendix C: CI/CD Workflow Example

### .github/workflows/tests.yml

```yaml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  unit-tests:
    name: Unit Tests
    runs-on: macos-14

    steps:
    - uses: actions/checkout@v4

    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.2.app

    - name: Run Unit Tests
      run: |
        xcodebuild test \
          -project dotViewer.xcodeproj \
          -scheme dotViewer \
          -destination 'platform=macOS' \
          -testPlan UnitTests \
          -enableCodeCoverage YES \
          -resultBundlePath TestResults

    - name: Generate Coverage Report
      run: |
        xcrun llvm-cov report \
          -instr-profile=$(find TestResults -name '*.profdata') \
          $(find TestResults -name 'dotViewer') \
          > coverage.txt
        cat coverage.txt

    - name: Check Coverage Threshold
      run: |
        COVERAGE=$(xcrun llvm-cov report \
          -instr-profile=$(find TestResults -name '*.profdata') \
          $(find TestResults -name 'dotViewer') | \
          grep "TOTAL" | awk '{print $NF}' | sed 's/%//')
        echo "Code coverage: $COVERAGE%"
        if (( $(echo "$COVERAGE < 85.0" | bc -l) )); then
          echo "Error: Coverage $COVERAGE% is below threshold 85%"
          exit 1
        fi

    - name: Upload Coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        files: coverage.txt
        fail_ci_if_error: true

  integration-tests:
    name: Integration Tests
    runs-on: macos-14

    steps:
    - uses: actions/checkout@v4

    - name: Run Integration Tests
      run: |
        xcodebuild test \
          -project dotViewer.xcodeproj \
          -scheme dotViewer \
          -destination 'platform=macOS' \
          -testPlan IntegrationTests

  e2e-tests:
    name: E2E Tests
    runs-on: macos-14

    steps:
    - uses: actions/checkout@v4

    - name: Build App
      run: |
        xcodebuild build \
          -project dotViewer.xcodeproj \
          -scheme dotViewer \
          -configuration Release \
          -derivedDataPath build

    - name: Install App
      run: |
        rm -rf /Applications/dotViewer.app
        cp -R build/Build/Products/Release/dotViewer.app /Applications/
        qlmanage -r

    - name: Run E2E Tests
      run: |
        xcodebuild test \
          -project dotViewer.xcodeproj \
          -scheme dotViewer \
          -destination 'platform=macOS' \
          -testPlan E2ETests
```

---

## Conclusion

The dotViewer project currently has **ZERO automated test coverage**, representing a **CRITICAL** risk for:
- Regression prevention during refactoring (God Class: 1471 lines)
- Security finding validation (11 findings untested)
- Performance requirement enforcement (cache, highlighting)
- Integration correctness (cache coordination, theme switching)

**Recommended Investment:** 185 hours over 8 weeks to achieve 85% code coverage with 174 automated tests.

**Immediate Priority:** Implement 39 critical path tests (40 hours) to establish a safety net before architectural refactoring.

**Long-Term Goal:** Shift to TDD methodology with pre-commit hooks, coverage gates, and continuous quality monitoring.

---

**Report Generated:** 2026-01-22
**Next Steps:** Review with development team, prioritize test implementation roadmap, allocate resources for Phase 3 execution.
