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
    @StateObject private var helper = ExtensionHelper.shared

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

                // Setup Guide Card
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "puzzlepiece.extension")
                            .font(.title2)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Enable Quick Look Extension")
                                .font(.headline)
                            Text("Follow these steps to enable dotViewer")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                    // Setup steps
                    VStack(alignment: .leading, spacing: 10) {
                        SetupStepRow(
                            step: 1,
                            text: "Click \"Open Extension Settings\" below"
                        )
                        SetupStepRow(
                            step: 2,
                            text: "Click \"Quick Look\" in the sidebar"
                        )
                        SetupStepRow(
                            step: 3,
                            text: "Enable \"dotViewer\" checkbox"
                        )
                        SetupStepRow(
                            step: 4,
                            text: "Try previewing a code file with Space in Finder"
                        )
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))

                    Button {
                        helper.openExtensionSettings()
                    } label: {
                        Label("Open Extension Settings", systemImage: "gear")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .frame(maxWidth: 400)

                // Quick Stats
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

struct SetupStepRow: View {
    let step: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(step)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(.blue, in: Circle())

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject private var themeManager = ThemeManager.shared
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
