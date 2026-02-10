import SwiftUI
import Shared

struct SettingsView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedTheme: String = SharedSettings.shared.selectedTheme
    @State private var fontSize: Double = SharedSettings.shared.fontSize
    @State private var showLineNumbers: Bool = SharedSettings.shared.showLineNumbers
    @State private var wordWrap: Bool = SharedSettings.shared.wordWrap
    @State private var maxFileSize: Double = Double(SharedSettings.shared.maxFileSizeBytes) / 1000.0
    @State private var showTruncationWarning: Bool = SharedSettings.shared.showTruncationWarning
    @State private var showPreviewHeader: Bool = SharedSettings.shared.showFileInfoHeader
    @State private var previewUnknownFiles: Bool = SharedSettings.shared.previewAllFileTypes
    @State private var forceTextForUnknown: Bool = SharedSettings.shared.previewForceTextForUnknown

    @State private var performanceLoggingEnabled: Bool = SharedSettings.shared.performanceLoggingEnabled
    @State private var previewCacheEnabled: Bool = SharedSettings.shared.previewCacheEnabled
    @State private var previewCacheMaxMB: Double = Double(SharedSettings.shared.previewCacheMaxMB)
    @State private var previewCacheTTLSeconds: Double = Double(SharedSettings.shared.previewCacheTTLSeconds)
    @State private var copyBehavior: String = SharedSettings.shared.copyBehavior

    private let copyBehaviors: [(String, String, String)] = [
        ("autoCopy", "Auto-copy", "Copies text to clipboard when you release the mouse after selecting."),
        ("floatingButton", "Floating copy button", "A small Copy button appears near your selection — click it to copy."),
        ("toastAction", "Toast with copy button", "A toast notification appears with a Copy button to confirm."),
        ("tapToCopy", "Tap to confirm", "Select text, then tap anywhere to copy it. Two-step confirmation."),
        ("holdToCopy", "Hold-to-copy", "Only copies when you hold the mouse for more than 500ms while selecting."),
        ("shakeToCopy", "Shake to copy", "Select text, then shake your mouse left-right to copy."),
        ("autoCopyUndo", "Auto-copy with undo", "Auto-copies on selection with a 3-second Undo button in the toast."),
        ("off", "Off", "No automatic copy behavior. Use the header button or right-click to copy."),
    ]

    private let themes: [(String, String)] = [
        ("auto", "Auto (System)"),
        ("atomOneLight", "Atom One Light"),
        ("atomOneDark", "Atom One Dark"),
        ("githubLight", "GitHub Light"),
        ("githubDark", "GitHub Dark"),
        ("xcodeLight", "Xcode Light"),
        ("xcodeDark", "Xcode Dark"),
        ("solarizedLight", "Solarized Light"),
        ("solarizedDark", "Solarized Dark"),
        ("tokyoNight", "Tokyo Night"),
        ("blackout", "Blackout"),
    ]

    private var palette: ThemePalette {
        ThemePalette.palette(for: selectedTheme, systemIsDark: colorScheme == .dark)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Appearance")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Theme", selection: $selectedTheme) {
                            ForEach(themes, id: \.0) { theme in
                                Text(theme.1).tag(theme.0)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedTheme) { _, newValue in
                            SharedSettings.shared.selectedTheme = newValue
                        }

                        HStack {
                            Text("Font Size")
                            Spacer()
                            Text("\(Int(fontSize))pt")
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $fontSize, in: 10...24, step: 1)
                            .onChange(of: fontSize) { _, newValue in
                                SharedSettings.shared.fontSize = newValue
                            }

                        Toggle("Show Line Numbers", isOn: $showLineNumbers)
                            .onChange(of: showLineNumbers) { _, newValue in
                                SharedSettings.shared.showLineNumbers = newValue
                            }

                        Toggle("Word Wrap", isOn: $wordWrap)
                            .onChange(of: wordWrap) { _, newValue in
                                SharedSettings.shared.wordWrap = newValue
                            }

                        Text("Wrap long lines instead of horizontal scrolling")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

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

                        Slider(value: $maxFileSize, in: 10...500, step: 10)
                            .onChange(of: maxFileSize) { _, newValue in
                                SharedSettings.shared.maxFileSizeBytes = Int(newValue * 1000)
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

                VStack(alignment: .leading, spacing: 16) {
                    Text("Preview UI")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Show File Info Header", isOn: $showPreviewHeader)
                            .onChange(of: showPreviewHeader) { _, newValue in
                                SharedSettings.shared.showFileInfoHeader = newValue
                            }

                        Text("Shows filename, language, line count, and file size in preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        Picker("Copy Behavior", selection: $copyBehavior) {
                            ForEach(copyBehaviors, id: \.0) { behavior in
                                Text(behavior.1).tag(behavior.0)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: copyBehavior) { _, newValue in
                            SharedSettings.shared.copyBehavior = newValue
                        }

                        Text(copyBehaviors.first(where: { $0.0 == copyBehavior })?.2 ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Divider()

                        Toggle("Preview All File Types", isOn: $previewUnknownFiles)
                            .onChange(of: previewUnknownFiles) { _, newValue in
                                SharedSettings.shared.previewAllFileTypes = newValue
                            }

                        Text("Preview files with extensions not in the built-in registry")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Toggle("Force Text Preview for Unknown Files", isOn: $forceTextForUnknown)
                            .onChange(of: forceTextForUnknown) { _, newValue in
                                SharedSettings.shared.previewForceTextForUnknown = newValue
                            }

                        Text("Treat files without a text MIME type as plain text if they contain readable bytes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Performance & Cache")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable Performance Logging", isOn: $performanceLoggingEnabled)
                            .onChange(of: performanceLoggingEnabled) { _, newValue in
                                SharedSettings.shared.performanceLoggingEnabled = newValue
                            }

                        Toggle("Enable Preview Cache", isOn: $previewCacheEnabled)
                            .onChange(of: previewCacheEnabled) { _, newValue in
                                SharedSettings.shared.previewCacheEnabled = newValue
                            }

                        HStack {
                            Text("Cache TTL")
                            Spacer()
                            Text("\(Int(previewCacheTTLSeconds))s")
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $previewCacheTTLSeconds, in: 5...600, step: 5)
                            .onChange(of: previewCacheTTLSeconds) { _, newValue in
                                SharedSettings.shared.previewCacheTTLSeconds = Int(newValue)
                            }

                        HStack {
                            Text("Cache Size Limit")
                            Spacer()
                            Text("\(Int(previewCacheMaxMB)) MB")
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $previewCacheMaxMB, in: 10...500, step: 10)
                            .onChange(of: previewCacheMaxMB) { _, newValue in
                                SharedSettings.shared.previewCacheMaxMB = Int(newValue)
                            }

                        Button {
                            SharedSettings.shared.previewCacheClearRequested = true
                        } label: {
                            Label("Clear Preview Cache", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Theme Preview")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 0) {
                        Text("// Example code preview")
                            .font(.system(size: fontSize, design: .monospaced))
                            .foregroundStyle(Color(hex: palette.comment))

                        Text("func greet(name: String) -> String {")
                            .font(.system(size: fontSize, design: .monospaced))
                            .foregroundStyle(Color(hex: palette.text))

                        Text("    return \"Hello, \\(name)!\"")
                            .font(.system(size: fontSize, design: .monospaced))
                            .foregroundStyle(Color(hex: palette.string))

                        Text("}")
                            .font(.system(size: fontSize, design: .monospaced))
                            .foregroundStyle(Color(hex: palette.text))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: palette.background), in: RoundedRectangle(cornerRadius: 12))
                }

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
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
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

#Preview {
    SettingsView()
}
