import SwiftUI
import UniformTypeIdentifiers

enum NavigationItem: String, CaseIterable, Identifiable {
    case status = "Status"
    case fileTypes = "File Types"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .status: return "checkmark.circle"
        case .fileTypes: return "doc.text"
        case .settings: return "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: NavigationItem = .status

    var body: some View {
        NavigationSplitView {
            List(NavigationItem.allCases, selection: $selectedItem) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
        } detail: {
            switch selectedItem {
            case .status:
                StatusView()
            case .fileTypes:
                FileTypesView()
            case .settings:
                SettingsView()
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

// MARK: - Status View

struct StatusView: View {
    @State private var isExtensionEnabled = false
    @State private var isCheckingStatus = true

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // App Icon and Title
                VStack(spacing: 12) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue.gradient)
                        .modifier(BounceEffectModifierFallback())
                    Text("dotViewer")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Quick Look for Source Code & Dotfiles")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            
                .padding(.top, 20)

                // Extension Status Card
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        if isCheckingStatus {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: isExtensionEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(isExtensionEnabled ? .green : .red)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(isCheckingStatus ? "Checking Status..." : (isExtensionEnabled ? "Extension Enabled" : "Extension Not Enabled"))
                                .font(.headline)
                            Text(isExtensionEnabled
                                ? "dotViewer is ready to preview your files"
                                : "Enable the extension in System Settings")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            checkExtensionStatus()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .help("Refresh status")
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                    if !isExtensionEnabled && !isCheckingStatus {
                        Button {
                            openExtensionSettings()
                        } label: {
                            Label("Open Extension Settings", systemImage: "gear")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .frame(maxWidth: 400)

                // Quick Stats
                if isExtensionEnabled {
                    VStack(spacing: 16) {
                        Text("Quick Stats")
                            .font(.headline)

                        HStack(spacing: 24) {
                            StatCard(
                                value: "\(FileTypeRegistry.shared.builtInTypes.count)",
                                label: "Built-in Types",
                                icon: "doc.text.fill",
                                color: .blue
                            )

                            StatCard(
                                value: "\(SharedSettings.shared.customExtensions.count)",
                                label: "Custom Types",
                                icon: "plus.circle.fill",
                                color: .orange
                            )

                            StatCard(
                                value: "\(SharedSettings.shared.disabledFileTypes.count)",
                                label: "Disabled",
                                icon: "eye.slash.fill",
                                color: .gray
                            )
                        }
                    }
                }

                // How to use
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to Use")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        HowToRow(number: 1, text: "Select any code file in Finder")
                        HowToRow(number: 2, text: "Press Space to Quick Look")
                        HowToRow(number: 3, text: "View syntax-highlighted preview")
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .frame(maxWidth: 400)

                Spacer(minLength: 20)

                // Footer
                HStack {
                    Text("v1.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Link(destination: URL(string: "https://github.com/stianlars1/dotViewer")!) {
                        Label("GitHub", systemImage: "arrow.up.right.square")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: 400)
            }
            .padding(32)
        }
        .navigationTitle("Status")
        .onAppear {
            checkExtensionStatus()
        }
    }

    private func checkExtensionStatus() {
        isCheckingStatus = true

        DispatchQueue.global(qos: .userInitiated).async {
            var isEnabled = false

            // Method 1: Check via pluginkit command with timeout
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
            task.arguments = ["-m", "-p", "com.apple.quicklook.preview"]

            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = FileHandle.nullDevice

            // Use semaphore with timeout to prevent indefinite hangs
            let semaphore = DispatchSemaphore(value: 0)
            task.terminationHandler = { _ in semaphore.signal() }

            do {
                try task.run()

                // Wait max 5 seconds for pluginkit to complete
                let result = semaphore.wait(timeout: .now() + 5)

                if result == .timedOut {
                    // Timeout - terminate the process and skip to fallback
                    task.terminate()
                    print("[dotViewer] pluginkit timed out")
                } else if task.terminationStatus == 0 {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""

                    // pluginkit output format: "+    com.bundle.id(version)" for enabled
                    // The "+" prefix indicates the extension is enabled
                    // Split by lines and check each one
                    for line in output.components(separatedBy: .newlines) {
                        if line.contains("com.stianlars1.dotViewer.QuickLookPreview") {
                            // Check if line starts with "+" (enabled) vs "-" (disabled)
                            let trimmed = line.trimmingCharacters(in: .whitespaces)
                            isEnabled = trimmed.hasPrefix("+")
                            break
                        }
                    }
                }
            } catch {
                print("[dotViewer] pluginkit error: \(error)")
            }

            // Method 2: Fallback - check if extension file exists in app bundle
            if !isEnabled {
                let extensionPath = Bundle.main.bundlePath + "/Contents/PlugIns/QuickLookPreview.appex"
                if FileManager.default.fileExists(atPath: extensionPath) {
                    // Extension exists in bundle, assume enabled if pluginkit failed
                    // This handles cases where pluginkit might not work in sandbox
                    isEnabled = true
                }
            }

            DispatchQueue.main.async {
                self.isExtensionEnabled = isEnabled
                self.isCheckingStatus = false
            }
        }
    }

    private func openExtensionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
            NSWorkspace.shared.open(url)
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 100)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct HowToRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(.blue, in: Circle())

            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @State private var maxFileSize: Double = Double(SharedSettings.shared.maxFileSize) / 1000.0
    @State private var showTruncationWarning = SharedSettings.shared.showTruncationWarning
    @State private var showPreviewHeader = SharedSettings.shared.showPreviewHeader
    @State private var markdownRenderMode = SharedSettings.shared.markdownRenderMode
    @State private var previewUnknownFiles = SharedSettings.shared.previewUnknownFiles
    @State private var showOpenInAppButton = SharedSettings.shared.showOpenInAppButton
    @State private var preferredEditorName = SharedSettings.shared.preferredEditorName ?? ""

    private let themes = [
        ("auto", "Auto (System)"),
        ("atomOneLight", "Atom One Light"),
        ("atomOneDark", "Atom One Dark"),
        ("github", "GitHub Light"),
        ("githubDark", "GitHub Dark"),
        ("xcode", "Xcode Light"),
        ("xcodeDark", "Xcode Dark"),
        ("solarizedLight", "Solarized Light"),
        ("solarizedDark", "Solarized Dark"),
        ("tokyoNight", "Tokyo Night"),
        ("blackout", "Blackout"),
    ]

    // List of common editors - only installed ones will be shown
    private var installedEditors: [(name: String, bundleId: String, icon: String)] {
        let editors: [(name: String, bundleId: String, icon: String)] = [
            ("VS Code", "com.microsoft.VSCode", "curlybraces.square"),
            ("Xcode", "com.apple.dt.Xcode", "hammer"),
            ("Sublime", "com.sublimetext.4", "text.alignleft"),
            ("TextEdit", "com.apple.TextEdit", "doc.text"),
            ("Nova", "com.panic.Nova", "sparkle"),
            ("BBEdit", "com.barebones.bbedit", "text.badge.star"),
            ("Cursor", "com.todesktop.230313mzl4w4u92", "cursorarrow.click.badge.clock"),
            ("Zed", "dev.zed.Zed", "text.cursor"),
        ]
        return editors.filter { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0.bundleId) != nil }
    }

    // Check if current selection is a custom app (not in preset list)
    private var isCustomAppSelected: Bool {
        guard let bundleId = SharedSettings.shared.preferredEditorBundleId else { return false }
        let presetBundleIds = ["com.microsoft.VSCode", "com.apple.dt.Xcode", "com.sublimetext.4",
                              "com.apple.TextEdit", "com.panic.Nova", "com.barebones.bbedit",
                              "com.todesktop.230313mzl4w4u92", "dev.zed.Zed"]
        return !presetBundleIds.contains(bundleId)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Appearance Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Appearance")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Theme", selection: $themeManager.selectedTheme) {
                            ForEach(themes, id: \.0) { theme in
                                Text(theme.1).tag(theme.0)
                            }
                        }
                        .pickerStyle(.menu)

                        HStack {
                            Text("Font Size")
                            Spacer()
                            Text("\(Int(themeManager.fontSize))pt")
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $themeManager.fontSize, in: 10...24, step: 1)

                        Toggle("Show Line Numbers", isOn: $themeManager.showLineNumbers)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Preview Limits Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preview Limits")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Max File Size")
                            Spacer()
                            Text("\(Int(maxFileSize)) KB")
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $maxFileSize, in: 100...2000, step: 100)
                            .onChange(of: maxFileSize) { _, newValue in
                                SharedSettings.shared.maxFileSize = Int(newValue * 1000)
                            }

                        Text("Files larger than this will be truncated in preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        Toggle("Show Truncation Warning", isOn: $showTruncationWarning)
                            .onChange(of: showTruncationWarning) { _, newValue in
                                SharedSettings.shared.showTruncationWarning = newValue
                            }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Preview UI Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preview UI")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Show File Info Header", isOn: $showPreviewHeader)
                            .onChange(of: showPreviewHeader) { _, newValue in
                                SharedSettings.shared.showPreviewHeader = newValue
                            }

                        Text("Shows filename, language, line count, and file size in preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        Picker("Markdown Preview", selection: $markdownRenderMode) {
                            Text("Raw Code").tag("raw")
                            Text("Rendered").tag("rendered")
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: markdownRenderMode) { _, newValue in
                            SharedSettings.shared.markdownRenderMode = newValue
                        }

                        Text("How to display Markdown files (.md) in preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        Toggle("Preview All File Types", isOn: $previewUnknownFiles)
                            .onChange(of: previewUnknownFiles) { _, newValue in
                                SharedSettings.shared.previewUnknownFiles = newValue
                            }

                        Text("Show plain text preview for unrecognized file types")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Open in App Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Open in App")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Show \"Open in App\" Button", isOn: $showOpenInAppButton)
                            .onChange(of: showOpenInAppButton) { _, newValue in
                                SharedSettings.shared.showOpenInAppButton = newValue
                            }

                        Text("Adds a button to the preview header to quickly open files")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        Text("Select Preferred Editor")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // Grid of installed editors + custom button
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70, maximum: 80), spacing: 12)], spacing: 12) {
                            // Only show installed preset editors
                            ForEach(installedEditors, id: \.bundleId) { editor in
                                EditorButton(
                                    name: editor.name,
                                    bundleId: editor.bundleId,
                                    icon: editor.icon,
                                    selectedEditor: $preferredEditorName
                                )
                            }

                            // Custom app button (always shown)
                            CustomEditorButton(
                                selectedEditor: $preferredEditorName,
                                onChooseApp: chooseCustomEditor
                            )
                        }

                        // Reset button
                        if !preferredEditorName.isEmpty {
                            Button("Reset to System Default") {
                                SharedSettings.shared.preferredEditorBundleId = nil
                                SharedSettings.shared.preferredEditorName = nil
                                preferredEditorName = ""
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                        }

                        Text("Files will open in the selected app when you click the button in Quick Look preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                // Theme Preview
                VStack(alignment: .leading, spacing: 16) {
                    Text("Theme Preview")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("// Example code preview")
                            .font(.system(size: themeManager.fontSize, design: .monospaced))
                            .foregroundStyle(themeManager.textColor.opacity(0.5))

                        Text("func greet(name: String) -> String {")
                            .font(.system(size: themeManager.fontSize, design: .monospaced))
                            .foregroundStyle(themeManager.textColor)

                        Text("    return \"Hello, \\(name)!\"")
                            .font(.system(size: themeManager.fontSize, design: .monospaced))
                            .foregroundStyle(themeManager.textColor)

                        Text("}")
                            .font(.system(size: themeManager.fontSize, design: .monospaced))
                            .foregroundStyle(themeManager.textColor)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(themeManager.backgroundColor, in: RoundedRectangle(cornerRadius: 12))
                }

                // Danger Zone Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Danger Zone")
                        .font(.headline)
                        .foregroundStyle(.red)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Remove dotViewer from your system")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button(role: .destructive) {
                            uninstallApp()
                        } label: {
                            Label("Uninstall dotViewer", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }

                Spacer()
            }
            .padding(32)
        }
        .navigationTitle("Settings")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func chooseCustomEditor() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.message = "Choose an application to open files with"
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            if let bundle = Bundle(url: url),
               let bundleId = bundle.bundleIdentifier {
                let appName = bundle.infoDictionary?["CFBundleName"] as? String
                    ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                    ?? url.deletingPathExtension().lastPathComponent

                SharedSettings.shared.preferredEditorBundleId = bundleId
                SharedSettings.shared.preferredEditorName = appName
                preferredEditorName = appName
            }
        }
    }

    private func uninstallApp() {
        let alert = NSAlert()
        alert.messageText = "Uninstall dotViewer?"
        alert.informativeText = "This will move dotViewer to the Trash. You can restore it from the Trash if needed."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Uninstall")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            let appURL = Bundle.main.bundleURL
            do {
                try FileManager.default.trashItem(at: appURL, resultingItemURL: nil)
                NSApplication.shared.terminate(nil)
            } catch {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Failed to Uninstall"
                errorAlert.informativeText = "Could not move dotViewer to Trash: \(error.localizedDescription)"
                errorAlert.alertStyle = .critical
                errorAlert.runModal()
            }
        }
    }
}

// MARK: - Editor Button

struct EditorButton: View {
    let name: String
    let bundleId: String
    let icon: String
    @Binding var selectedEditor: String

    private var isSelected: Bool {
        SharedSettings.shared.preferredEditorBundleId == bundleId
    }

    var body: some View {
        Button {
            SharedSettings.shared.preferredEditorBundleId = bundleId
            SharedSettings.shared.preferredEditorName = name
            selectedEditor = name
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(name)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(width: 70, height: 60)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .help("Open files in \(name)")
    }
}

// MARK: - Custom Editor Button

struct CustomEditorButton: View {
    @Binding var selectedEditor: String
    let onChooseApp: () -> Void

    private var settings: SharedSettings { SharedSettings.shared }

    private var isCustomSelected: Bool {
        guard let bundleId = settings.preferredEditorBundleId else { return false }
        let presetBundleIds = ["com.microsoft.VSCode", "com.apple.dt.Xcode", "com.sublimetext.4",
                              "com.apple.TextEdit", "com.panic.Nova", "com.barebones.bbedit",
                              "com.todesktop.230313mzl4w4u92", "dev.zed.Zed"]
        return !presetBundleIds.contains(bundleId)
    }

    private var customAppName: String? {
        isCustomSelected ? settings.preferredEditorName : nil
    }

    private var customAppIcon: NSImage? {
        guard isCustomSelected,
              let bundleId = settings.preferredEditorBundleId,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }

    var body: some View {
        Button {
            onChooseApp()
        } label: {
            VStack(spacing: 6) {
                if let icon = customAppIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "plus.app")
                        .font(.system(size: 20))
                }
                Text(customAppName ?? "Custom")
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(width: 70, height: 60)
            .background(isCustomSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCustomSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .help(isCustomSelected ? "Custom app: \(customAppName ?? "Unknown")" : "Choose a custom app")
    }
}

// MARK: - Bounce Effect Modifier

@available(macOS 15.0, *)
struct BounceEffectModifier: ViewModifier {
    @State private var didAppear = false

    func body(content: Content) -> some View {
        content
            .symbolEffect(.bounce.up.byLayer, options: .nonRepeating, value: didAppear)
            .onAppear {
                didAppear = true
            }
    }
}

// Fallback for older macOS versions
struct BounceEffectModifierFallback: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content.modifier(BounceEffectModifier())
        } else {
            content
        }
    }
}

#Preview {
    ContentView()
}
