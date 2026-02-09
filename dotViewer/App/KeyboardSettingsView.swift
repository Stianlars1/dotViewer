import SwiftUI
import Shared

struct KeyboardSettingsView: View {
    @EnvironmentObject private var copyHelper: CopyHelperManager
    @State private var copyHelperEnabled: Bool = SharedSettings.shared.copyHelperEnabled

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Clipboard")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable Cmd+C in Quick Look Previews", isOn: $copyHelperEnabled)
                            .onChange(of: copyHelperEnabled) { _, newValue in
                                SharedSettings.shared.copyHelperEnabled = newValue
                                if newValue {
                                    copyHelper.launch()
                                } else {
                                    copyHelper.stop()
                                }
                            }

                        statusRow

                        if copyHelper.status == .needsPermission {
                            Button {
                                copyHelper.openAccessibilitySettings()
                            } label: {
                                Label("Open Accessibility Settings", systemImage: "lock.shield")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.regular)
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("How It Works")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        explanation(
                            icon: "keyboard",
                            title: "The Problem",
                            text: "Quick Look intercepts Cmd+C before it reaches the preview content. This is a macOS platform limitation affecting all Quick Look extensions."
                        )

                        Divider()

                        explanation(
                            icon: "hammer",
                            title: "The Solution",
                            text: "A small background helper monitors keyboard events. When Cmd+C is pressed while a Quick Look preview is visible, it reads the selected text via the Accessibility API and copies it to the clipboard."
                        )

                        Divider()

                        explanation(
                            icon: "lock.shield",
                            title: "Accessibility Permission",
                            text: "The helper requires Accessibility permission to read selected text from Quick Look windows. This permission is only used when Quick Look is active — all other Cmd+C events pass through unchanged."
                        )

                        Divider()

                        explanation(
                            icon: "arrow.counterclockwise",
                            title: "Auto-Cleanup",
                            text: "The helper automatically terminates when dotViewer quits. It only runs while dotViewer is open and the feature is enabled."
                        )
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                Spacer()
            }
            .padding(32)
        }
        .navigationTitle("Keyboard")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var statusRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        switch copyHelper.status {
        case .running: return .green
        case .needsPermission: return .yellow
        case .error: return .red
        case .stopped: return .gray
        }
    }

    private var statusText: String {
        switch copyHelper.status {
        case .running: return "Helper is running"
        case .needsPermission: return "Accessibility permission required"
        case .error(let msg): return "Error: \(msg)"
        case .stopped: return "Helper is not running"
        }
    }

    private func explanation(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
