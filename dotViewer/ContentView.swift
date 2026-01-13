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
    @Environment(\.scenePhase) private var scenePhase

    // Timer for periodic polling (backup mechanism)
    private let pollTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

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
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
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
        // Auto-refresh when app becomes active (SwiftUI scenePhase)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                checkExtensionStatus()
            }
        }
        // Backup: NSApplication notification (more reliable on macOS)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkExtensionStatus()
        }
        // Periodic polling every 10 seconds as additional fallback
        .onReceive(pollTimer) { _ in
            // Only poll if not already checking to avoid redundant calls
            if !isCheckingStatus {
                checkExtensionStatus()
            }
        }
    }

    private func checkExtensionStatus() {
        isCheckingStatus = true

        DispatchQueue.global(qos: .userInitiated).async {
            var isEnabled = false
            var foundInPluginkit = false  // Track if we found our extension in pluginkit output

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
                } else {
                    // Always try to read output regardless of exit status
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""

                    // pluginkit output format: "+    com.bundle.id(version)" for enabled
                    // The "+" prefix indicates the extension is enabled
                    // The "-" prefix indicates the extension is disabled
                    for line in output.components(separatedBy: .newlines) {
                        if line.contains("com.stianlars1.dotViewer.QuickLookPreview") {
                            foundInPluginkit = true
                            let trimmed = line.trimmingCharacters(in: .whitespaces)
                            isEnabled = trimmed.hasPrefix("+")
                            break
                        }
                    }
                }
            } catch {
                print("[dotViewer] pluginkit error: \(error)")
            }

            // Method 2: Fallback - ONLY use if pluginkit didn't find our extension at all
            // This handles cases where the app is installed but not yet registered with pluginkit
            // If pluginkit explicitly reported disabled ("-"), we trust that result
            if !foundInPluginkit {
                let extensionPath = Bundle.main.bundlePath + "/Contents/PlugIns/QuickLookPreview.appex"
                if FileManager.default.fileExists(atPath: extensionPath) {
                    // Extension bundle exists - assume it's enabled until pluginkit catches up
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
