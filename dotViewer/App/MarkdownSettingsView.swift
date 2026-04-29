import SwiftUI
import Shared

struct MarkdownSettingsView: View {
    @State private var defaultMode: String = SharedSettings.shared.markdownDefaultMode
    @State private var showInlineImages: Bool = SharedSettings.shared.markdownShowInlineImages
    @State private var useSyntaxHighlightInRaw: Bool = SharedSettings.shared.markdownUseSyntaxHighlightInRaw
    @State private var showTOC: Bool = SharedSettings.shared.markdownShowTOC
    @State private var tocDefaultOpen: Bool = SharedSettings.shared.markdownTOCDefaultOpen
    @State private var renderFontSize: Double = SharedSettings.shared.markdownRenderFontSize
    @State private var renderedFontFamilyName: String = SharedSettings.shared.markdownRenderedFontFamilyName
    @State private var renderedWidthMode: String = SharedSettings.shared.markdownRenderedWidthMode
    @State private var renderedCustomMaxWidth: Double = Double(SharedSettings.shared.markdownRenderedCustomMaxWidth)
    @State private var renderedContentAlignment: String = SharedSettings.shared.markdownRenderedContentAlignment
    @State private var showRenderedAlignmentAdvanced: Bool = false
    @State private var syncFontSizes: Bool = SharedSettings.shared.syncFontSizes
    @State private var customCSS: String = SharedSettings.shared.markdownCustomCSS
    @State private var customCSSOverride: Bool = SharedSettings.shared.markdownCustomCSSOverride
    private let renderedFontFamilies = PreviewFontMenu.renderedFontFamilies

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

                        Toggle("Enable Table of Contents Button", isOn: $showTOC)
                            .onChange(of: showTOC) { _, newValue in
                                SharedSettings.shared.markdownShowTOC = newValue
                            }

                        Text("Adds a TOC button to the rendered header. You can still hide the panel by default.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if showTOC {
                            Picker("TOC Default", selection: $tocDefaultOpen) {
                                Text("Open").tag(true)
                                Text("Hidden").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: tocDefaultOpen) { _, newValue in
                                SharedSettings.shared.markdownTOCDefaultOpen = newValue
                            }

                            Text("Controls whether the table of contents opens by default in rendered previews.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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

                        Divider()

                        Picker("Rendered Font", selection: $renderedFontFamilyName) {
                            ForEach(renderedFontFamilies, id: \.self) { family in
                                Text(PreviewFontMenu.title(for: family)).tag(family)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: renderedFontFamilyName) { _, newValue in
                            SharedSettings.shared.markdownRenderedFontFamilyName = newValue
                        }

                        HStack {
                            Text("Used by rendered Markdown prose and rich text previews. Inline code still uses the code font.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button("Reset") {
                                renderedFontFamilyName = PreviewFontFamily.defaultMarkdownRenderedFamily
                                SharedSettings.shared.markdownRenderedFontFamilyName = PreviewFontFamily.defaultMarkdownRenderedFamily
                            }
                            .controlSize(.small)
                        }

                        Divider()

                        Picker("Rendered Width", selection: $renderedWidthMode) {
                            Text("Auto").tag("auto")
                            Text("Custom").tag("custom")
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: renderedWidthMode) { _, newValue in
                            SharedSettings.shared.markdownRenderedWidthMode = newValue
                        }

                        if renderedWidthMode == "custom" {
                            HStack {
                                Text("Max Width")
                                Spacer()
                                Text("\(Int(renderedCustomMaxWidth))px")
                                    .foregroundStyle(.secondary)
                            }

                            Slider(value: $renderedCustomMaxWidth, in: 480...2400, step: 10)
                                .onChange(of: renderedCustomMaxWidth) { _, newValue in
                                    SharedSettings.shared.markdownRenderedCustomMaxWidth = Int(newValue)
                                }
                        }

                        Text("Auto uses the built-in rendered markdown layout width.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        DisclosureGroup("Content Alignment (Advanced)", isExpanded: $showRenderedAlignmentAdvanced) {
                            VStack(alignment: .leading, spacing: 12) {
                                Picker("Rendered Alignment", selection: $renderedContentAlignment) {
                                    Text("Left").tag("left")
                                    Text("Center").tag("center")
                                    Text("Right").tag("right")
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: renderedContentAlignment) { _, newValue in
                                    SharedSettings.shared.markdownRenderedContentAlignment = newValue
                                }
                            }
                            .padding(.top, 8)
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
            renderedFontFamilyName = SharedSettings.shared.markdownRenderedFontFamilyName
            renderedWidthMode = SharedSettings.shared.markdownRenderedWidthMode
            renderedCustomMaxWidth = Double(SharedSettings.shared.markdownRenderedCustomMaxWidth)
            renderedContentAlignment = SharedSettings.shared.markdownRenderedContentAlignment
            tocDefaultOpen = SharedSettings.shared.markdownTOCDefaultOpen
        }
    }
}

#Preview {
    MarkdownSettingsView()
}
