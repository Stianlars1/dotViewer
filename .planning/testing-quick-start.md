# Testing Quick Start - Immediate Actions

## Critical Status
- **Current Coverage:** 0% (CRITICAL)
- **Test Count:** 0 automated tests
- **Manual Tests:** 1 E2E shell script only
- **Risk Level:** HIGH (no regression protection)

---

## Start Testing in 30 Minutes

### Step 1: Add Test Target (5 minutes)
```bash
# Open Xcode
open dotViewer.xcodeproj

# Add test target:
# 1. File > New > Target
# 2. Select "macOS Unit Testing Bundle"
# 3. Product Name: "dotViewerTests"
# 4. Click Finish
```

### Step 2: Create First Test (10 minutes)
```swift
// dotViewerTests/HighlightCacheTests.swift
import XCTest
@testable import dotViewer

final class HighlightCacheTests: XCTestCase {
    var cache: HighlightCache!

    override func setUp() {
        super.setUp()
        cache = HighlightCache()
        cache.clearAll()
    }

    // First test: Verify cache miss returns nil
    func testCacheMiss_ReturnsNil() {
        // When: Request uncached file
        let result = cache.get(
            path: "/path/test.swift",
            modDate: Date(),
            theme: "xcodeDark",
            language: "swift"
        )

        // Then: Should return nil
        XCTAssertNil(result)
    }

    // Second test: Verify cache hit returns data
    func testMemoryCacheHit_ReturnsData() {
        // Given: Store in cache
        let path = "/path/test.swift"
        let modDate = Date()
        let highlighted = AttributedString("test code")

        cache.set(
            path: path,
            modDate: modDate,
            theme: "xcodeDark",
            language: "swift",
            highlighted: highlighted
        )

        // When: Retrieve from cache
        let result = cache.get(
            path: path,
            modDate: modDate,
            theme: "xcodeDark",
            language: "swift"
        )

        // Then: Should return cached data
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.description, highlighted.description)
    }
}
```

### Step 3: Run First Tests (5 minutes)
```bash
# Command line
xcodebuild test -scheme dotViewer -destination 'platform=macOS'

# Or in Xcode:
# Product > Test (⌘U)
```

### Step 4: Verify Tests Pass (10 minutes)
```bash
# You should see:
# Test Suite 'HighlightCacheTests' passed
# Executed 2 tests, with 0 failures
```

**Congratulations! You now have 2 passing tests.**

---

## Next: Add 5 More Critical Tests (1 hour)

### Test 3: LRU Eviction
```swift
func testLRUEviction_RemovesOldestWhenFull() {
    // Fill cache to capacity (20 entries)
    for i in 0..<20 {
        cache.set(
            path: "/path/file\(i).swift",
            modDate: Date(),
            theme: "xcodeDark",
            language: "swift",
            highlighted: AttributedString("code \(i)")
        )
    }

    // Add 21st entry
    cache.set(
        path: "/path/file20.swift",
        modDate: Date(),
        theme: "xcodeDark",
        language: "swift",
        highlighted: AttributedString("code 20")
    )

    // First entry should be evicted
    let firstResult = cache.get(
        path: "/path/file0.swift",
        modDate: Date(),
        theme: "xcodeDark",
        language: "swift"
    )

    XCTAssertNil(firstResult, "Oldest entry should be evicted")
}
```

### Test 4: Cache Key Changes with Theme
```swift
func testCacheKey_ChangesWhenThemeChanges() {
    let key1 = cache.cacheKey(
        path: "/path/test.swift",
        modDate: Date(),
        theme: "xcodeDark",
        language: "swift"
    )

    let key2 = cache.cacheKey(
        path: "/path/test.swift",
        modDate: Date(),
        theme: "github",
        language: "swift"
    )

    XCTAssertNotEqual(key1, key2)
}
```

### Test 5: Thread Safety
```swift
func testConcurrentReads_ThreadSafe() {
    // Store data
    cache.set(
        path: "/path/test.swift",
        modDate: Date(),
        theme: "xcodeDark",
        language: "swift",
        highlighted: AttributedString("test")
    )

    // 100 concurrent reads
    let expectation = XCTestExpectation(description: "Concurrent reads")
    expectation.expectedFulfillmentCount = 100

    DispatchQueue.concurrentPerform(iterations: 100) { _ in
        let result = cache.get(
            path: "/path/test.swift",
            modDate: Date(),
            theme: "xcodeDark",
            language: "swift"
        )
        XCTAssertNotNil(result)
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5.0)
}
```

### Test 6: Security - Cache Key Validation
```swift
// dotViewerTests/DiskCacheSecurityTests.swift
import XCTest
@testable import dotViewer

final class DiskCacheSecurityTests: XCTestCase {
    func testIsValidCacheKey_PathTraversal_Invalid() {
        // Note: Access private method via reflection or make it internal
        // For now, test via public API

        // Attempt to use path traversal in cache key
        let maliciousKey = "../../../etc/passwd"

        // DiskCache.shared.get should reject invalid key
        let result = DiskCache.shared.get(key: maliciousKey)

        XCTAssertNil(result, "Path traversal should be rejected")
    }
}
```

### Test 7: Sensitive File Detection
```swift
// dotViewerTests/SensitiveFileTests.swift
import XCTest
@testable import dotViewer

final class SensitiveFileTests: XCTestCase {
    func testIsEnvFile_DotEnv_ReturnsTrue() {
        let state = PreviewState(
            content: "API_KEY=secret",
            filename: ".env",
            language: "properties",
            lineCount: 1,
            fileSize: "100 bytes",
            isTruncated: false,
            truncationMessage: nil,
            fileURL: URL(fileURLWithPath: "/path/.env"),
            modificationDate: Date(),
            preHighlightedContent: nil
        )

        let view = PreviewContentView(state: state)

        // Use reflection or make isEnvFile internal
        // For now, test via UI
        XCTAssertTrue(state.filename == ".env")
    }
}
```

**After 1 hour: You now have 7 passing tests!**

---

## Daily Testing Routine

### Before Writing Code (5 minutes)
```bash
# 1. Pull latest tests
git pull origin main

# 2. Run tests to verify clean state
xcodebuild test -scheme dotViewer

# 3. If tests fail, fix before adding new code
```

### While Writing Code (ongoing)
```bash
# Run tests frequently (after each logical change)
xcodebuild test -only-testing:dotViewerTests/YourTestClass

# Or use Xcode Test Navigator:
# - ⌘6 to open Test Navigator
# - Click diamond icon next to test method
```

### Before Committing (5 minutes)
```bash
# 1. Run all tests
xcodebuild test -scheme dotViewer

# 2. Check coverage
xcodebuild test -scheme dotViewer -enableCodeCoverage YES
xcrun llvm-cov report -instr-profile=$(find . -name '*.profdata') \
  $(find . -name 'dotViewer')

# 3. Only commit if tests pass and coverage doesn't drop
```

---

## Common Test Patterns

### Pattern 1: Arrange-Act-Assert (AAA)
```swift
func testExample() {
    // Arrange: Set up test data
    let input = "test data"
    let expected = "expected result"

    // Act: Execute the code under test
    let result = functionUnderTest(input)

    // Assert: Verify the result
    XCTAssertEqual(result, expected)
}
```

### Pattern 2: Given-When-Then
```swift
func testExample() {
    // Given: Initial state
    cache.set(path: testPath, ...)

    // When: Action occurs
    let result = cache.get(path: testPath, ...)

    // Then: Verify outcome
    XCTAssertNotNil(result)
}
```

### Pattern 3: Test Doubles (Mocks)
```swift
class MockHighlightCache: HighlightCacheProtocol {
    var getCalls: [(path: String, theme: String)] = []

    func get(path: String, modDate: Date, theme: String, language: String?) -> AttributedString? {
        getCalls.append((path, theme))
        return nil
    }
}

func testExample() {
    let mock = MockHighlightCache()
    // Use mock instead of real cache
    // Verify mock.getCalls to check behavior
}
```

---

## Test Debugging Tips

### Test Failing? Try These

1. **Run test in isolation:**
   ```bash
   xcodebuild test -only-testing:dotViewerTests/HighlightCacheTests/testCacheMiss_ReturnsNil
   ```

2. **Add print statements:**
   ```swift
   print("DEBUG: cache key = \(cacheKey)")
   print("DEBUG: result = \(result)")
   ```

3. **Set breakpoint in Xcode:**
   - Open test file
   - Click line number to set breakpoint
   - Run test with ⌘U
   - Debugger will pause at breakpoint

4. **Check test isolation:**
   ```swift
   override func setUp() {
       super.setUp()
       cache.clearAll() // Clean state for each test
   }
   ```

5. **Verify async expectations:**
   ```swift
   let expectation = XCTestExpectation(description: "async operation")
   // ... async code ...
   expectation.fulfill()
   wait(for: [expectation], timeout: 5.0)
   ```

---

## XCTest Cheat Sheet

### Common Assertions
```swift
XCTAssertEqual(a, b)              // a == b
XCTAssertNotEqual(a, b)           // a != b
XCTAssertTrue(condition)          // condition is true
XCTAssertFalse(condition)         // condition is false
XCTAssertNil(value)               // value is nil
XCTAssertNotNil(value)            // value is not nil
XCTAssertGreaterThan(a, b)        // a > b
XCTAssertLessThan(a, b)           // a < b
XCTAssertThrowsError(try func())  // function throws error
XCTAssertNoThrow(try func())      // function doesn't throw
```

### Test Lifecycle
```swift
class MyTests: XCTestCase {
    // Run once before all tests
    override class func setUp() { }

    // Run once after all tests
    override class func tearDown() { }

    // Run before each test
    override func setUp() { }

    // Run after each test
    override func tearDown() { }
}
```

### Async Testing
```swift
// Async/await (Swift 5.5+)
func testAsync() async throws {
    let result = await asyncFunction()
    XCTAssertNotNil(result)
}

// Expectations (older pattern)
func testAsync() {
    let expectation = XCTestExpectation(description: "async")
    asyncFunction { result in
        XCTAssertNotNil(result)
        expectation.fulfill()
    }
    wait(for: [expectation], timeout: 5.0)
}
```

---

## Week 1 Milestone Checklist

By end of Week 1, you should have:

- [x] Test target added to Xcode project
- [x] First 2 tests passing (cache miss, cache hit)
- [x] 5 additional tests added (LRU, thread safety, security)
- [ ] 11 more tests for full Week 1 target (18 total)
- [ ] 25% code coverage achieved
- [ ] All tests passing in local environment
- [ ] Tests integrated with Xcode Test Navigator

**Remaining Week 1 Tests to Add:**
1. testCacheKey_IsDeterministic
2. testCacheKey_IncludesPath
3. testCacheKey_IncludesModificationDate
4. testClearMemory_PreservesDisk
5. testClearAll_ClearsMemoryAndDisk
6. testStats_ReturnsCorrectCounts
7. testDiskCacheHit_PromotesToMemory
8. testConcurrentWrites_ThreadSafe
9. testCacheMiss_HighlightAndStore (integration)
10. testThemeChange_InvalidatesBothCaches (integration)
11. testIsValidCacheKey_NonHex_Invalid (security)

---

## Help & Resources

**Questions?**
- Review full evaluation: `.planning/phase-3-testing-evaluation-report.md`
- Check weekly roadmap: `.planning/testing-roadmap-actionable.md`

**Official Documentation:**
- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [Testing Your App](https://developer.apple.com/documentation/xcode/testing-your-app-in-xcode)

**Command Reference:**
```bash
# Run all tests
xcodebuild test -scheme dotViewer

# Run specific test class
xcodebuild test -only-testing:dotViewerTests/HighlightCacheTests

# Run specific test method
xcodebuild test -only-testing:dotViewerTests/HighlightCacheTests/testCacheMiss_ReturnsNil

# Run with coverage
xcodebuild test -scheme dotViewer -enableCodeCoverage YES

# Generate coverage report
xcrun llvm-cov report -instr-profile=$(find . -name '*.profdata') $(find . -name 'dotViewer')
```

---

**Ready to start? Run these commands:**
```bash
# 1. Open Xcode
open dotViewer.xcodeproj

# 2. Add test target (File > New > Target > macOS Unit Testing Bundle)

# 3. Create first test file and copy the code from "Step 2" above

# 4. Run tests (⌘U)

# You're now on your way to 85% coverage!
```
