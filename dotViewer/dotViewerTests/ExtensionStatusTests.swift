import XCTest

final class ExtensionStatusTests: XCTestCase {
    func testEnabledRegistration() async {
        let checker = ExtensionStatusChecker { arguments in
            XCTAssertEqual(arguments, ["-m", "-i", "com.stianlars1.dotViewer.QuickLookPreview"])
            return "+    com.stianlars1.dotViewer.QuickLookPreview(1.5.3)"
        }
        let status = await checker.checkStatus()
        XCTAssertEqual(status, .enabled)
    }

    func testDisabledAndMissingRegistrations() async {
        for output in ["-    com.stianlars1.dotViewer.QuickLookPreview(1.5.3)", ""] {
            let checker = ExtensionStatusChecker { _ in output }
            let status = await checker.checkStatus()
            XCTAssertEqual(status, .disabled)
        }
    }

    func testTimeoutEndsCheckingWithoutFalseGreen() async {
        let checker = ExtensionStatusChecker { _ in throw StatusProcessRunner.Failure.timedOut }
        let status = await checker.checkStatus()
        XCTAssertEqual(status, .error("Status check timed out. Try again."))
    }

    func testFailedCommandEndsCheckingWithoutFalseGreen() async {
        let checker = ExtensionStatusChecker { _ in throw StatusProcessRunner.Failure.unsuccessfulExit(7) }
        let status = await checker.checkStatus()
        XCTAssertEqual(status, .error("Unable to check extension status. Try again."))
    }

    func testFailedConflictScanIsNotAnEmptySuccessfulScan() async {
        let scanner = ExtensionConflictScanner { _, _ in throw StatusProcessRunner.Failure.timedOut }
        do { _ = try await scanner.scanConflicts(); XCTFail("Expected failure") }
        catch { XCTAssertEqual(error as? StatusProcessRunner.Failure, .timedOut) }
    }
    func testSupersededAndUnknownRegistrationsAreNotGreen() async {
        for marker in ["=", "?"] {
            let checker = ExtensionStatusChecker { _ in "\(marker) com.stianlars1.dotViewer.QuickLookPreview(1.5.3)" }
            let status = await checker.checkStatus()
            XCTAssertEqual(status, .error("Extension status could not be confirmed. Try again."))
        }
    }

    func testActiveRegistrationWinsOverSupersededRecord() async {
        let checker = ExtensionStatusChecker { _ in "= com.stianlars1.dotViewer.QuickLookPreview(1.5.3)\n+ com.stianlars1.dotViewer.QuickLookPreview(1.5.4)" }
        let status = await checker.checkStatus()
        XCTAssertEqual(status, .enabled)
    }

    func testResolveReportsMutationFailure() async {
        let scanner = ExtensionConflictScanner { _, arguments in
            if arguments.first == "-mDvvv" { return "+ com.example.preview(1.0)\n Path = /Applications/Example.app" }
            throw StatusProcessRunner.Failure.unsuccessfulExit(7)
        }
        do { _ = try await scanner.resolveAllConflicts(); XCTFail("Expected mutation failure") }
        catch { XCTAssertTrue(error is ExtensionConflictScanner.ResolutionFailure) }
    }

    func testResolveReportsFailedEnableWithNoConflicts() async {
        let scanner = ExtensionConflictScanner { _, arguments in
            if arguments.first == "-mDvvv" { return "" }
            throw StatusProcessRunner.Failure.unsuccessfulExit(7)
        }
        do { _ = try await scanner.resolveAllConflicts(); XCTFail("Expected enable failure") }
        catch { XCTAssertTrue(error is ExtensionConflictScanner.ResolutionFailure) }
    }

}
