import SwiftUI
import AppKit
import Shared
import OSLog

struct StatusView: View {
    @StateObject private var helper = ExtensionHelper.shared
    @State private var extensionStatus: ExtensionStatus = .checking
    @State private var conflicts: [QLExtensionInfo] = []
    @State private var staleRegistrations: [QLExtensionInfo] = []
    @State private var isScanning = true
    @State private var scanError: String?
    private let statusLogger = Logger(subsystem: "com.stianlars1.dotViewer", category: "ExtensionStatus")
    @State private var resolveResult: String?
    @State private var resolveFailed = false
    @State private var pointer = PointerLocation()
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    AnimatedLogoView(size: 96, pointer: pointer)
                    Text("dotViewer")
                        .fontWeight(.bold)
                        .appFont(.largeTitle)
                    Text("Quick Look for dotfiles, source code & markdown")
                        .appFont(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                VStack(spacing: 16) {
                    
                    Group {
                        if extensionStatus == .disabled {
                            
                            HStack(spacing: 12) {
                                Image(systemName: "puzzlepiece.extension")
                                    .appFont(.title2)
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Enable Quick Look Extension")
                                        .appFont(.headline)
                                    Text("Follow these steps to enable dotViewer")
                                        .appFont(.caption)
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
                                .appFont(.headline)
                            Text(extensionStatus.description)
                                .appFont(.caption)
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
                        .disabled(extensionStatus == .checking)

                        
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                    if case .disabled = extensionStatus {
                        setupSteps
                        openSettingsButton
                    }
                }
                .frame(maxWidth: 420 * textScale)

                VStack(spacing: 16) {
                    Text("Quick Stats")
                        .appFont(.headline)

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

                extensionConflictsSection

                VStack(alignment: .leading, spacing: 12) {
                    Text("How to Use")
                        .appFont(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        HowToRow(number: 1, text: "Select any code file in Finder")
                        HowToRow(number: 2, text: "Press Space to Quick Look")
                        HowToRow(number: 3, text: "View syntax-highlighted preview")
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .frame(maxWidth: 420 * textScale)

                Spacer(minLength: 20)

                HStack {
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "_x.x")")
                        .appFont(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Link(destination: URL(string: "https://github.com/stianlars1/dotViewer")!) {
                        Label("GitHub", systemImage: "arrow.up.right.square")
                            .appFont(.caption)
                    }
                }
                .frame(maxWidth: 420 * textScale)
            }
            .padding(32)
        }
        // The logo looks at the pointer anywhere on the page, like the site's hero.
        .onContinuousHover(coordinateSpace: .global) { phase in
            switch phase {
            case .active(let location): pointer.point = location
            case .ended: pointer.point = nil
            }
        }
        .navigationTitle("Status")
        .onAppear {
            Task { await checkExtensionStatus() }
            Task { await scanForConflicts() }
        }
    }
}

private extension StatusView {
    @ViewBuilder
    var statusIcon: some View {
        ZStack {
            Circle()
                .fill(extensionStatus.backgroundColor)
                .frame(width: 56 * textScale, height: 56 * textScale)

            Image(systemName: extensionStatus.icon)
                .appFont(size: 24)
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

    @MainActor
    func scanForConflicts() async {
        isScanning = true
        scanError = nil
        defer { isScanning = false }
        do {
            let all = try await ExtensionConflictScanner.shared.scanPreviewExtensions()
            withAnimation {
                conflicts = all.filter { $0.isThirdPartyConflict }
                #if DEBUG
                staleRegistrations = all.filter { $0.isDotViewer && !$0.path.hasPrefix("/Applications/dotViewer.app") }
                #else
                staleRegistrations = []
                #endif
            }
            statusLogger.info("Conflict scan completed: \(conflicts.count) competing extensions")
        } catch {
            scanError = "Could not check extension conflicts. Try again."
            statusLogger.error("Conflict scan failed or timed out")
        }
    }

    @ViewBuilder
    var extensionConflictsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Extension Conflicts")
                    .appFont(.headline)

                Spacer()

                Button {
                    Task { await scanForConflicts() }
                } label: {
                    if isScanning {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderless)
                .help("Rescan for conflicts")
                .disabled(isScanning)
            }

            VStack(alignment: .leading, spacing: 12) {
                if isScanning {
                    Label("Checking extension conflicts…", systemImage: "hourglass")
                        .foregroundStyle(.secondary)
                } else if let scanError {
                    Label(scanError, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                } else if conflicts.isEmpty && staleRegistrations.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .appFont(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No conflicts detected")
                                .fontWeight(.medium)
                                .appFont(.subheadline)
                            Text("dotViewer has priority for all its registered file types.")
                                .appFont(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    if !conflicts.isEmpty {
                        Text("These Quick Look extensions may override dotViewer for some file types:")
                            .appFont(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(conflicts) { ext in
                            conflictRow(ext)
                        }

                        Button {
                            Task {
                                resolveFailed = false
                                do {
                                    let count = try await ExtensionConflictScanner.shared.resolveAllConflicts()
                                    resolveResult = "Disabled \(count) conflicting extension\(count == 1 ? "" : "s")."
                                } catch {
                                    resolveFailed = true
                                    resolveResult = "Could not resolve extension conflicts. Try again."
                                }
                                await scanForConflicts()
                                await checkExtensionStatus()
                            }
                        } label: {
                            Label("Resolve All — Prefer dotViewer", systemImage: "wand.and.stars")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }

                    if !staleRegistrations.isEmpty {
                        if !conflicts.isEmpty { Divider() }

                        Text("Old dotViewer registrations from previous builds:")
                            .appFont(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(staleRegistrations) { ext in
                            staleRow(ext)
                        }

                        Button {
                            Task {
                                for ext in staleRegistrations {
                                    // By path — the bundle id is shared with the installed build,
                                    // so removing by id could unregister the working extension.
                                    await ExtensionConflictScanner.shared
                                        .removeRegistration(atPath: ext.path)
                                }
                                await scanForConflicts()
                            }
                        } label: {
                            Label("Clean Up Stale Registrations", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                }

                if let result = resolveResult {
                    Text(result)
                        .appFont(.caption)
                        .foregroundStyle(resolveFailed ? .orange : .green)
                        .transition(.opacity)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: 420 * textScale)
    }

    func conflictRow(_ ext: QLExtensionInfo) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .appFont(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text(ext.appName)
                    .fontWeight(.medium)
                    .appFont(.subheadline)
                Text(ext.id)
                    .appFont(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            Button("Disable") {
                Task {
                    await ExtensionConflictScanner.shared.disableExtension(ext.id)
                    await scanForConflicts()
                }
            }
            .controlSize(.small)
            .buttonStyle(.bordered)
        }
    }

    func staleRow(_ ext: QLExtensionInfo) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.gray)
                .appFont(.body)

            VStack(alignment: .leading, spacing: 2) {
                Text("dotViewer \(ext.version)")
                    .appFont(.subheadline)
                Text(ext.path)
                    .appFont(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }

            Spacer()
        }
    }
}

private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .appFont(.title2)
                .foregroundStyle(color)

            Text(value)
                .fontWeight(.bold)
                .appFont(.title)

            Text(label)
                .appFont(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 100 * textScale)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct HowToRow: View {
    let number: Int
    let text: String
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .fontWeight(.bold)
                .appFont(.caption)
                .foregroundStyle(.white)
                .frame(width: 20 * textScale, height: 20 * textScale)
                .background(.blue, in: Circle())

            Text(text)
                .appFont(.subheadline)
        }
    }
}

private struct SetupStepRow: View {
    let step: Int
    let text: String
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(step)")
                .fontWeight(.bold)
                .appFont(.caption)
                .foregroundStyle(.white)
                .frame(width: 20 * textScale, height: 20 * textScale)
                .background(.blue, in: Circle())

            Text(text)
                .appFont(.subheadline)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    StatusView()
}
