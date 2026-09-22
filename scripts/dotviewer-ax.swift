import AppKit
import ApplicationServices

// Accessibility driver for hands-on checks of the running dotViewer app: reads windows, presses
// controls and menu items, selects sidebar rows, types. No screenshots, so no Screen Recording
// permission and no prompts; the terminal that runs it needs Accessibility.
//
//   swiftc -O scripts/dotviewer-ax.swift -o /tmp/dvax
//   /tmp/dvax menu dotViewer                                   # items and their shortcuts
//   /tmp/dvax press-menu dotViewer "Settings…"
//   /tmp/dvax select-row "*" Appearance                         # "*" = first window
//   /tmp/dvax value-after Appearance AXCheckBox "Wrap long lines"
//   /tmp/dvax tree General 20                                   # roles, labels, values, sizes
//
// Key events are sent only while dotViewer is frontmost, so they can never land in another app.
// AX_BUNDLE=<bundle id> points it at another app.

let bundleID = ProcessInfo.processInfo.environment["AX_BUNDLE"] ?? "com.stianlars1.dotViewer"

func fail(_ message: String) -> Never {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
    exit(1)
}

func attr(_ el: AXUIElement, _ name: String) -> AnyObject? {
    var value: AnyObject?
    return AXUIElementCopyAttributeValue(el, name as CFString, &value) == .success ? value : nil
}

func text(_ el: AXUIElement, _ name: String) -> String? {
    guard let s = attr(el, name) as? String, !s.isEmpty else { return nil }
    return s
}

func kids(_ el: AXUIElement) -> [AXUIElement] {
    (attr(el, kAXChildrenAttribute) as? [AXUIElement]) ?? []
}

func describe(_ el: AXUIElement) -> String {
    var parts = [(text(el, kAXRoleAttribute) ?? "?") + (text(el, kAXSubroleAttribute).map { "/" + $0 } ?? "")]
    if let t = text(el, kAXTitleAttribute) { parts.append("title=\"\(t)\"") }
    if let d = text(el, kAXDescriptionAttribute) { parts.append("desc=\"\(d)\"") }
    if let v = attr(el, kAXValueAttribute) {
        if let s = v as? String, !s.isEmpty { parts.append("value=\"\(s.prefix(90))\"") }
        if let n = v as? NSNumber { parts.append("value=\(n)") }
    }
    if let h = text(el, kAXHelpAttribute) { parts.append("help=\"\(h)\"") }
    if (attr(el, kAXSelectedAttribute) as? Bool) == true { parts.append("SELECTED") }
    if (attr(el, kAXEnabledAttribute) as? Bool) == false { parts.append("DISABLED") }
    if let size = attr(el, kAXSizeAttribute) {
        var s = CGSize.zero
        if AXValueGetValue(size as! AXValue, .cgSize, &s) { parts.append("w=\(Int(s.width)) h=\(Int(s.height))") }
    }
    return parts.joined(separator: " ")
}

func dump(_ el: AXUIElement, _ depth: Int, _ maxDepth: Int) {
    print(String(repeating: "  ", count: depth) + describe(el))
    guard depth < maxDepth else { return }
    for child in kids(el) { dump(child, depth + 1, maxDepth) }
}

func all(_ el: AXUIElement, _ depth: Int = 0, _ out: inout [AXUIElement]) {
    out.append(el)
    guard depth < 60 else { return }
    for child in kids(el) { all(child, depth + 1, &out) }
}

func matches(_ el: AXUIElement, _ needle: String) -> Bool {
    [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute].contains { text(el, $0) == needle }
}

guard let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
    fail("dotViewer is not running")
}
let app = AXUIElementCreateApplication(running.processIdentifier)

func windows() -> [AXUIElement] { (attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? [] }

func window(_ needle: String) -> AXUIElement {
    guard let w = windows().first(where: { needle == "*" || (text($0, kAXTitleAttribute) ?? "").contains(needle) }) else {
        fail("no window matching \(needle); have: \(windows().map { text($0, kAXTitleAttribute) ?? "" })")
    }
    return w
}

func press(_ el: AXUIElement) {
    let err = AXUIElementPerformAction(el, kAXPressAction as CFString)
    if err != .success { fail("AXPress failed (\(err.rawValue)) on \(describe(el))") }
}

func sendKeys(_ events: [(CGKeyCode, CGEventFlags, String?)]) {
    guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleID else {
        fail("refusing to send keys: dotViewer is not frontmost")
    }
    let source = CGEventSource(stateID: .hidSystemState)
    for (code, flags, unicode) in events {
        for down in [true, false] {
            guard let e = CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: down) else { continue }
            e.flags = flags
            if let unicode {
                let chars = Array(unicode.utf16)
                e.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: chars)
            }
            e.post(tap: .cghidEventTap)
            usleep(15_000)
        }
    }
}

let args = Array(CommandLine.arguments.dropFirst())
switch args.first {
case "windows":
    for w in windows() { print(describe(w)) }

case "tree":  // tree <window> [depth]
    dump(window(args[1]), 0, args.count > 2 ? Int(args[2])! : 25)

case "menu":  // menu <top-level title>
    guard let bar = attr(app, kAXMenuBarAttribute) as! AXUIElement?,
          let top = kids(bar).first(where: { text($0, kAXTitleAttribute) == args[1] }) else { fail("no menu \(args[1])") }
    for item in kids(top).first.map(kids) ?? [] {
        let key = text(item, kAXMenuItemCmdCharAttribute) ?? ""
        let mods = (attr(item, kAXMenuItemCmdModifiersAttribute) as? NSNumber)?.intValue ?? -1
        print("\(text(item, kAXTitleAttribute) ?? "—")\t key=\(key) mods=\(mods)")
    }

case "press-menu":  // press-menu <top> <item>
    guard let bar = attr(app, kAXMenuBarAttribute) as! AXUIElement?,
          let top = kids(bar).first(where: { text($0, kAXTitleAttribute) == args[1] }),
          let item = (kids(top).first.map(kids) ?? []).first(where: { text($0, kAXTitleAttribute) == args[2] }) else {
        fail("no menu item \(args[1]) > \(args[2])")
    }
    press(item)

case "press":  // press <window> <role> <text>  — first element with that role whose title/desc/value is text
    var els: [AXUIElement] = []
    all(window(args[1]), 0, &els)
    guard let el = els.first(where: { text($0, kAXRoleAttribute) == args[2] && matches($0, args[3]) }) else {
        fail("no \(args[2]) \"\(args[3])\" in \(args[1])")
    }
    press(el)

case "press-after", "value-after":  // <window> <role> <label> — first <role> after the label, in document order
    var els: [AXUIElement] = []
    all(window(args[1]), 0, &els)
    guard let start = els.firstIndex(where: { text($0, kAXRoleAttribute) == "AXStaticText" && text($0, kAXValueAttribute) == args[3] }),
          let control = els[start...].first(where: { text($0, kAXRoleAttribute) == args[2] }) else {
        fail("no \(args[2]) after \"\(args[3])\"")
    }
    if args[0] == "press-after" { press(control) }
    print(describe(control))

case "choose":  // choose <window> <label> <menu item> — pick from the pop-up button after a label
    var els: [AXUIElement] = []
    all(window(args[1]), 0, &els)
    guard let start = els.firstIndex(where: { text($0, kAXRoleAttribute) == "AXStaticText" && text($0, kAXValueAttribute) == args[2] }),
          let popup = els[start...].first(where: { text($0, kAXRoleAttribute) == "AXPopUpButton" }) else {
        fail("no pop-up after \"\(args[2])\"")
    }
    press(popup)
    usleep(400_000)
    var inPopup: [AXUIElement] = []
    all(popup, 0, &inPopup)
    guard let item = inPopup.first(where: { text($0, kAXRoleAttribute) == "AXMenuItem" && text($0, kAXTitleAttribute) == args[3] }) else {
        let titles = inPopup.compactMap { text($0, kAXRoleAttribute) == "AXMenuItem" ? text($0, kAXTitleAttribute) : nil }
        sendKeys([(53, [], nil)])
        fail("no item \"\(args[3])\"; have \(titles)")
    }
    press(item)

case "select-row":  // select-row <window> <text>
    var els: [AXUIElement] = []
    all(window(args[1]), 0, &els)
    guard let row = els.first(where: { el in
        guard text(el, kAXRoleAttribute) == "AXRow" else { return false }
        var inRow: [AXUIElement] = []
        all(el, 0, &inRow)
        return inRow.contains { matches($0, args[2]) }
    }) else { fail("no row \"\(args[2])\"") }
    let err = AXUIElementSetAttributeValue(row, kAXSelectedAttribute as CFString, kCFBooleanTrue)
    if err != .success { fail("select failed (\(err.rawValue))") }

case "focus":  // focus <window> <role> [subrole]
    var els: [AXUIElement] = []
    all(window(args[1]), 0, &els)
    guard let el = els.first(where: { text($0, kAXRoleAttribute) == args[2] && (args.count < 4 || text($0, kAXSubroleAttribute) == args[3]) }) else {
        fail("no \(args[2]) to focus")
    }
    AXUIElementSetAttributeValue(el, kAXFocusedAttribute as CFString, kCFBooleanTrue)

case "activate":
    AXUIElementSetAttributeValue(app, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
    if let w = windows().first { AXUIElementPerformAction(w, kAXRaiseAction as CFString) }
    usleep(500_000)
    print("frontmost:", NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "?")

case "key-settings":  // ⌘,
    sendKeys([(43, .maskCommand, nil)])

case "key-close":  // ⌘W
    sendKeys([(13, .maskCommand, nil)])

case "key-escape":
    sendKeys([(53, [], nil)])

case "type":  // type <text>
    sendKeys(args[1].map { (0, [], String($0)) })

default:
    fail("usage: windows | tree <win> [depth] | menu <top> | press-menu <top> <item> | press <win> <role> <text> | press-after|value-after <win> <role> <label> | choose <win> <label> <item> | select-row <win> <text> | focus <win> <role> [subrole] | activate | key-settings | key-close | key-escape | type <text>")
}
