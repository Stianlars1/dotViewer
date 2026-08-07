import AppKit
import Carbon.HIToolbox
import Shared
import os.log

private let interceptLogger = Logger(subsystem: "com.stianlars1.dotViewer", category: "SearchKeys")

/// Captures `Cmd+F` and the typing that follows while a dotViewer Quick Look preview is open, and
/// forwards it to the preview over the loopback bridge.
///
/// Why an event tap is unavoidable: a Quick Look preview cannot be typed into. Character keys are
/// claimed by Finder's type-select — which *moves the selection and swaps the previewed file*, so
/// the preview does not merely miss the keystroke, it disappears. `Cmd+F` is claimed by Finder's own
/// Find menu item. Neither can be intercepted from inside the extension; every in-process route is
/// measured and closed in docs/research/quicklook-search-keyboard-2026-08.md.
///
/// Keys are **swallowed**, never passed through. Two reasons: it suppresses type-select, and WebKit's
/// text-insertion path already delivers characters to the focused field on its own — passing them
/// through would type everything twice.
///
/// Privacy posture: the tap is installed only while at least one preview is subscribed, only
/// forwards keys after an explicit `Cmd+F`, and drops out of search mode as soon as the preview
/// closes. It never records or persists anything.
public final class SearchKeyInterceptor: @unchecked Sendable {
    public static let shared = SearchKeyInterceptor()

    private let lock = NSLock()
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var searchActive = false
    private var query = ""
    private var activationObserver: NSObjectProtocol?

    private init() {}

    public var isRunning: Bool {
        lock.lock(); defer { lock.unlock() }
        return tap != nil
    }

    /// Whether the process holds Accessibility permission. Pass `prompt: true` to show the system
    /// dialog — only in response to the user turning the feature on, never at launch.
    public static func hasAccessibility(prompt: Bool = false) -> Bool {
        // The literal rather than kAXTrustedCheckOptionPrompt: the SDK exposes that constant as a
        // global var, which Swift 6 rejects as shared mutable state. The value is stable API.
        let options = ["AXTrustedCheckOptionPrompt": prompt]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    @discardableResult
    public func start() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard tap == nil else { return true }

        guard Self.hasAccessibility() else {
            interceptLogger.info("Accessibility not granted — search keys not intercepted")
            return false
        }

        let mask = (1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,          // must be able to swallow, so not .listenOnly
            eventsOfInterest: CGEventMask(mask),
            callback: searchKeyTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            interceptLogger.error("Could not create event tap")
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        self.tap = tap
        self.runLoopSource = source
        observeApplicationSwitches()
        interceptLogger.info("Search key interception active")
        return true
    }

    /// Search mode must not outlive the preview's frontmost app. Without this, pressing ⌘F and then
    /// switching to another app would leave the tap swallowing that app's keystrokes — a usability
    /// trap and completely unacceptable behaviour for a process holding Accessibility.
    private func observeApplicationSwitches() {
        guard activationObserver == nil else { return }
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.endSearch(broadcast: true)
        }
    }

    public func stop() {
        lock.lock()
        defer { lock.unlock() }
        guard let tap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        self.tap = nil
        self.runLoopSource = nil
        searchActive = false
        query = ""
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
            self.activationObserver = nil
        }
        interceptLogger.info("Search key interception stopped")
    }

    // MARK: - Event handling

    fileprivate func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // The system disables a tap that takes too long. Re-arm rather than silently going deaf.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }

        // No open dotViewer preview means nothing to type into — stay out of the way entirely.
        guard SearchBridgeServer.shared.subscriberCount > 0 else {
            endSearch(broadcast: false)
            return Unmanaged.passUnretained(event)
        }

        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        let command = flags.contains(.maskCommand)
        let shift = flags.contains(.maskShift)
        let optionOrControl = flags.contains(.maskAlternate) || flags.contains(.maskControl)

        if command, keyCode == kVK_ANSI_F {
            beginSearch()
            return nil  // swallow, so Finder's Find window never opens
        }

        guard isSearching else { return Unmanaged.passUnretained(event) }

        switch keyCode {
        case kVK_Escape:
            endSearch(broadcast: true)
            return nil

        case kVK_Return, kVK_ANSI_KeypadEnter:
            SearchBridgeServer.shared.broadcast(kind: shift ? "prev" : "next")
            return nil

        case kVK_ANSI_G where command:
            SearchBridgeServer.shared.broadcast(kind: shift ? "prev" : "next")
            return nil

        case kVK_ANSI_V where command:
            // Read the pasteboard directly — the page's own clipboard read would make WebKit show
            // its "Paste" confirmation button, which is exactly the friction we are removing.
            if let pasted = NSPasteboard.general.string(forType: .string) {
                appendToQuery(pasted)
            }
            return nil

        case kVK_Delete, kVK_ForwardDelete:
            dropLastFromQuery()
            return nil

        default:
            break
        }

        // Leave every other command chord alone — Cmd+W, Cmd+Tab, screenshots and so on.
        if command || optionOrControl { return Unmanaged.passUnretained(event) }

        guard let characters = NSEvent(cgEvent: event)?.characters,
              !characters.isEmpty,
              characters.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) })
        else {
            return Unmanaged.passUnretained(event)
        }

        appendToQuery(characters)
        return nil  // swallow: stops type-select, and avoids double entry via WebKit's own insertion
    }

    private var isSearching: Bool {
        lock.lock(); defer { lock.unlock() }
        return searchActive
    }

    private func beginSearch() {
        lock.lock()
        searchActive = true
        query = ""
        lock.unlock()
        SearchBridgeServer.shared.broadcast(kind: "open")
    }

    private func endSearch(broadcast: Bool) {
        lock.lock()
        let wasActive = searchActive
        searchActive = false
        query = ""
        lock.unlock()
        if broadcast, wasActive {
            SearchBridgeServer.shared.broadcast(kind: "close")
        }
    }

    private func appendToQuery(_ text: String) {
        lock.lock()
        query += text
        let current = query
        lock.unlock()
        SearchBridgeServer.shared.broadcast(kind: "query", value: current)
    }

    private func dropLastFromQuery() {
        lock.lock()
        if !query.isEmpty { query.removeLast() }
        let current = query
        lock.unlock()
        SearchBridgeServer.shared.broadcast(kind: "query", value: current)
    }
}

private func searchKeyTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let interceptor = Unmanaged<SearchKeyInterceptor>.fromOpaque(userInfo).takeUnretainedValue()
    return interceptor.handle(type: type, event: event)
}
