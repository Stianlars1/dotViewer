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
    private var queryIsSelected = false
    /// Insertion point within `query`, as a Character offset. The page has no editable field — the
    /// query is a span — so the caret lives here and is sent along with the text.
    private var caret = 0
    /// Whether this tap put a selection into the preview with ⌘A. Gates ⌘C so that copying a file
    /// in Finder keeps working whenever the user has not asked for the contents.
    private var previewSelectionActive = false

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
        // Remembered so a later launch can tell "never granted" from "granted, then invalidated by
        // a signature change" — the one case where the Grant button cannot help.
        SharedSettings.shared.accessibilityGrantSeen = true
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

        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        let command = flags.contains(.maskCommand)
        let shift = flags.contains(.maskShift)
        let option = flags.contains(.maskAlternate)
        let optionOrControl = option || flags.contains(.maskControl)

        // ⌥Space opens dotViewer's own preview panel. Space itself is deliberately untouched, so
        // native Quick Look keeps handling every file it already handles.
        //
        // Checked before the subscriber guard below because it has to work with no Quick Look
        // preview open — that is the whole point of the panel.
        if option, !command, keyCode == kVK_Space,
           SharedSettings.shared.previewPanelEnabled,
           FinderSelection.isFinderFrontmost {
            // The tap callback must return quickly or the system disables it, so the AppleScript
            // round-trip and the window work both happen off the callback.
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    PreviewPanelController.shared.openForFinderSelection()
                }
            }
            return nil  // swallow, so Finder never sees ⌥Space
        }

        // While dotViewer's own panel is frontmost it handles its own keys. Without this the tap
        // would swallow them on the way to the panel whenever a Quick Look preview is also open.
        if NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Bundle.main.bundleIdentifier {
            return Unmanaged.passUnretained(event)
        }

        // No open dotViewer preview means nothing to type into — stay out of the way entirely.
        guard SearchBridgeServer.shared.subscriberCount > 0 else {
            endSearch(broadcast: false)
            setPreviewSelection(false)
            return Unmanaged.passUnretained(event)
        }

        // Gated on the setting because with the search bar switched off the page has no search UI
        // to drive. Entering search mode anyway would swallow every subsequent keystroke with
        // nothing on screen to show for it.
        if command, keyCode == kVK_ANSI_F, SharedSettings.shared.showSearchButton {
            beginSearch()
            return nil  // swallow, so Finder's Find window never opens
        }

        // ⌘A and ⌘C over the previewed file. Finder otherwise claims both: ⌘A selects every file in
        // the window and ⌘C copies the file itself, when the person is plainly looking at its
        // contents. Only while not searching — there ⌘A means the query text instead.
        if command, !optionOrControl, !isSearching, keyCode == kVK_ANSI_A {
            SearchBridgeServer.shared.broadcast(kind: "selectallcontent")
            setPreviewSelection(true)
            return nil
        }

        // Deliberately conditional on a selection this tap actually made. Without that, ⌘C would be
        // swallowed whenever a preview is open and copying the file in Finder would silently stop
        // working — a worse regression than the feature is worth.
        if command, !optionOrControl, !isSearching, keyCode == kVK_ANSI_C, hasPreviewSelection {
            SearchBridgeServer.shared.broadcast(kind: "copyselection")
            return nil
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
                insertIntoQuery(pasted)
            }
            return nil

        case kVK_ANSI_A where command:
            // Without this ⌘A falls through to Finder and selects every file in the window while
            // the user believes they are selecting the search text.
            selectAll()
            return nil

        case kVK_Delete:
            deleteBackward()
            return nil

        case kVK_ForwardDelete:
            deleteForward()
            return nil

        // Arrows move the insertion point. They must be handled explicitly: they arrive as
        // characters in the Unicode Private Use Area, so without a case here they fall through to
        // the text path below and get appended as invisible padding.
        case kVK_LeftArrow:
            moveCaret(.left, by: command ? .line : (option ? .word : .character))
            return nil

        case kVK_RightArrow:
            moveCaret(.right, by: command ? .line : (option ? .word : .character))
            return nil

        case kVK_UpArrow, kVK_Home:
            moveCaret(.left, by: .line)
            return nil

        case kVK_DownArrow, kVK_End:
            moveCaret(.right, by: .line)
            return nil

        default:
            break
        }

        // Leave every other command chord alone — Cmd+W, Cmd+Tab, screenshots and so on.
        if command || optionOrControl { return Unmanaged.passUnretained(event) }

        guard let characters = NSEvent(cgEvent: event)?.characters,
              !characters.isEmpty,
              characters.unicodeScalars.allSatisfy(Self.isInsertable)
        else {
            return Unmanaged.passUnretained(event)
        }

        insertIntoQuery(characters)
        return nil  // swallow: stops type-select, and avoids double entry via WebKit's own insertion
    }

    private var isSearching: Bool {
        lock.lock(); defer { lock.unlock() }
        return searchActive
    }

    private var hasPreviewSelection: Bool {
        lock.lock(); defer { lock.unlock() }
        return previewSelectionActive
    }

    private func setPreviewSelection(_ active: Bool) {
        lock.lock(); defer { lock.unlock() }
        previewSelectionActive = active
    }

    private func beginSearch() {
        lock.lock()
        searchActive = true
        query = ""
        caret = 0
        queryIsSelected = false
        lock.unlock()
        SearchBridgeServer.shared.broadcast(kind: "open")
    }

    private func endSearch(broadcast: Bool) {
        lock.lock()
        let wasActive = searchActive
        searchActive = false
        query = ""
        caret = 0
        queryIsSelected = false
        lock.unlock()
        if broadcast, wasActive {
            SearchBridgeServer.shared.broadcast(kind: "close")
        }
    }

    /// Marks the whole query as selected, mirroring what ⌘A does in a real text field: the next
    /// character replaces everything, and delete clears it.
    private func selectAll() {
        lock.lock()
        let isEmpty = query.isEmpty
        queryIsSelected = !isEmpty
        lock.unlock()
        guard !isEmpty else { return }
        SearchBridgeServer.shared.broadcast(kind: "selectall")
    }

    /// Characters the search field will accept.
    ///
    /// Arrow keys, Home/End, page keys and the function row do not arrive as control characters —
    /// AppKit maps them into the Unicode Private Use Area (U+F700–U+F8FF). A control-character
    /// check alone lets them through, and they are then appended as invisible text that pads the
    /// query and matches nothing.
    private static func isInsertable(_ scalar: Unicode.Scalar) -> Bool {
        if CharacterSet.controlCharacters.contains(scalar) { return false }
        if (0xF700...0xF8FF).contains(scalar.value) { return false }
        return true
    }

    private enum CaretDirection { case left, right }
    private enum CaretGranularity { case character, word, line }

    private func insertIntoQuery(_ text: String) {
        lock.lock()
        if queryIsSelected {
            // Typing over a selection replaces it, as it would in an NSTextField.
            query = text
            caret = text.count
            queryIsSelected = false
        } else {
            let position = min(max(caret, 0), query.count)
            query.insert(contentsOf: text, at: query.index(query.startIndex, offsetBy: position))
            caret = position + text.count
        }
        let current = query
        let position = caret
        lock.unlock()
        SearchBridgeServer.shared.broadcast(kind: "query", value: current, caret: position)
    }

    private func deleteBackward() {
        lock.lock()
        if queryIsSelected {
            query = ""
            caret = 0
            queryIsSelected = false
        } else if caret > 0, !query.isEmpty {
            let position = min(caret, query.count)
            query.remove(at: query.index(query.startIndex, offsetBy: position - 1))
            caret = position - 1
        }
        let current = query
        let position = caret
        lock.unlock()
        SearchBridgeServer.shared.broadcast(kind: "query", value: current, caret: position)
    }

    private func deleteForward() {
        lock.lock()
        if queryIsSelected {
            query = ""
            caret = 0
            queryIsSelected = false
        } else if caret < query.count {
            query.remove(at: query.index(query.startIndex, offsetBy: caret))
        }
        let current = query
        let position = caret
        lock.unlock()
        SearchBridgeServer.shared.broadcast(kind: "query", value: current, caret: position)
    }

    private func moveCaret(_ direction: CaretDirection, by granularity: CaretGranularity) {
        lock.lock()
        let characters = Array(query)
        if queryIsSelected {
            // Collapsing a selection puts the caret at the matching edge, the way a text field does.
            queryIsSelected = false
            caret = direction == .left ? 0 : characters.count
        } else {
            switch (direction, granularity) {
            case (.left, .character): caret = max(0, caret - 1)
            case (.right, .character): caret = min(characters.count, caret + 1)
            case (.left, .word): caret = Self.wordBoundaryBefore(caret, in: characters)
            case (.right, .word): caret = Self.wordBoundaryAfter(caret, in: characters)
            case (.left, .line): caret = 0
            case (.right, .line): caret = characters.count
            }
        }
        let current = query
        let position = caret
        lock.unlock()
        // A distinct kind: moving the insertion point must not re-run the search and re-scroll the
        // document to the first match.
        SearchBridgeServer.shared.broadcast(kind: "caret", value: current, caret: position)
    }

    private static func wordBoundaryBefore(_ index: Int, in characters: [Character]) -> Int {
        var i = min(max(index, 0), characters.count)
        while i > 0, characters[i - 1].isWhitespace { i -= 1 }
        while i > 0, !characters[i - 1].isWhitespace { i -= 1 }
        return i
    }

    private static func wordBoundaryAfter(_ index: Int, in characters: [Character]) -> Int {
        var i = min(max(index, 0), characters.count)
        while i < characters.count, characters[i].isWhitespace { i += 1 }
        while i < characters.count, !characters[i].isWhitespace { i += 1 }
        return i
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
