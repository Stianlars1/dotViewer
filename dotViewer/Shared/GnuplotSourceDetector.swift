import Foundation

/// `.gp` is shared with PARI/GP, so content decides. A file counts as Gnuplot only when its code,
/// with comments removed, contains something PARI/GP never writes: a Gnuplot command starting a
/// statement, a braced block, a Gnuplot-only variable, or the `**` operator. PARI/GP calls always
/// take parentheses (`plot(X=0,1,f(X))`, `print(x)`, `while(c, …)`), which keeps the two apart.
public enum GnuplotSourceDetector {
    public static func matches(_ source: String) -> Bool {
        let code = stripComments(String(source.prefix(32_768)))
        return signals.contains { code.range(of: $0, options: .regularExpression) != nil }
    }

    /// Everything `set`, `unset` and `show` accept, plus the abbreviations scripts actually use
    /// (`set t push`, `set o "plot.png"`, `set xr [0:1]`).
    private static let options = [
        "(?:[xyz]2?|cb|r|t|u|v)(?:range|label|tics|data|dtics|mtics|zeroaxis)", "m(?:[xyz]2?|cb|r|t)tics",
        "angles", "arrow", "autoscale", "bars", "[blrt]margin", "border", "boxwidth", "clabel", "clip",
        "cntrlabel", "cntrparam", "colorbox", "colormap", "colorsequence", "contour", "dashtype",
        "datafile", "decimalsign", "dgrid3d", "dummy", "encoding", "errorbars", "fit", "fontpath",
        "format", "grid", "hidden3d", "history", "isosamples", "isotropic", "jitter", "key", "label",
        "linetype", "link", "loadpath", "locale", "logscale", "log", "macros", "mapping", "margins?",
        "minussign", "monochrome", "mouse", "multiplot", "nonlinear", "object", "offsets", "origin",
        "output", "overflow", "palette", "parametric", "pixmap", "pm3d", "pointintervalbox",
        "pointsize", "polar", "print", "psdir", "samples", "size", "spiderplot", "style", "surface",
        "table", "terminal", "termoption", "term", "theta", "tics", "ticscale", "ticslevel",
        "timefmt", "timestamp", "title", "view", "walls", "xyplane", "zeroaxis", "zero", "for",
        "t", "o", "out", "xr", "yr", "zr", "xl", "yl", "zl", "tit", "sty", "st", "lt", "ps", "samp", "iso",
    ].joined(separator: "|")

    /// A statement starts at the beginning of a line or after `;`.
    private static let statement = "(?m)(?:^|;)\\h*"

    private static let signals: [String] = [
        statement + "(?:s|re)?plot\\h+[^\\s(=,;]",
        statement + "replot\\h*(?:$|;)",
        statement + "(?:set|unset|show)\\h+(?:\(options))\\b",
        statement + "(?:bind|undefine|printerr)\\h+[^\\s(=]",
        statement + "(?:load|call|eval|stats|save|system|cd)\\h+[\"']",
        statement + "print\\h+[^\\s(]",
        statement + "pause\\h+(?:-?\\d|mouse)",
        statement + "(?:clear|reset(?:\\h+(?:bind|errors|session))?)\\h*(?:$|;)",
        statement + "fit\\h+(?:\\[|\\w+\\()",
        // Braced blocks; PARI/GP writes control flow as function calls.
        "(?m)^\\h*do\\h+for\\h*\\[",
        "(?m)^\\h*(?:if|while)\\h*\\(.*\\)\\h*\\{\\h*$",
        "(?m)^\\h*\\}\\h*else\\b",
        // Gnuplot-only variables, and exponentiation (PARI/GP writes `^`).
        "\\b(?:ARG[0-9C]|ARGV|MOUSE_[A-Z]+|GPVAL_\\w+|STATS_\\w+|FIT_[A-Z]+)\\b",
        "[\\w)\\]]\\h*\\*\\*\\h*[\\w(.+-]",
    ]

    /// Drops `#` (Gnuplot) and `\\` or `/* */` (PARI/GP) comments so prose in either language
    /// cannot supply evidence. Block comments keep their line breaks, so no line starts move;
    /// removing text can only lose a match, never create one.
    private static func stripComments(_ source: String) -> String {
        var code = ""
        var rest = source[...]
        while let open = rest.range(of: "/*"), let close = rest[open.upperBound...].range(of: "*/") {
            code += rest[..<open.lowerBound]
            code += String(repeating: "\n", count: rest[open.lowerBound..<close.upperBound].filter { $0 == "\n" }.count)
            rest = rest[close.upperBound...]
        }
        code += rest
        return code.replacingOccurrences(of: "(?m)(?:#|\\\\\\\\).*$", with: "", options: .regularExpression)
    }
}
