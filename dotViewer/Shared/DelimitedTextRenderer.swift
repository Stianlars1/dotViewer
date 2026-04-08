import Foundation

public enum DelimitedTextKind: String, Sendable {
    case csv
    case tsv

    var delimiter: Character {
        switch self {
        case .csv:
            return ","
        case .tsv:
            return "\t"
        }
    }
}

public struct DelimitedTextPreview: Sendable {
    public let html: String
    public let rowCount: Int
    public let columnCount: Int
    public let isTruncated: Bool
}

public enum DelimitedTextRenderer {
    private static let maxPreviewRows = 200
    private static let maxPreviewColumns = 24

    public static func preview(text: String, kind: DelimitedTextKind) -> DelimitedTextPreview? {
        let rows = parseRows(in: text, delimiter: kind.delimiter)
        guard !rows.isEmpty else { return nil }

        let totalColumns = rows.map(\.count).max() ?? 0
        let previewRows = Array(rows.prefix(maxPreviewRows))
        let cappedColumns = min(totalColumns, maxPreviewColumns)
        let normalizedRows = previewRows.map { row in
            let visible = Array(row.prefix(cappedColumns))
            if visible.count >= cappedColumns {
                return visible
            }
            return visible + Array(repeating: "", count: cappedColumns - visible.count)
        }

        guard let headerRow = normalizedRows.first else { return nil }
        let bodyRows = Array(normalizedRows.dropFirst())
        let isTruncated = rows.count > maxPreviewRows || totalColumns > maxPreviewColumns

        let summaryParts = [
            "\(rows.count) row\(rows.count == 1 ? "" : "s")",
            "\(totalColumns) column\(totalColumns == 1 ? "" : "s")",
        ]

        let truncationNote = isTruncated
            ? "<p class=\"delimited-note\">Showing the first \(min(rows.count, maxPreviewRows)) rows and \(cappedColumns) columns.</p>"
            : ""

        let html = """
        <div class="delimited-preview" data-delimited-kind="\(kind.rawValue)">
          <div class="delimited-summary">\(summaryParts.joined(separator: " • "))</div>
          \(truncationNote)
          <div class="delimited-scroll">
            <table class="delimited-table">
              <thead>
                <tr>\(headerRow.map { "<th>\(escapeHTML($0))</th>" }.joined())</tr>
              </thead>
              <tbody>
                \(bodyRows.map { row in "<tr>\(row.map { "<td>\(escapeHTML($0))</td>" }.joined())</tr>" }.joined())
              </tbody>
            </table>
          </div>
        </div>
        """

        return DelimitedTextPreview(
            html: html,
            rowCount: rows.count,
            columnCount: totalColumns,
            isTruncated: isTruncated
        )
    }

    private static func parseRows(in text: String, delimiter: Character) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false
        var iterator = text.makeIterator()

        while let character = iterator.next() {
            if inQuotes {
                if character == "\"" {
                    if let next = iterator.next() {
                        if next == "\"" {
                            currentField.append("\"")
                        } else {
                            inQuotes = false
                            consume(character: next, delimiter: delimiter, currentField: &currentField, currentRow: &currentRow, rows: &rows)
                        }
                    } else {
                        inQuotes = false
                    }
                } else {
                    currentField.append(character)
                }
                continue
            }

            if character == "\"" {
                inQuotes = true
                continue
            }

            consume(character: character, delimiter: delimiter, currentField: &currentField, currentRow: &currentRow, rows: &rows)
        }

        currentRow.append(currentField)
        if !(currentRow.count == 1 && currentRow[0].isEmpty && rows.isEmpty) {
            rows.append(currentRow)
        }

        if text.hasSuffix("\n"), rows.last == [""] {
            rows.removeLast()
        }

        return rows
    }

    private static func consume(
        character: Character,
        delimiter: Character,
        currentField: inout String,
        currentRow: inout [String],
        rows: inout [[String]]
    ) {
        switch character {
        case delimiter:
            currentRow.append(currentField)
            currentField = ""
        case "\n":
            currentRow.append(currentField)
            rows.append(currentRow)
            currentField = ""
            currentRow = []
        case "\r":
            break
        default:
            currentField.append(character)
        }
    }

    private static func escapeHTML(_ value: String) -> String {
        var escaped = value
        escaped = escaped.replacingOccurrences(of: "&", with: "&amp;")
        escaped = escaped.replacingOccurrences(of: "<", with: "&lt;")
        escaped = escaped.replacingOccurrences(of: ">", with: "&gt;")
        escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;")
        return escaped
    }
}
