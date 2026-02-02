# dotViewer v2.0 - Complete Rewrite Specification

**Version:** 2.0 (Improved)
**Date:** 2026-02-02
**Purpose:** Complete rewrite prompt for blazing-fast Quick Look extension

---

## CRITICAL FIRST STEP

**Before writing ANY code, read these files in the repository:**
```
1. QUICKLOOK_PERFORMANCE_RESEARCH.md - Competitor analysis
2. DOTVIEWER_VS_COMPETITORS_ANALYSIS.md - Why v1 is slow
```

These explain why the old version was slow (JavaScript highlighting) and what competitors do (native C/C++).

---

## Project Overview

### What We're Building
**dotViewer** - A macOS Quick Look extension that previews:
- Source code with **instant** syntax highlighting
- Dotfiles and config files
- Markdown with raw/rendered toggle
- Any text-based file

### Why Rewriting
Current v1 uses JavaScript (HighlightSwift/highlight.js) which is 10-100x slower than native. Files >4KB are noticeably slow.

### Performance Target
```
1KB file:  <50ms  (instant feel)
10KB file: <100ms (instant feel)
50KB file: <200ms (barely noticeable)
100KB:     <500ms (acceptable)
```

---

## Part 1: Project Structure (NEW XCODE PROJECT)

Create a **brand new** Xcode project. Do NOT modify existing code.

### Three Targets Required

```
dotViewer.xcodeproj
├── dotViewer/                    # Main App (SwiftUI)
│   ├── dotViewerApp.swift
│   ├── Views/
│   │   ├── ContentView.swift     # Navigation container
│   │   ├── StatusView.swift      # Extension status & onboarding
│   │   ├── FileTypesView.swift   # File type management (ACCORDION!)
│   │   └── SettingsView.swift    # All preferences
│   ├── Models/
│   │   ├── FileType.swift
│   │   ├── FileTypeCategory.swift
│   │   └── Theme.swift           # ENUM, not strings!
│   ├── Services/
│   │   ├── ExtensionStatusChecker.swift  # pluginkit detection
│   │   └── SharedSettings.swift
│   └── Info.plist
│
├── QuickLookExtension/           # Quick Look Extension
│   ├── PreviewViewController.swift
│   ├── PreviewView.swift         # SwiftUI preview
│   ├── MarkdownRenderer.swift    # For rendered mode
│   ├── Info.plist                # UTI declarations
│   └── QuickLookExtension.entitlements
│
├── HighlightService/             # XPC Service (CRITICAL FOR SPEED)
│   ├── main.swift
│   ├── HighlightServiceDelegate.swift
│   ├── HighlightServiceProtocol.swift
│   ├── NativeHighlighter.swift   # Tree-sitter OR regex-based
│   └── HighlightService.entitlements
│
└── Shared/                       # Shared Framework
    ├── HighlightProtocol.swift
    ├── FileTypeRegistry.swift
    ├── LanguageDetector.swift
    ├── ThemeColors.swift
    └── SharedSettings.swift
```

### App Group Configuration
Both the main app and extension need App Groups entitlement:
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.yourname.dotViewer.shared</string>
</array>
```

---

## Part 2: Extension Status Detection (CRITICAL!)

The app must correctly detect if the Quick Look extension is enabled in System Settings.

### Implementation (EXACT COPY THIS)

```swift
import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.yourname.dotViewer", category: "StatusChecker")

@MainActor
final class ExtensionStatusChecker: ObservableObject {
    static let shared = ExtensionStatusChecker()

    @Published private(set) var isEnabled = false
    @Published private(set) var isChecking = true

    private var checkTask: Task<Void, Never>?

    private init() {}

    func check() {
        checkTask?.cancel()
        isChecking = true

        checkTask = Task {
            let enabled = await checkPluginkit()
            guard !Task.isCancelled else { return }
            self.isEnabled = enabled
            self.isChecking = false
        }
    }

    /// CRITICAL: Uses pluginkit to detect extension status
    private nonisolated func checkPluginkit() async -> Bool {
        await withCheckedContinuation { continuation in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
            task.arguments = ["-m", "-p", "com.apple.quicklook.preview"]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = FileHandle.nullDevice

            var hasResumed = false
            let resumeOnce: (Bool) -> Void = { result in
                guard !hasResumed else { return }
                hasResumed = true
                continuation.resume(returning: result)
            }

            // Timeout after 5 seconds
            DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
                task.terminate()
                resumeOnce(false)
            }

            task.terminationHandler = { [pipe] _ in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                // Parse: "+" prefix = enabled, "-" = disabled
                for line in output.components(separatedBy: .newlines) {
                    // IMPORTANT: Use YOUR bundle ID here!
                    if line.contains("com.yourname.dotViewer.QuickLookExtension") {
                        let enabled = line.first == "+"
                        resumeOnce(enabled)
                        return
                    }
                }
                resumeOnce(false)
            }

            do {
                try task.run()
            } catch {
                resumeOnce(false)
            }
        }
    }
}
```

### Status View Must Show Correct State

```swift
struct StatusView: View {
    @ObservedObject private var statusChecker = ExtensionStatusChecker.shared

    var body: some View {
        VStack {
            // Status indicator
            HStack {
                Circle()
                    .fill(statusChecker.isEnabled ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(statusChecker.isEnabled ? "Extension Enabled" : "Extension Disabled")
            }

            // Only show enable instructions if NOT enabled
            if !statusChecker.isEnabled {
                EnableInstructionsView()
            }
        }
        .onAppear {
            statusChecker.check()
        }
    }
}
```

---

## Part 3: Main App Views (THREE TABS)

### Navigation Structure

```swift
struct ContentView: View {
    enum Tab: String, CaseIterable {
        case status = "Status"
        case fileTypes = "File Types"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .status: return "checkmark.circle"
            case .fileTypes: return "doc.text"
            case .settings: return "gear"
            }
        }
    }

    @State private var selectedTab: Tab = .status

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(Tab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180)
        } detail: {
            // Content
            switch selectedTab {
            case .status:
                StatusView()
            case .fileTypes:
                FileTypesView()
            case .settings:
                SettingsView()  // THIS MUST EXIST!
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}
```

---

## Part 4: Settings View (COMPLETE SPECIFICATION)

**THIS VIEW MUST BE IMPLEMENTED. The v1 attempt was missing it.**

### All Settings to Implement

```swift
struct SettingsView: View {
    // App Group shared settings
    @AppStorage("selectedTheme", store: UserDefaults(suiteName: "group.com.yourname.dotViewer.shared"))
    private var selectedTheme = "auto"

    @AppStorage("fontSize", store: UserDefaults(suiteName: "group.com.yourname.dotViewer.shared"))
    private var fontSize = 13.0

    @AppStorage("showLineNumbers", store: UserDefaults(suiteName: "group.com.yourname.dotViewer.shared"))
    private var showLineNumbers = true

    @AppStorage("maxFileSize", store: UserDefaults(suiteName: "group.com.yourname.dotViewer.shared"))
    private var maxFileSize = 100_000  // 100KB default

    @AppStorage("showTruncationWarning", store: UserDefaults(suiteName: "group.com.yourname.dotViewer.shared"))
    private var showTruncationWarning = true

    @AppStorage("showPreviewHeader", store: UserDefaults(suiteName: "group.com.yourname.dotViewer.shared"))
    private var showPreviewHeader = true

    @AppStorage("markdownRenderMode", store: UserDefaults(suiteName: "group.com.yourname.dotViewer.shared"))
    private var markdownRenderMode = "raw"  // "raw" or "rendered"

    @AppStorage("previewUnknownFiles", store: UserDefaults(suiteName: "group.com.yourname.dotViewer.shared"))
    private var previewUnknownFiles = true

    var body: some View {
        Form {
            // SECTION 1: Appearance
            Section("Appearance") {
                // Theme picker
                Picker("Theme", selection: $selectedTheme) {
                    Text("Auto (System)").tag("auto")
                    Divider()
                    Text("Atom One Light").tag("atomOneLight")
                    Text("Atom One Dark").tag("atomOneDark")
                    Text("GitHub Light").tag("github")
                    Text("GitHub Dark").tag("githubDark")
                    Text("Xcode Light").tag("xcode")
                    Text("Xcode Dark").tag("xcodeDark")
                    Text("Solarized Light").tag("solarizedLight")
                    Text("Solarized Dark").tag("solarizedDark")
                    Text("Tokyo Night").tag("tokyoNight")
                    Text("Blackout").tag("blackout")
                }

                // Font size slider
                HStack {
                    Text("Font Size")
                    Slider(value: $fontSize, in: 10...20, step: 1)
                    Text("\(Int(fontSize))pt")
                        .monospacedDigit()
                        .frame(width: 40)
                }

                // Line numbers toggle
                Toggle("Show Line Numbers", isOn: $showLineNumbers)
            }

            // SECTION 2: Preview Limits
            Section("Preview Limits") {
                // File size slider
                VStack(alignment: .leading) {
                    HStack {
                        Text("Max File Size")
                        Spacer()
                        Text(formatFileSize(maxFileSize))
                            .foregroundStyle(.secondary)
                    }
                    Slider(
                        value: Binding(
                            get: { Double(maxFileSize) },
                            set: { maxFileSize = Int($0) }
                        ),
                        in: 10_000...500_000,
                        step: 10_000
                    )
                    Text("Files larger than this will be truncated in preview")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Toggle("Show Truncation Warning", isOn: $showTruncationWarning)
            }

            // SECTION 3: Preview UI
            Section("Preview UI") {
                Toggle("Show File Info Header", isOn: $showPreviewHeader)
                    .help("Shows filename, language, line count, and file size in preview")

                // Markdown mode picker
                Picker("Markdown Preview", selection: $markdownRenderMode) {
                    Text("Raw Code").tag("raw")
                    Text("Rendered").tag("rendered")
                }
                .pickerStyle(.segmented)
                .help("How to display Markdown files (.md) in preview")

                Toggle("Preview All File Types", isOn: $previewUnknownFiles)
                    .help("Show plain text preview for unrecognized file types")
            }

            // SECTION 4: Theme Preview
            Section("Theme Preview") {
                ThemePreviewBox(theme: selectedTheme, fontSize: fontSize)
                    .frame(height: 120)
            }

            // SECTION 5: Danger Zone
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Danger Zone")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text("Remove dotViewer from your system")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(role: .destructive) {
                        uninstallApp()
                    } label: {
                        Label("Uninstall dotViewer", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func formatFileSize(_ bytes: Int) -> String {
        if bytes >= 1_000_000 {
            return "\(bytes / 1_000_000) MB"
        } else {
            return "\(bytes / 1_000) KB"
        }
    }

    private func uninstallApp() {
        // Move app to trash
        NSWorkspace.shared.recycle([Bundle.main.bundleURL]) { _, _ in
            NSApp.terminate(nil)
        }
    }
}

// Theme preview component
struct ThemePreviewBox: View {
    let theme: String
    let fontSize: Double

    var body: some View {
        // Show sample code with selected theme colors
        ScrollView {
            Text(sampleCode)
                .font(.system(size: fontSize, design: .monospaced))
                .padding()
        }
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var sampleCode: AttributedString {
        // Return syntax-highlighted sample code
        var str = AttributedString("// Example code preview\nfunc greet(name: String) -> String {\n    return \"Hello, \\(name)!\"\n}")
        // Apply theme colors...
        return str
    }

    private var backgroundColor: Color {
        // Return theme background color
        theme.contains("Dark") || theme == "blackout" || theme == "tokyoNight"
            ? Color(white: 0.1)
            : Color(white: 0.95)
    }
}
```

---

## Part 5: File Types View (ACCORDION EXPAND/COLLAPSE)

**CRITICAL: Categories must be collapsible accordions, collapsed by default.**

### Implementation

```swift
struct FileTypesView: View {
    @State private var searchText = ""
    @State private var expandedCategories: Set<FileTypeCategory> = []  // Empty = all collapsed
    @State private var showingAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            // Search bar + Add button
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search file types...", text: $searchText)
                    .textFieldStyle(.plain)

                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Custom", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Category list with accordions
            List {
                ForEach(FileTypeCategory.allCases.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.self) { category in
                    CategoryAccordionView(
                        category: category,
                        isExpanded: expandedCategories.contains(category),
                        onToggle: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedCategories.contains(category) {
                                    expandedCategories.remove(category)
                                } else {
                                    expandedCategories.insert(category)
                                }
                            }
                        },
                        searchText: searchText
                    )
                }
            }
            .listStyle(.plain)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddCustomExtensionSheet()
        }
    }
}

struct CategoryAccordionView: View {
    let category: FileTypeCategory
    let isExpanded: Bool
    let onToggle: () -> Void
    let searchText: String

    private var fileTypes: [SupportedFileType] {
        FileTypeRegistry.shared.builtInTypes
            .filter { $0.category == category }
            .filter { searchText.isEmpty ||
                      $0.displayName.localizedCaseInsensitiveContains(searchText) ||
                      $0.extensions.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
    }

    var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { isExpanded },
                set: { _ in onToggle() }
            )
        ) {
            // Expanded content: list of file types
            ForEach(fileTypes) { fileType in
                FileTypeRow(fileType: fileType)
            }
        } label: {
            // Category header
            HStack {
                Image(systemName: category.icon)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                Text(category.rawValue)
                    .fontWeight(.medium)
                Spacer()
                Text("\(fileTypes.count)")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
    }
}

struct FileTypeRow: View {
    let fileType: SupportedFileType
    @State private var isEnabled: Bool

    init(fileType: SupportedFileType) {
        self.fileType = fileType
        // Initialize from SharedSettings
        let disabled = SharedSettings.shared.disabledFileTypes
        self._isEnabled = State(initialValue: !disabled.contains(fileType.id))
    }

    var body: some View {
        HStack {
            Toggle("", isOn: $isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
                .onChange(of: isEnabled) { _, newValue in
                    var disabled = SharedSettings.shared.disabledFileTypes
                    if newValue {
                        disabled.remove(fileType.id)
                    } else {
                        disabled.insert(fileType.id)
                    }
                    SharedSettings.shared.disabledFileTypes = disabled
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(fileType.displayName)
                    .fontWeight(.medium)
                Text(fileType.extensionDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.leading, 28)  // Indent under category
        .padding(.vertical, 4)
    }
}
```

---

## Part 6: Quick Look Preview UI (EXACT SPECIFICATION)

### Header Bar Components

```
┌─────────────────────────────────────────────────────────────┐
│ ≡ │ [</> Raw] │ [Language Badge] │ 32 lines • 553 byte │ 📋 │
└─────────────────────────────────────────────────────────────┘
```

### Implementation

```swift
struct PreviewView: View {
    let state: PreviewState
    @State private var highlightedContent: AttributedString?
    @State private var showRenderedMarkdown: Bool

    init(state: PreviewState) {
        self.state = state
        _showRenderedMarkdown = State(
            initialValue: SharedSettings.shared.markdownRenderMode == "rendered"
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header (if enabled in settings)
            if SharedSettings.shared.showPreviewHeader {
                PreviewHeader(
                    language: state.language,
                    lineCount: state.lineCount,
                    fileSize: state.fileSize,
                    isMarkdown: state.language == "markdown",
                    showRendered: $showRenderedMarkdown,
                    onCopy: { copyToClipboard() }
                )
            }

            // Truncation warning (if applicable)
            if state.isTruncated && SharedSettings.shared.showTruncationWarning {
                TruncationBanner(originalSize: state.originalFileSize)
            }

            // Content
            if state.language == "markdown" && showRenderedMarkdown {
                MarkdownRenderedView(content: state.content)
            } else {
                CodeView(
                    content: state.content,
                    highlightedContent: highlightedContent,
                    showLineNumbers: SharedSettings.shared.showLineNumbers,
                    fontSize: SharedSettings.shared.fontSize
                )
            }
        }
        .task {
            await loadHighlighting()
        }
    }
}

struct PreviewHeader: View {
    let language: String?
    let lineCount: Int
    let fileSize: String
    let isMarkdown: Bool
    @Binding var showRendered: Bool
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Menu button (hamburger)
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)

            Spacer()

            // Raw/Rendered toggle (only for markdown)
            if isMarkdown {
                Button {
                    showRendered.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showRendered ? "doc.richtext" : "chevron.left.forwardslash.chevron.right")
                        Text(showRendered ? "Rendered" : "Raw")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.15))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Language badge
            if let lang = language {
                Text(lang.capitalized)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }

            // Stats
            Text("\(lineCount) lines")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Text("•")
                .foregroundStyle(.tertiary)

            Text(fileSize)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            // Copy button
            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .help("Copy to clipboard")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
}
```

---

## Part 7: Native Syntax Highlighting (THE KEY TO PERFORMANCE)

### Option A: Simple Regex-Based (RECOMMENDED FOR FIRST VERSION)

This is faster than JavaScript and good enough for most cases:

```swift
struct NativeHighlighter {

    func highlight(code: String, language: String, theme: Theme) -> AttributedString {
        var result = AttributedString(code)
        let colors = theme.colors

        // Apply base text color
        result.foregroundColor = colors.text

        // Get patterns for language
        let patterns = getPatterns(for: language)

        // Apply highlighting
        applyPattern(patterns.comments, color: colors.comment, to: &result, in: code)
        applyPattern(patterns.strings, color: colors.string, to: &result, in: code)
        applyPattern(patterns.keywords, color: colors.keyword, to: &result, in: code)
        applyPattern(patterns.numbers, color: colors.number, to: &result, in: code)
        applyPattern(patterns.types, color: colors.type, to: &result, in: code)

        return result
    }

    private func applyPattern(_ pattern: String, color: Color, to result: inout AttributedString, in code: String) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        let nsRange = NSRange(code.startIndex..., in: code)

        for match in regex.matches(in: code, options: [], range: nsRange) {
            guard let range = Range(match.range, in: code),
                  let attrRange = Range(range, in: result) else { continue }
            result[attrRange].foregroundColor = color
        }
    }

    private func getPatterns(for language: String) -> LanguagePatterns {
        switch language.lowercased() {
        case "swift":
            return LanguagePatterns(
                comments: "//[^\n]*|/\\*[\\s\\S]*?\\*/",
                strings: "\"(?:[^\"\\\\]|\\\\.)*\"",
                keywords: "\\b(func|let|var|if|else|guard|return|import|class|struct|enum|protocol|extension|private|public|static|self|nil|true|false|for|while|switch|case|break|async|await)\\b",
                numbers: "\\b\\d+\\.?\\d*\\b",
                types: "\\b(String|Int|Double|Bool|Array|Dictionary|Set|Optional|View|Color|Text)\\b"
            )
        case "javascript", "typescript":
            return LanguagePatterns(
                comments: "//[^\n]*|/\\*[\\s\\S]*?\\*/",
                strings: "\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*'|`(?:[^`\\\\]|\\\\.)*`",
                keywords: "\\b(function|const|let|var|if|else|return|import|export|class|extends|new|this|null|undefined|true|false|for|while|async|await|interface|type)\\b",
                numbers: "\\b\\d+\\.?\\d*\\b",
                types: "\\b(string|number|boolean|any|void|Promise|Array|Map|Set)\\b"
            )
        // Add more languages...
        default:
            return LanguagePatterns(
                comments: "//[^\n]*|#[^\n]*",
                strings: "\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*'",
                keywords: "\\b(if|else|for|while|return|function|class|import|export|true|false|null)\\b",
                numbers: "\\b\\d+\\.?\\d*\\b",
                types: ""
            )
        }
    }
}

struct LanguagePatterns {
    let comments: String
    let strings: String
    let keywords: String
    let numbers: String
    let types: String
}
```

### Option B: Tree-sitter (BETTER, BUT MORE COMPLEX)

Use the `SwiftTreeSitter` package for true parsing:
```swift
// Package.swift dependency:
.package(url: "https://github.com/ChimeHQ/SwiftTreeSitter", from: "0.8.0")
```

---

## Part 8: Theme Definition (ENUM, NOT STRINGS!)

```swift
enum Theme: String, CaseIterable, Identifiable {
    case auto = "auto"
    case atomOneLight = "atomOneLight"
    case atomOneDark = "atomOneDark"
    case github = "github"
    case githubDark = "githubDark"
    case xcode = "xcode"
    case xcodeDark = "xcodeDark"
    case solarizedLight = "solarizedLight"
    case solarizedDark = "solarizedDark"
    case tokyoNight = "tokyoNight"
    case blackout = "blackout"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "Auto (System)"
        case .atomOneLight: return "Atom One Light"
        case .atomOneDark: return "Atom One Dark"
        case .github: return "GitHub Light"
        case .githubDark: return "GitHub Dark"
        case .xcode: return "Xcode Light"
        case .xcodeDark: return "Xcode Dark"
        case .solarizedLight: return "Solarized Light"
        case .solarizedDark: return "Solarized Dark"
        case .tokyoNight: return "Tokyo Night"
        case .blackout: return "Blackout"
        }
    }

    var isDark: Bool {
        switch self {
        case .auto:
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        case .atomOneDark, .githubDark, .xcodeDark, .solarizedDark, .tokyoNight, .blackout:
            return true
        default:
            return false
        }
    }

    var colors: ThemeColors {
        switch self {
        case .auto:
            return isDark ? Theme.atomOneDark.colors : Theme.atomOneLight.colors
        case .atomOneLight:
            return ThemeColors(
                background: Color(hex: "#FAFAFA"),
                text: Color(hex: "#383A42"),
                keyword: Color(hex: "#A626A4"),
                string: Color(hex: "#50A14F"),
                comment: Color(hex: "#A0A1A7"),
                number: Color(hex: "#986801"),
                type: Color(hex: "#C18401")
            )
        case .atomOneDark:
            return ThemeColors(
                background: Color(hex: "#282C34"),
                text: Color(hex: "#ABB2BF"),
                keyword: Color(hex: "#C678DD"),
                string: Color(hex: "#98C379"),
                comment: Color(hex: "#5C6370"),
                number: Color(hex: "#D19A66"),
                type: Color(hex: "#E5C07B")
            )
        // ... define all themes
        }
    }
}

struct ThemeColors {
    let background: Color
    let text: Color
    let keyword: Color
    let string: Color
    let comment: Color
    let number: Color
    let type: Color
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}
```

---

## Part 9: File Type Registry (COMPLETE DATA)

Include ALL file types from v1. Here are the categories and counts:

| Category | Count | Examples |
|----------|-------|----------|
| Web Development | 18 | TypeScript, JavaScript, JSX, TSX, Vue, Svelte, HTML, CSS, SCSS |
| Systems Languages | 17 | Swift, C, C++, Rust, Go, Java, Kotlin, C# |
| Scripting | 17 | Python, Ruby, PHP, Perl, Lua, R, Julia |
| Data & Config | 19 | JSON, YAML, TOML, XML, INI, SQL, GraphQL |
| Shell & Terminal | 13 | Bash, Zsh, Fish, PowerShell, Dockerfile, Makefile |
| Documentation | 9 | Markdown, MDX, LaTeX, Plain Text |
| Dotfiles | 7 | .gitignore, .env, .editorconfig, .npmrc |

**Total: 100 file types**

---

## Part 10: Implementation Checklist

### Phase 1: Project Setup
- [ ] Create new Xcode project with 3 targets
- [ ] Configure App Groups for both targets
- [ ] Set up Info.plist with UTI declarations
- [ ] Create basic navigation structure

### Phase 2: Main App Views
- [ ] StatusView with extension detection (pluginkit)
- [ ] FileTypesView with accordion categories
- [ ] SettingsView with all options
- [ ] Theme preview component

### Phase 3: Quick Look Extension
- [ ] PreviewViewController entry point
- [ ] PreviewView with header bar
- [ ] File reading with size limits
- [ ] Truncation handling

### Phase 4: Syntax Highlighting
- [ ] Native regex-based highlighter
- [ ] 10 theme color definitions
- [ ] Language pattern definitions
- [ ] Performance testing (<200ms for 50KB)

### Phase 5: Markdown Support
- [ ] Raw markdown with highlighting
- [ ] Rendered markdown view
- [ ] Toggle between modes

### Phase 6: Polish
- [ ] Test all 100 file types
- [ ] Test extension enable/disable detection
- [ ] Test settings sync between app and extension
- [ ] Performance benchmarks

---

## Success Criteria

1. **Extension status detection works correctly** - Green when enabled, red when disabled
2. **All 3 tabs visible** - Status, File Types, Settings
3. **Settings view complete** - All options from v1
4. **File types accordion** - Collapsed by default, expandable
5. **Syntax highlighting works** - Colors visible for code files
6. **Quick Look preview matches v1** - Header bar, copy button, raw/rendered toggle
7. **Performance** - 50KB file previews in <200ms

---

## Common Mistakes to Avoid

1. **Don't use HighlightSwift** - It's JavaScript, too slow
2. **Don't forget the Settings tab** - It was missing in first attempt
3. **Don't hardcode bundle IDs** - Use your own bundle ID in pluginkit check
4. **Don't forget App Group** - Settings won't sync without it
5. **Don't make accordions expanded by default** - They should be collapsed
6. **Don't skip the preview header** - It shows important file info

---

**Copy this entire document and paste it at the start of a new Claude Code session.**

---

*Document version: 2.0*
*Created: 2026-02-02*
