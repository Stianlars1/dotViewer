import XCTest
@testable import Shared

/// `.gp` is shared by Gnuplot and PARI/GP. The positive cases cover each construct from the
/// 11 "Gnuplot in Action" scripts reported as unrecognised in #29 — rewritten, not copied.
final class GnuplotSourceDetectorTests: XCTestCase {

    func testRecognisesGnuplotConstructs() {
        let samples: [String: String] = [
            "time axis": "set xdata time\nset xtics format \"%H:%M\"\nset timefmt \"%H:%M:%S\"\n",
            "plot after a semicolon": "alpha = 0.3; plot 'series.dat' using 1:2 with lines\n",
            "abbreviated terminal and output": "set t push\nset t pngcairo\nset o 'out.png'\nreplot\nset o\nset t pop\n",
            "commands inside a helper string": "snapshot(name) = sprintf( \\\n  \"set t push; set t svg; set o '%s'; replot\", name)\n",
            "key binding": "bind 'F2' 'set logscale y; replot'\n",
            "do for loop": "do for [k = 1:5] {\n  print k\n}\n",
            "braced while": "while (abs(step) > 1e-9 && n < 20) {\n  n = n + 1\n}\n",
            "braced if/else": "if (n == 0) {\n  n = 1\n} else {\n  n = n * 2\n}\n",
            "undefine": "undefine TMP_*\n",
            "line types and point size": "set linetype 1 lw 2 pt 7 lc rgb '0x1f77b4' # blue\nset pointsize 0.8\n",
            "terminal options": "set termoption font \"Menlo,11\"\n",
            "exponentiation": "twopi = 2.0*pi\nbell(x, s) = exp(-0.5*(x/s)**2)/(sqrt(twopi)*s)\n",
            "call arguments": "first = ARG1\nsecond = ARG2\n",
            "mouse variables": "cursor_x = MOUSE_X\n",
            "print without parentheses": "print sprintf(\"%d steps\", n)\n",
            "plain plot": "plot sin(x)\n",
            "iterated set": "set for [i = 1:3] label i sprintf(\"%d\", i) at i, 0\n",
        ]
        for (name, source) in samples {
            XCTAssertTrue(GnuplotSourceDetector.matches(source), name)
        }
    }

    func testLeavesPARIGPScriptsAlone() {
        let samples: [String: String] = [
            "line comment": "\\\\ sum of divisors\nsigma_sum(n) = sumdiv(n, d, d);\n",
            "plot calls and prose in a block comment": "/* set size and output first,\n   then plot the values */\nploth(t = 0, 50, abs(zeta(1/2 + I*t)));\nplot(X = 0, 2*Pi, sin(X));\n",
            "braced function body": "fib(n) =\n{\n  my(a = 0, b = 1);\n  while (n > 0,\n    [a, b] = [b, a + b];\n    n--\n  );\n  a\n}\n",
            "nested calls": "forprime(p = 2, 100, if (p % 4 == 1, print(p)));\n",
            "length operator": "v = vector(10, i, i^2);\nprint(\"size: \", #v);\n",
            "spaced print call": "default(realprecision, 50);\nx = Mod(2, 7)^3;\nprint (x);\n",
            "meta commands": "\\p 50\n\\r lib.gp\nf(x) = x^2 + 1;\n",
            "banner comments": "/*****************************/\n/* helpers                   */\n/*****************************/\nsq(x) = x^2;\n",
            "variable named plot": "plot = 3;\nplot, 4\n",
            "gnuplot only in comments and strings": "# plot sin(x)\nprint(\"set title hello\")\n",
            "user function named bind": "bind(x) = x + 1;\nbind (3)\n",
            "empty": "",
        ]
        for (name, source) in samples {
            XCTAssertFalse(GnuplotSourceDetector.matches(source), name)
        }
    }

    func testUnterminatedBlockCommentDoesNotHideLaterCommands() {
        XCTAssertTrue(GnuplotSourceDetector.matches("files = system(\"ls data/*.dat\")\nset key left\n"))
    }

    func testResolverUsesDetectorForGPOnly() {
        let url = URL(fileURLWithPath: "/tmp/chart.gp")
        XCTAssertEqual(FileLanguageResolver.resolve(url: url, key: "gp", sample: "set xdata time\n", customMappings: []).id, "gnuplot")
        XCTAssertEqual(FileLanguageResolver.resolve(url: url, key: "gp", sample: "f(x) = x^2;\n", customMappings: []).id, "plaintext")
    }
}
