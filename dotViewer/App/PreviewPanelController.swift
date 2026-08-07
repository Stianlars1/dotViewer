import AppKit
import Carbon.HIToolbox
import Shared
import WebKit
import os.log

private let panelLogger = Logger(subsystem: "com.stianlars1.dotViewer", category: "PreviewPanel")

/// dotViewer's own preview window, opened with ⌥Space in Finder.
///
/// Why this exists at all: some extensions can never reach the Quick Look extension. `.ts` resolves
/// to `public.mpeg-2-transport-stream`, a system-declared type conforming to `public.movie`, and a
/// third-party extension cannot claim it — measured on macOS 26.4. Space is deliberately left alone
/// so native Quick Look keeps handling everything it already handles; this is a second, additive
/// route that works on any text file rather than only the blocked ones, because a shortcut that
/// silently does nothing on the files a user expects it to handle reads as broken.
///
/// Rendering comes from `PreviewContentBuilder`, the same pipeline the Quick Look extension uses.
@MainActor
final class PreviewPanelController: NSObject {
    static let shared = PreviewPanelController()

    private var panel: NSPanel?
    private var webView: WKWebView?
    private var currentURL: URL?
    private var keyMonitor: Any?
    private var resignObserver: NSObjectProtocol?

    /// Bumped on every show, so a slow render that has been superseded discards its own result.
    private var generation = 0

    // The page's search bar is a `<span>`, not a text field — it was built to be driven from
    // outside (see SearchBridge). The panel drives the same `window.__dvSearch` API, so it owns the
    // query string the way `SearchKeyInterceptor` does for Quick Look.
    private var searchIsOpen = false
    private var searchQuery = ""
    private var searchQueryIsSelected = false

    private override init() { super.init() }

    var isVisible: Bool { panel?.isVisible ?? false }

    // MARK: - Presentation

    /// Entry point for ⌥Space: ask Finder what is selected, then preview it.
    func openForFinderSelection() {
        switch FinderSelection.frontmostSelectedFile() {
        case .success(let url):
            toggle(for: url)

        case .failure(.notPermitted):
            presentAutomationRequest()

        case .failure(let reason):
            // Nothing selected, a folder, a Recents entry with no path — the shortcut simply does
            // not apply. A beep says so without stealing focus for a dialog.
            panelLogger.debug("No Finder selection to preview: \(String(describing: reason), privacy: .public)")
            NSSound.beep()
        }
    }

    /// Asked only when the user actually presses ⌥Space, never at launch: the system remembers a
    /// denial permanently, so the one chance to ask should come with visible context.
    private func presentAutomationRequest() {
        let alert = NSAlert()
        alert.messageText = "dotViewer needs permission to see what is selected in Finder"
        alert.informativeText = """
        ⌥Space previews the file selected in Finder. To find out which file that is, dotViewer has \
        to ask Finder — which macOS treats as controlling another app.

        dotViewer only reads the path of the selected item. It does not change anything in Finder.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Allow…")
        alert.addButton(withTitle: "Open Privacy Settings")
        alert.addButton(withTitle: "Not Now")

        // ⌥Space is pressed while Finder is frontmost, so without this the alert opens behind it.
        NSApp.activate(ignoringOtherApps: true)

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            // Raises the system prompt. If it was already denied this returns without a dialog,
            // which is why the settings route is offered alongside.
            if FinderSelection.automationPermission(prompting: true) == noErr {
                openForFinderSelection()
            }
        case .alertSecondButtonReturn:
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                NSWorkspace.shared.open(url)
            }
        default:
            break
        }
    }

    func toggle(for url: URL) {
        if isVisible, currentURL == url {
            close()
            return
        }
        show(url)
    }

    func show(_ url: URL) {
        generation &+= 1
        let token = generation
        currentURL = url

        Task { @MainActor in
            let systemIsDark = SystemAppearance.isDark()
            let outcome = await PreviewContentBuilder.build(
                for: url,
                systemIsDark: systemIsDark,
                enableSearchBridge: false,
                // "Show Find in Preview" is off by default because in Quick Look the bar is only
                // driveable over the bridge. Here ⌘F is handled natively, so it always applies.
                forceSearchUI: true
            )

            guard token == self.generation else {
                panelLogger.debug("Discarding superseded render for \(url.lastPathComponent, privacy: .public)")
                return
            }

            switch outcome {
            case .systemFallback:
                // Not a text file. Opening an empty window would be worse than doing nothing, and
                // Finder's own preview already handles these.
                panelLogger.log("No panel for \(url.lastPathComponent, privacy: .public) — not a text file")
                NSSound.beep()
                self.currentURL = nil

            case .rendered(let render):
                self.present(render, for: url)
            }
        }
    }

    func close() {
        panel?.orderOut(nil)
        teardown()
    }

    private func present(_ render: PreviewRender, for url: URL) {
        let panel = panel ?? makePanel()
        self.panel = panel

        let webView = webView ?? makeWebView()
        self.webView = webView
        if webView.superview == nil {
            panel.contentView = webView
        }

        panel.title = render.title
        // A file URL base is what lets the page resolve anything relative to the previewed file.
        webView.loadHTMLString(render.html, baseURL: url.deletingLastPathComponent())

        resetSearchState()
        size(panel, for: render)
        installKeyMonitor()
        observeAppDeactivation()

        // Activation is what guarantees the panel receives keys. Finder keeps its selection; the
        // panel closes again as soon as the user clicks back into it.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panelLogger.log("Panel shown for \(url.lastPathComponent, privacy: .public)")
    }

    // MARK: - Window

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 520),
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        // Deliberately not fullSizeContentView: the rendered page draws its own header bar (file
        // type badge, size, copy button) at the very top, which would slide under the titlebar.
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .utilityWindow
        panel.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
        panel.delegate = self
        return panel
    }

    private func makeWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        return webView
    }

    /// Honours the user's configured Quick Look window sizing so the panel does not feel like a
    /// different product, then clamps to the screen the pointer is on.
    private func size(_ panel: NSPanel, for render: PreviewRender) {
        let settings = SharedSettings.shared
        var size = PreviewSizing.initialContentSize(
            lineCount: render.lineCount,
            fontSize: render.fontSize,
            showHeader: render.showHeader,
            windowSizeMode: settings.previewWindowSizeMode,
            fixedWidth: settings.previewWindowFixedWidth,
            fixedHeight: settings.previewWindowFixedHeight,
            lastWidth: settings.previewWindowLastWidth,
            lastHeight: settings.previewWindowLastHeight,
            aspectRatioKey: settings.previewWindowAspectRatio,
            aspectBaseWidth: settings.previewWindowAspectBaseWidth
        )

        let screen = screenForPointer()
        let visible = screen.visibleFrame
        size.width = min(size.width, visible.width * 0.9)
        size.height = min(size.height, visible.height * 0.9)

        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2
        )
        panel.setFrame(
            panel.frameRect(forContentRect: NSRect(origin: origin, size: size)),
            display: true
        )
    }

    private func screenForPointer() -> NSScreen {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }

    private func teardown() {
        currentURL = nil
        resetSearchState()
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
        if let resignObserver {
            NotificationCenter.default.removeObserver(resignObserver)
            self.resignObserver = nil
        }
        // Stop any media/timers the page started, and drop the rendered document.
        webView?.loadHTMLString("", baseURL: nil)
    }

    /// Clicking away dismisses, the way Quick Look does.
    private func observeAppDeactivation() {
        guard resignObserver == nil else { return }
        resignObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.isVisible else { return }
                self.close()
            }
        }
    }

    // MARK: - Keyboard

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            // NSEvent is not Sendable, so only the decision crosses back out of the isolated block.
            // The monitor itself is documented to run on the main thread.
            let consumed = MainActor.assumeIsolated { () -> Bool in
                guard self.isVisible, event.window === self.panel else { return false }
                return self.handle(event)
            }
            return consumed ? nil : event
        }
    }

    /// - Returns: true when the panel consumed the event.
    private func handle(_ event: NSEvent) -> Bool {
        let command = event.modifierFlags.contains(.command)
        let shift = event.modifierFlags.contains(.shift)
        let optionOrControl = event.modifierFlags.contains(.option) || event.modifierFlags.contains(.control)
        let keyCode = Int(event.keyCode)

        if command, keyCode == kVK_ANSI_F {
            openSearch()
            return true
        }

        if command, keyCode == kVK_ANSI_W {
            close()
            return true
        }

        if keyCode == kVK_Escape {
            if searchIsOpen {
                closeSearch()
            } else {
                close()
            }
            return true
        }

        guard searchIsOpen else { return false }

        switch keyCode {
        case kVK_Return, kVK_ANSI_KeypadEnter:
            runSearchJS(shift ? "prev" : "next")
            return true

        case kVK_ANSI_G where command:
            runSearchJS(shift ? "prev" : "next")
            return true

        case kVK_ANSI_V where command:
            if let pasted = NSPasteboard.general.string(forType: .string) {
                appendToQuery(pasted)
            }
            return true

        case kVK_ANSI_A where command:
            selectAllQuery()
            return true

        case kVK_Delete, kVK_ForwardDelete:
            dropLastFromQuery()
            return true

        default:
            break
        }

        // Leave ⌘C, ⌘Q and every other chord to the responder chain.
        if command || optionOrControl { return false }

        guard let characters = event.characters,
              !characters.isEmpty,
              characters.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) })
        else {
            return false
        }

        appendToQuery(characters)
        return true
    }

    // MARK: - Search

    private func resetSearchState() {
        searchIsOpen = false
        searchQuery = ""
        searchQueryIsSelected = false
    }

    private func openSearch() {
        searchIsOpen = true
        searchQuery = ""
        searchQueryIsSelected = false
        runSearchJS("open")
    }

    private func closeSearch() {
        resetSearchState()
        runSearchJS("close")
    }

    private func selectAllQuery() {
        guard !searchQuery.isEmpty else { return }
        searchQueryIsSelected = true
        runSearchJS("setSelected", argument: "true")
    }

    private func appendToQuery(_ text: String) {
        if searchQueryIsSelected {
            searchQuery = text
            searchQueryIsSelected = false
        } else {
            searchQuery += text
        }
        pushQuery()
    }

    private func dropLastFromQuery() {
        if searchQueryIsSelected {
            searchQuery = ""
            searchQueryIsSelected = false
        } else if !searchQuery.isEmpty {
            searchQuery.removeLast()
        }
        pushQuery()
    }

    private func pushQuery() {
        guard let encoded = try? JSONEncoder().encode(searchQuery),
              let literal = String(data: encoded, encoding: .utf8)
        else { return }
        // JSONEncoder produces a correctly escaped JS string literal, so arbitrary typed text
        // cannot break out into executable code.
        evaluate("window.__dvSearch && (window.__dvSearch.open(), window.__dvSearch.query(\(literal)), window.__dvSearch.setSelected(false));")
    }

    private func runSearchJS(_ method: String, argument: String = "") {
        evaluate("window.__dvSearch && window.__dvSearch.\(method)(\(argument));")
    }

    private func evaluate(_ javaScript: String) {
        webView?.evaluateJavaScript(javaScript) { _, error in
            if let error {
                panelLogger.debug("Panel JS failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

// MARK: - NSWindowDelegate

extension PreviewPanelController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        teardown()
    }
}

// MARK: - WKNavigationDelegate

extension PreviewPanelController: WKNavigationDelegate {
    /// Links open in the user's browser rather than replacing the preview. This is the affordance
    /// Quick Look cannot offer — `window.open` is blocked inside quicklookd's web view (KI-012).
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard navigationAction.navigationType == .linkActivated,
              let url = navigationAction.request.url
        else {
            decisionHandler(.allow)
            return
        }

        if url.scheme == "http" || url.scheme == "https" {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }

        // Anything else — file://, custom schemes planted in a document — is not followed. A
        // previewed file is untrusted input; navigating on its say-so is not something to allow.
        decisionHandler(.cancel)
    }
}
