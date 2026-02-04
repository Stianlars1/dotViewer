import SwiftUI
import AppKit
import Shared

struct StatusView: View {
    @StateObject private var helper = ExtensionHelper.shared
    @State private var extensionStatus: ExtensionStatus = .checking

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue.gradient)
                        .modifier(BounceEffectModifierFallback())
                    Text("dotViewer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Quick Look for dotfiles, source code & markdown")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                VStack(spacing: 16) {
                    
                    Group {
                        if extensionStatus != .enabled && extensionStatus != .checking  {
                            
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
                        }
                    }

                    HStack(spacing: 16) {
                        statusIcon

                        VStack(alignment: .leading, spacing: 4) {
                            Text(extensionStatus.title)
                                .font(.headline)
                            Text(extensionStatus.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            Task { await checkExtensionStatus() }
                        } label: {
                            if .checking == extensionStatus {
                                Image(systemName: "progress.indicator")
                                    .symbolEffect(.variableColor.iterative.hideInactiveLayers.nonReversing, options: .repeat(.continuous))
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .buttonStyle(.borderless)
                        .help("Refresh status")

                        
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                    if case .disabled = extensionStatus {
                        setupSteps
                        openSettingsButton
                    } else if case .error = extensionStatus {
                        setupSteps
                        openSettingsButton
                    }
                }
                .frame(maxWidth: 420)

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
                .frame(maxWidth: 420)

                Spacer(minLength: 20)

                HStack {
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "_x.x")")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Link(destination: URL(string: "https://github.com/stianlars1/dotViewer")!) {
                        Label("GitHub", systemImage: "arrow.up.right.square")
                            .font(.caption)
                    }
                }
                .frame(maxWidth: 420)
            }
            .padding(32)
        }
        .navigationTitle("Status")
        .onAppear {
            Task { await checkExtensionStatus() }
        }
    }
}

private extension StatusView {
    @ViewBuilder
    var statusIcon: some View {
        ZStack {
            Circle()
                .fill(extensionStatus.backgroundColor)
                .frame(width: 56, height: 56)

            Image(systemName: extensionStatus.icon)
                .font(.system(size: 24))
                .foregroundStyle(extensionStatus.iconColor)
                .symbolEffect(.pulse, options: .repeating, isActive: extensionStatus == .checking)
        }
    }

    var setupSteps: some View {
        VStack(alignment: .leading, spacing: 10) {
            SetupStepRow(step: 1, text: "Click \"Open Extension Settings\" below")
            SetupStepRow(step: 2, text: "Click \"Quick Look\" in the sidebar")
            SetupStepRow(step: 3, text: "Enable \"dotViewer\" checkbox")
            SetupStepRow(step: 4, text: "Try previewing a code file with Space in Finder")
        }
        .padding()
        .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    var openSettingsButton: some View {
        Button {
            helper.openExtensionSettings()
        } label: {
            Label("Open Extension Settings", systemImage: "gear")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    @MainActor
    func checkExtensionStatus() async {
        extensionStatus = .checking
        try? await Task.sleep(for: .milliseconds(500))

        let status = await ExtensionStatusChecker.shared.checkStatus()
        withAnimation {
            extensionStatus = status
        }
    }
}

private struct StatCard: View {
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

private struct HowToRow: View {
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

private struct SetupStepRow: View {
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

@available(macOS 15.0, *)
private struct BounceEffectModifier: ViewModifier {
    @State private var didAppear = false

    func body(content: Content) -> some View {
        content
            .symbolEffect(.bounce.up.byLayer, options: .nonRepeating, value: didAppear)
            .onAppear { didAppear = true }
    }
}

private struct BounceEffectModifierFallback: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content.modifier(BounceEffectModifier())
        } else {
            content
        }
    }
}

#Preview {
    StatusView()
}
