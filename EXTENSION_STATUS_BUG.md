# dotViewer - Quick Look Extension Status Detection Bug

## App Overview

**dotViewer** is a macOS Quick Look extension app providing syntax-highlighted previews for source code files and dotfiles when users press Space in Finder.

| Component | Bundle ID |
|-----------|-----------|
| Main App | `com.stianlars1.dotViewer` |
| QL Extension | `com.stianlars1.dotViewer.QuickLookPreview` |
| App Group | `group.com.stianlars1.dotviewer` |

**Architecture:**
- `dotViewerApp.swift` - SwiftUI App entry point with `WindowGroup` + `Settings` scene
- `ContentView.swift` - `NavigationSplitView` containing `StatusView`, `FileTypesView`, `SettingsView`
- `QuickLookPreview.appex` - Bundled Quick Look extension

---

## The Problem

The Status View shows "Extension Not Enabled" (red X) even when the extension **IS enabled** in System Settings.

**Key observations:**
1. Quick Look previews **work correctly** when extension is enabled
2. Terminal command shows correct status: `pluginkit -m -p com.apple.quicklook.preview` returns `+    com.stianlars1.dotViewer.QuickLookPreview(1.0)`
3. Debug file writes to `/tmp/dotviewer_debug.log` produce **no output**
4. User reports app "opens and closes in an irritating way"

---

## What We Know

### Sandbox Status: NOT SANDBOXED ✓

The `dotViewer.entitlements` contains only App Group capability - no sandbox:
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.stianlars1.dotviewer</string>
</array>
```

This rules out sandbox as the cause. `/tmp/` writes and `Process()` execution should work.

### Current Status Check Implementation

```swift
// In StatusView (ContentView.swift:249-346)
private func checkExtensionStatus() {
    isCheckingStatus = true

    DispatchQueue.global(qos: .userInitiated).async {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        task.arguments = ["-m", "-p", "com.apple.quicklook.preview"]
        // ... parse for "+" prefix = enabled
    }
}
```

Status check is triggered by:
1. `onAppear` - Initial load
2. `onChange(of: scenePhase)` - App becomes active
3. `NSApplication.didBecomeActiveNotification` - Backup for scenePhase
4. `Timer.publish(every: 10)` - Polling every 10 seconds

---

## Root Cause Hypotheses

### 1. SwiftUI `@State` in Detail View Problem (MOST LIKELY)

`StatusView` is in the `detail` pane of `NavigationSplitView`:

```swift
NavigationSplitView {
    List(selection: $selectedItem) { ... }  // Sidebar
} detail: {
    switch selectedItem {
    case .status: StatusView()  // ← Created fresh on every selection change
    // ...
    }
}
```

**The issue:** Every time `selectedItem` changes or the view hierarchy updates, SwiftUI may:
1. **Recreate** `StatusView` entirely (new `@State` values)
2. **Not call** `onAppear` if the view was cached
3. **Reset** `isExtensionEnabled` to `false` (the initial value)

**Why debug logs don't appear:** The view is being recreated so rapidly that:
- `init()` file writes overwrite each other
- `onAppear` may not fire between recreations
- The async `checkExtensionStatus()` completes after the view is already replaced

**Evidence:** User reports "opens and closes in an irritating way" - likely rapid view recreation.

### 2. Race Condition in Async Check

```swift
DispatchQueue.global(qos: .userInitiated).async {
    // ... long running pluginkit check
    DispatchQueue.main.async {
        self.isExtensionEnabled = isEnabled  // ← "self" may refer to old view instance
        self.isCheckingStatus = false
    }
}
```

When SwiftUI recreates the view, `self` in the closure captures the **old** view instance. The state update goes to a view that no longer exists.

### 3. Multiple Competing Status Checks

Four different triggers call `checkExtensionStatus()`:
- `onAppear`
- `onChange(of: scenePhase)`
- `didBecomeActiveNotification`
- Timer (every 10 seconds)

These can fire simultaneously, causing:
- Multiple `Process()` instances running
- Race conditions updating `@State`
- UI thrashing

### 4. Timer Causing View Updates

```swift
private let pollTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
```

This timer is a **stored property** that starts immediately. Combined with `onReceive`, it may cause the view body to re-evaluate every 10 seconds even when nothing changed.

---

## Swift/Xcode Debugging Steps

### Step 1: Add Console.app Logging (Works Even If File I/O Fails)

```swift
import os.log

private let logger = Logger(subsystem: "com.stianlars1.dotViewer", category: "StatusView")

struct StatusView: View {
    init() {
        logger.notice("⚡ StatusView.init() called - instance: \(ObjectIdentifier(self).debugDescription)")
    }

    var body: some View {
        let _ = logger.notice("🔄 StatusView.body evaluated")
        // ... existing body
    }

    .onAppear {
        logger.notice("👁 StatusView.onAppear called")
        checkExtensionStatus()
    }
}
```

**View logs:** Open Console.app → Filter: `subsystem:com.stianlars1.dotViewer`

### Step 2: Track View Identity

Add unique ID to see if view is being recreated:

```swift
struct StatusView: View {
    private let viewID = UUID()  // New ID each time view is created

    init() {
        logger.notice("StatusView init - ID: \(viewID)")
    }
}
```

If you see many different IDs in Console, the view is being recreated.

### Step 3: Use StateObject Instead of State

For data that should persist across view recreations:

```swift
// Create a class to hold the status
class ExtensionStatusChecker: ObservableObject {
    @Published var isEnabled = false
    @Published var isChecking = true

    func check() { /* ... */ }
}

struct StatusView: View {
    @StateObject private var checker = ExtensionStatusChecker()  // Survives view recreation
}
```

### Step 4: Verify pluginkit Actually Runs

Add explicit error logging:

```swift
do {
    try task.run()
    logger.notice("✅ pluginkit started, PID: \(task.processIdentifier)")
} catch {
    logger.error("❌ pluginkit failed: \(error.localizedDescription, privacy: .public)")
}

task.waitUntilExit()
logger.notice("pluginkit exited with code: \(task.terminationStatus)")
```

### Step 5: Check for Xcode Build Issues

```bash
# Verify the binary contains your changes
strings /Applications/dotViewer.app/Contents/MacOS/dotViewer | grep "StatusView init"

# Check binary modification time
stat /Applications/dotViewer.app/Contents/MacOS/dotViewer

# Nuclear clean
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/com.apple.dt.Xcode
```

---

## Recommended Fix

### Option A: Use @StateObject for Status Management (Recommended)

```swift
// ExtensionStatusChecker.swift
import SwiftUI
import os.log

@MainActor
class ExtensionStatusChecker: ObservableObject {
    static let shared = ExtensionStatusChecker()  // Singleton - survives view recreation

    @Published var isEnabled = false
    @Published var isChecking = false

    private let logger = Logger(subsystem: "com.stianlars1.dotViewer", category: "StatusChecker")
    private var checkTask: Task<Void, Never>?

    func check() {
        // Cancel any in-progress check
        checkTask?.cancel()

        isChecking = true

        checkTask = Task {
            let enabled = await checkPluginkit()

            // Only update if not cancelled
            if !Task.isCancelled {
                self.isEnabled = enabled
                self.isChecking = false
            }
        }
    }

    private func checkPluginkit() async -> Bool {
        await withCheckedContinuation { continuation in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
            task.arguments = ["-m", "-p", "com.apple.quicklook.preview"]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = FileHandle.nullDevice

            do {
                try task.run()
                task.waitUntilExit()

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                for line in output.components(separatedBy: .newlines) {
                    if line.contains("com.stianlars1.dotViewer.QuickLookPreview") {
                        let enabled = line.trimmingCharacters(in: .whitespaces).hasPrefix("+")
                        logger.info("Extension found: enabled=\(enabled)")
                        continuation.resume(returning: enabled)
                        return
                    }
                }

                logger.warning("Extension not found in pluginkit output")
                continuation.resume(returning: false)
            } catch {
                logger.error("pluginkit error: \(error.localizedDescription)")
                continuation.resume(returning: false)
            }
        }
    }
}

// In StatusView
struct StatusView: View {
    @StateObject private var checker = ExtensionStatusChecker.shared

    var body: some View {
        // Use checker.isEnabled, checker.isChecking
    }
    .onAppear {
        checker.check()
    }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
        checker.check()
    }
    // Remove the timer - it's causing unnecessary updates
}
```

### Option B: Quick Fix - Debounce Status Checks

```swift
private func checkExtensionStatus() {
    // Prevent multiple simultaneous checks
    guard !isCheckingStatus else { return }
    isCheckingStatus = true

    // Add small delay to let view settle
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.performActualCheck()
    }
}
```

### Option C: Remove Timer Polling

The timer may be causing unnecessary view updates. Remove it and rely only on:
- `onAppear`
- App activation notification
- Manual refresh button

---

## Quick Diagnostic Commands

```bash
# Check if pluginkit works from current user context
/usr/bin/pluginkit -m -p com.apple.quicklook.preview

# Watch Console logs in real-time
log stream --predicate 'subsystem == "com.stianlars1.dotViewer"' --style compact

# Check app is actually running
pgrep -fl dotViewer

# Verify app binary is recent
ls -la /Applications/dotViewer.app/Contents/MacOS/
```

---

## Files to Modify

| File | Changes Needed |
|------|----------------|
| `dotViewer/ContentView.swift` | Refactor `StatusView` to use `@StateObject` |
| (new) `dotViewer/ExtensionStatusChecker.swift` | Create shared status manager class |

---

## Summary

**Most likely cause:** SwiftUI is recreating `StatusView` frequently due to `NavigationSplitView` behavior. Each recreation:
1. Resets `@State` to default (`isExtensionEnabled = false`)
2. Starts new async check
3. Old async check completes but updates dead view instance

**Fix:** Use `@StateObject` with a singleton/shared instance that survives view recreation, and remove the aggressive 10-second polling timer.
