import Foundation

/// `.gp` is shared with PARI/GP. Require a Gnuplot command, not a math function call.
public enum GnuplotSourceDetector {
    public static func matches(_ source: String) -> Bool {
        source.range(
            of: #"(?m)^\h*(?:(?:splot|plot)\h+[^\s(]|set\h+(?:term(?:inal)?|output|[xyz]range|title|xlabel|ylabel|grid|key)\b|unset\h+(?:key|grid|title)\b)"#,
            options: .regularExpression
        ) != nil
    }
}
