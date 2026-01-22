import SwiftUI

/// Native markdown renderer using SwiftUI Text with AttributedString
/// Much simpler than WKWebView - no JavaScript, no bundle loading issues
struct MarkdownWebView: View {
    let markdown: String
    let baseURL: URL?
    let fontSize: Double

    @State private var attributedContent: AttributedString?
    @State private var parseError: String?

    var body: some View {
        ScrollView {
            if let error = parseError {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Markdown parsing error")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Divider()
                    Text(markdown)
                        .font(.system(size: fontSize, design: .monospaced))
                        .textSelection(.enabled)
                }
                .padding()
            } else if let content = attributedContent {
                Text(content)
                    .font(.system(size: fontSize))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            } else {
                // Fallback: show raw markdown while parsing
                Text(markdown)
                    .font(.system(size: fontSize, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .background(backgroundColor)
        .onAppear {
            parseMarkdown()
        }
    }

    private var backgroundColor: Color {
        ThemeManager.shared.backgroundColor
    }

    private func parseMarkdown() {

        do {
            // Use Apple's native AttributedString markdown parser
            var options = AttributedString.MarkdownParsingOptions()
            options.interpretedSyntax = .inlineOnlyPreservingWhitespace

            // Try full parsing first
            let parsed = try AttributedString(
                markdown: markdown,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .full,
                    failurePolicy: .returnPartiallyParsedIfPossible
                )
            )

            // Apply styling
            var styled = parsed
            // Set base font
            styled.font = .system(size: fontSize)

            attributedContent = styled

        } catch {
            perfLog("[MarkdownWebView] Markdown parsing failed: \(error.localizedDescription)")
            // On error, try simpler inline-only parsing
            do {
                let simpleParsed = try AttributedString(
                    markdown: markdown,
                    options: AttributedString.MarkdownParsingOptions(
                        interpretedSyntax: .inlineOnlyPreservingWhitespace,
                        failurePolicy: .returnPartiallyParsedIfPossible
                    )
                )
                attributedContent = simpleParsed
            } catch {
                // If all parsing fails, show raw text
                parseError = error.localizedDescription
            }
        }
    }
}

// MARK: - Alternative: Rich Markdown View with better styling

/// A more feature-rich markdown view that handles common elements better
struct RichMarkdownView: View {
    let markdown: String
    let fontSize: Double

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(parseLines(), id: \.self) { line in
                    renderLine(line)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(ThemeManager.shared.backgroundColor)
    }

    private func parseLines() -> [String] {
        markdown.components(separatedBy: "\n")
    }

    @ViewBuilder
    private func renderLine(_ line: String) -> some View {
        if line.hasPrefix("# ") {
            Text(line.dropFirst(2))
                .font(.system(size: fontSize * 2, weight: .bold))
                .padding(.top, 8)
        } else if line.hasPrefix("## ") {
            Text(line.dropFirst(3))
                .font(.system(size: fontSize * 1.5, weight: .bold))
                .padding(.top, 6)
        } else if line.hasPrefix("### ") {
            Text(line.dropFirst(4))
                .font(.system(size: fontSize * 1.25, weight: .semibold))
                .padding(.top, 4)
        } else if line.hasPrefix("- ") || line.hasPrefix("* ") {
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                Text(parseInlineMarkdown(String(line.dropFirst(2))))
            }
            .font(.system(size: fontSize))
        } else if line.hasPrefix("```") {
            // Code block marker - simplified handling
            Text(line)
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundColor(.secondary)
        } else if line.hasPrefix(">") {
            Text(parseInlineMarkdown(String(line.dropFirst(1).trimmingCharacters(in: .whitespaces))))
                .font(.system(size: fontSize, weight: .regular).italic())
                .padding(.leading, 16)
                .overlay(
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 4),
                    alignment: .leading
                )
        } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
            Spacer().frame(height: 8)
        } else {
            Text(parseInlineMarkdown(line))
                .font(.system(size: fontSize))
        }
    }

    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        // Try to parse inline markdown (bold, italic, code, links)
        do {
            return try AttributedString(
                markdown: text,
                options: AttributedString.MarkdownParsingOptions(
                    interpretedSyntax: .inlineOnlyPreservingWhitespace
                )
            )
        } catch {
            return AttributedString(text)
        }
    }
}
