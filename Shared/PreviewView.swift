import SwiftUI

struct PreviewView: View {
    let content: AttributedString
    let fileName: String
    let language: String?
    let lineCount: Int
    let fileSize: String

    @State private var showLineNumbers = true

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HeaderBar(
                fileName: fileName,
                language: language,
                lineCount: lineCount,
                fileSize: fileSize
            )

            // Code content
            CodeContentView(
                content: content,
                showLineNumbers: showLineNumbers,
                lineCount: lineCount
            )
        }
        .background(ThemeManager.shared.backgroundColor)
    }
}

struct HeaderBar: View {
    let fileName: String
    let language: String?
    let lineCount: Int
    let fileSize: String

    var body: some View {
        HStack(spacing: 12) {
            // File icon and name
            HStack(spacing: 8) {
                Image(systemName: iconForLanguage(language))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(fileName)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }

            Spacer()

            // Language badge
            if let lang = language {
                Text(LanguageDetector.displayName(for: lang))
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
            }

            // File info
            HStack(spacing: 8) {
                Text("\(lineCount) lines")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if !fileSize.isEmpty {
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text(fileSize)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }

    private func iconForLanguage(_ language: String?) -> String {
        guard let lang = language else { return "doc.text" }

        switch lang {
        case "javascript", "typescript":
            return "curlybraces"
        case "python":
            return "chevron.left.forwardslash.chevron.right"
        case "swift":
            return "swift"
        case "html", "xml":
            return "chevron.left.slash.chevron.right"
        case "css", "scss":
            return "paintbrush"
        case "json", "yaml":
            return "list.bullet.rectangle"
        case "markdown":
            return "text.justify"
        case "bash", "shell":
            return "terminal"
        case "sql":
            return "cylinder"
        case "dockerfile":
            return "shippingbox"
        default:
            return "doc.text"
        }
    }
}

struct CodeContentView: View {
    let content: AttributedString
    let showLineNumbers: Bool
    let lineCount: Int

    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                HStack(alignment: .top, spacing: 0) {
                    // Line numbers
                    if showLineNumbers {
                        LineNumbersView(lineCount: lineCount)
                    }

                    // Code content
                    Text(content)
                        .font(.system(size: ThemeManager.shared.fontSize, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(minWidth: geometry.size.width - (showLineNumbers ? 60 : 0), alignment: .topLeading)
                }
            }
        }
    }
}

struct LineNumbersView: View {
    let lineCount: Int

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(1...max(lineCount, 1), id: \.self) { lineNumber in
                Text("\(lineNumber)")
                    .font(.system(size: ThemeManager.shared.fontSize, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(height: ThemeManager.shared.fontSize * 1.4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(ThemeManager.shared.backgroundColor.opacity(0.5))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundStyle(.separator),
            alignment: .trailing
        )
    }
}

// Preview for development
#Preview {
    PreviewView(
        content: AttributedString("""
        import SwiftUI

        struct ContentView: View {
            var body: some View {
                Text("Hello, World!")
                    .padding()
            }
        }
        """),
        fileName: "ContentView.swift",
        language: "swift",
        lineCount: 10,
        fileSize: "1.2 KB"
    )
    .frame(width: 600, height: 400)
}
