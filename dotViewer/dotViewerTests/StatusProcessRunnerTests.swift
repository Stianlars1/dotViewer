import XCTest

final class StatusProcessRunnerTests: XCTestCase {
    func testLargeStdoutAndStderrDoNotDeadlock() async throws {
        let output = try await StatusProcessRunner.run(path: "/bin/sh", arguments: ["-c", "/bin/dd if=/dev/zero bs=1024 count=256 2>/dev/null; /bin/dd if=/dev/zero bs=1024 count=256 1>&2 2>/dev/null"], timeout: 2)
        XCTAssertEqual(output.utf8.count, 262_144)
    }

    func testHungChildIsTerminatedAtDeadline() async {
        let start = Date()
        do {
            _ = try await StatusProcessRunner.run(path: "/bin/sleep", arguments: ["20"], timeout: 0.1)
            XCTFail("Expected timeout")
        } catch { XCTAssertEqual(error as? StatusProcessRunner.Failure, .timedOut) }
        XCTAssertLessThan(Date().timeIntervalSince(start), 2)
    }

    func testNonzeroExitIsNotReportedAsSuccess() async {
        do {
            _ = try await StatusProcessRunner.run(path: "/bin/sh", arguments: ["-c", "echo failure >&2; exit 7"])
            XCTFail("Expected unsuccessful exit")
        } catch { XCTAssertEqual(error as? StatusProcessRunner.Failure, .unsuccessfulExit(7)) }
    }

    func testUnicodeOutputIsPreserved() async throws {
        let output = try await StatusProcessRunner.run(path: "/usr/bin/printf", arguments: ["ÆØÅ ✓"])
        XCTAssertEqual(output, "ÆØÅ ✓")
    }

    func testLaunchFailureReturnsAnError() async {
        do {
            _ = try await StatusProcessRunner.run(path: "/does-not-exist/dotviewer-test", arguments: [])
            XCTFail("Expected launch error")
        } catch { XCTAssertFalse(error is StatusProcessRunner.Failure) }
    }
    func testConcurrentQueriesCompleteIndependently() async throws {
        let lengths = try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    let text = try await StatusProcessRunner.run(path: "/bin/sh", arguments: ["-c", "/bin/dd if=/dev/zero bs=1024 count=32 2>/dev/null"])
                    return text.utf8.count
                }
            }
            var values: [Int] = []
            for try await value in group { values.append(value) }
            return values
        }
        XCTAssertEqual(lengths, Array(repeating: 32_768, count: 8))
    }

}
