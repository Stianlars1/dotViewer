import Foundation
import ApplicationServices

// MARK: - CopyHelper Entry Point
// Unsandboxed command-line tool that intercepts Cmd+C in Quick Look windows
// and copies selected text via the Accessibility API.

func parseParentPID() -> pid_t? {
    let args = CommandLine.arguments
    guard let idx = args.firstIndex(of: "--parent-pid"),
          idx + 1 < args.count,
          let pid = Int32(args[idx + 1])
    else { return nil }
    return pid
}

// Check Accessibility permission
guard AXIsProcessTrusted() else {
    fputs("ERROR:accessibility_not_trusted\n", stderr)
    exit(1)
}

guard let parentPID = parseParentPID() else {
    fputs("ERROR:missing_parent_pid\n", stderr)
    fputs("Usage: CopyHelper --parent-pid <pid>\n", stderr)
    exit(3)
}

let monitor = KeyboardMonitor()
guard monitor.start() else {
    fputs("ERROR:tap_create_failed\n", stderr)
    exit(2)
}

// Watch for parent process death → auto-terminate
let source = DispatchSource.makeProcessSource(
    identifier: parentPID,
    eventMask: .exit,
    queue: .main
)
source.setEventHandler {
    exit(0)
}
source.resume()

fputs("OK:running\n", stdout)
fflush(stdout)

CFRunLoopRun()
