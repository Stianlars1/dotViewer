import AppKit
import ApplicationServices

enum AccessibilityCopier {
    /// Attempt to read selected text from the focused UI element via the Accessibility API,
    /// and write it to the general pasteboard.
    /// Returns `true` if text was successfully copied.
    @discardableResult
    static func copySelectedText() -> Bool {
        let systemWide = AXUIElementCreateSystemWide()

        // Try: system-wide focused element → selected text
        if let text = selectedText(from: systemWide), !text.isEmpty {
            writeToPasteboard(text)
            return true
        }

        // Fallback: focused app → focused UI element → selected text
        var focusedApp: AnyObject?
        guard AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp) == .success,
              let appElement = focusedApp as! AXUIElement?
        else { return false }

        if let text = selectedText(from: appElement), !text.isEmpty {
            writeToPasteboard(text)
            return true
        }

        // Deep fallback: walk focused app's focused window's children
        if let text = deepSearch(from: appElement), !text.isEmpty {
            writeToPasteboard(text)
            return true
        }

        return false
    }

    // MARK: - Private

    private static func selectedText(from element: AXUIElement) -> String? {
        // Get the focused UI element
        var focused: AnyObject?
        let focusResult = AXUIElementCopyAttributeValue(element, kAXFocusedUIElementAttribute as CFString, &focused)

        let target: AXUIElement
        if focusResult == .success, let el = focused as! AXUIElement? {
            target = el
        } else {
            target = element
        }

        // Read selected text
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(target, kAXSelectedTextAttribute as CFString, &value)
        guard result == .success, let text = value as? String else { return nil }
        return text
    }

    private static func deepSearch(from appElement: AXUIElement) -> String? {
        // Try the focused window
        var windowValue: AnyObject?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowValue) == .success,
              let window = windowValue as! AXUIElement?
        else { return nil }

        // Check window itself
        if let text = readSelectedText(from: window), !text.isEmpty {
            return text
        }

        // Check children (1 level deep)
        var childrenValue: AnyObject?
        guard AXUIElementCopyAttributeValue(window, kAXChildrenAttribute as CFString, &childrenValue) == .success,
              let children = childrenValue as? [AXUIElement]
        else { return nil }

        for child in children.prefix(20) {
            if let text = readSelectedText(from: child), !text.isEmpty {
                return text
            }
        }

        return nil
    }

    private static func readSelectedText(from element: AXUIElement) -> String? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &value)
        guard result == .success, let text = value as? String else { return nil }
        return text
    }

    private static func writeToPasteboard(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }
}
