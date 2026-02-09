import Foundation
import CoreGraphics
import ApplicationServices

final class KeyboardMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isHandling = false

    func start() -> Bool {
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
            guard let userInfo = userInfo else { return Unmanaged.passRetained(event) }
            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(userInfo).takeUnretainedValue()

            if type == .tapDisabledByTimeout {
                if let tap = monitor.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passRetained(event)
            }

            guard type == .keyDown else {
                return Unmanaged.passRetained(event)
            }

            if let result = monitor.handleKeyDown(event: event) {
                return result
            }
            return Unmanaged.passRetained(event)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: selfPtr
        ) else {
            return false
        }

        self.eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        return true
    }

    private func handleKeyDown(event: CGEvent) -> Unmanaged<CGEvent>? {
        // keyCode 8 = 'C'
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        guard keyCode == 8 else { return nil }

        let flags = event.flags
        // Must have Cmd, must NOT have Ctrl or Option
        guard flags.contains(.maskCommand),
              !flags.contains(.maskControl),
              !flags.contains(.maskAlternate)
        else { return nil }

        // Re-entry guard
        guard !isHandling else { return nil }
        isHandling = true
        defer { isHandling = false }

        // Only act when Quick Look is visible
        guard QuickLookDetector.isQuickLookVisible() else { return nil }

        // Try to copy via Accessibility
        if AccessibilityCopier.copySelectedText() {
            // Swallow the event — we handled it
            return nil
        }

        // Couldn't copy — pass through
        return nil  // still nil: let QL handle it (won't do anything useful, but avoid double-paste)
    }
}
