import SwiftUI
import Shared

struct MarkdownSettingsView: View {
    @State private var defaultMode: String = SharedSettings.shared.markdownDefaultMode
    @State private var showInlineImages: Bool = SharedSettings.shared.markdownShowInlineImages
    @State private var useSyntaxHighlightInRaw: Bool = SharedSettings.shared.markdownUseSyntaxHighlightInRaw
    @State private var showTOC: Bool = SharedSettings.shared.markdownShowTOC
    @State private var renderFontSize: Double = SharedSettings.shared.markdownRenderFontSize
    @State private var syncFontSizes: Bool = SharedSettings.shared.syncFontSizes
    @State private var customCSS: String = SharedSettings.shared.markdownCustomCSS
    @State private var customCSSOverride: Bool = SharedSettings.shared.markdownCustomCSSOverride

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Markdown Preview")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Default Mode", selection: $defaultMode) {
                            Text("Raw").tag("raw")
                            Text("Rendered").tag("rendered")
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: defaultMode) { _, newValue in
                            SharedSettings.shared.markdownDefaultMode = newValue
                        }

                        Toggle("Show Inline Images", isOn: $showInlineImages)
                            .onChange(of: showInlineImages) { _, newValue in
                                SharedSettings.shared.markdownShowInlineImages = newValue
                            }

                        Toggle("Syntax Highlight in Raw View", isOn: $useSyntaxHighlightInRaw)
                            .onChange(of: useSyntaxHighlightInRaw) { _, newValue in
                                SharedSettings.shared.markdownUseSyntaxHighlightInRaw = newValue
                            }

                        Toggle("Show Table of Contents", isOn: $showTOC)
                            .onChange(of: showTOC) { _, newValue in
                                SharedSettings.shared.markdownShowTOC = newValue
                            }

                        Text("Show a collapsible table of contents in rendered previews")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Rendered View")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Font Size")
                            Spacer()
                            Text("\(Int(renderFontSize))pt")
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $renderFontSize, in: 10...24, step: 1)
                            .disabled(syncFontSizes)
                            .onChange(of: renderFontSize) { _, newValue in
                                SharedSettings.shared.markdownRenderFontSize = newValue
                                if syncFontSizes {
                                    SharedSettings.shared.fontSize = newValue
                                }
                            }

                        if syncFontSizes {
                            Text("Synced with code font size — change in Settings > Appearance")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Applies to rendered Markdown only.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Custom CSS")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Override Built-in Styles", isOn: $customCSSOverride)
                            .onChange(of: customCSSOverride) { _, newValue in
                                SharedSettings.shared.markdownCustomCSSOverride = newValue
                            }

                        Text("Paste CSS that will be applied to rendered Markdown.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $customCSS)
                            .font(.system(.caption, design: .monospaced))
                            .frame(minHeight: 160)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                            .onChange(of: customCSS) { _, newValue in
                                SharedSettings.shared.markdownCustomCSS = newValue
                            }
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(32)
        }
        .navigationTitle("Markdown")
        .onAppear {
            syncFontSizes = SharedSettings.shared.syncFontSizes
            renderFontSize = SharedSettings.shared.markdownRenderFontSize
        }
    }
}

#Preview {
    MarkdownSettingsView()
}
