import Foundation

/// Conservative disambiguation for .gd: recognize GAP declarations or assignment/block syntax.
/// Godot signatures win, and comments/string literals cannot supply GAP evidence.
enum GAPSourceDetector {
    static func matches(_ sample: String) -> Bool {
        let code = codeOutsideLiterals(sample)
        if code.range(of: #"(?m)^\s*(extends|class_name|func|signal|var|const)\b|^\s*@(export|onready|tool)\b"#, options: .regularExpression) != nil {
            return false
        }
        if code.range(of: #"(?m)^\s*(Declare|Install)[A-Z][A-Za-z0-9_]*\s*\("#, options: .regularExpression) != nil {
            return true
        }
        return code.contains(":=") && code.range(of: #"\b(fi|od|end)\s*;"#, options: .regularExpression) != nil
    }

    private static func codeOutsideLiterals(_ source: String) -> String {
        let bytes = Array(source.utf8.prefix(32_768))
        var result = bytes
        var index = 0
        func blank(_ position: Int) {
            if bytes[position] != 10 && bytes[position] != 13 { result[position] = 32 }
        }
        while index < bytes.count {
            if bytes[index] == 35 {
                while index < bytes.count, bytes[index] != 10 { blank(index); index += 1 }
            } else if bytes[index] == 34 || bytes[index] == 39 {
                let quote = bytes[index]
                let width = index + 2 < bytes.count && bytes[index + 1] == quote && bytes[index + 2] == quote ? 3 : 1
                for _ in 0..<width { blank(index); index += 1 }
                while index < bytes.count {
                    if bytes[index] == 92 {
                        blank(index); index += 1
                        if index < bytes.count { blank(index); index += 1 }
                    } else if bytes[index] == quote && (width == 1 || (index + 2 < bytes.count && bytes[index + 1] == quote && bytes[index + 2] == quote)) {
                        for _ in 0..<width { blank(index); index += 1 }
                        break
                    } else { blank(index); index += 1 }
                }
            } else { index += 1 }
        }
        return String(decoding: result, as: UTF8.self)
    }
}
