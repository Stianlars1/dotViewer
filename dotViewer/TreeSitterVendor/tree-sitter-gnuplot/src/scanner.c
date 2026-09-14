#include <stdlib.h>
#include <string.h>
#include <wctype.h>

#include "tree_sitter/parser.h"

#define MAX_WORD_LENGTH 100

enum TokenType {
  DATABLOCK_START,
  DATABLOCK_END,
  CMD_FIT_KW,    // f / fi / fit
  CMD_PLOT_KW,   // p / pl / plo / plot
  CMD_SPLOT_KW,  // sp / spl / splo / splot
  CMD_PAUSE_KW,  // pa / pau / paus / pause
  CMD_PRINT_KW,  // pr / pri / prin / print
  CMD_HELP_KW,   // he / hel / help
  CMD_LOAD_KW,   // l / lo / loa / load
  KW_PLT_ST,       // plain plot style names (lines, points, boxes, ...)
  KW_CMD_BARE,     // argument-less commands: break/clear/continue/pwd/replot/reread/refresh
  KW_CMD_OPTEXPR,  // commands with optional expression: raise/lower/vclear/toggle
  KW_CMD_EXIT,     // exit / quit
  KW_CMD_EXPR,     // commands with required expression: cd/evaluate
  // Style attribute keywords (was K.* regex tokens in grammar.js). Each has a
  // distinct grammar continuation, so they are distinct tokens (no N->1 merge);
  // moved to the scanner to retire the reg() machinery (scanner-first).
  // Order MUST match the externals list in grammar.js.
  // KW_SA: the style attrs whose continuation is exactly `<kw> <expression>`
  // (linewidth/linestyle/pointinterval/pointnumber/arrowstyle/dashlength) collapsed
  // into ONE token (6->1, identical continuation -> shrinks the table). The rest
  // keep distinct tokens (different continuations: lt/lc colorspec, dt dash_opts,
  // pt/ps `variable`|expr, fs fill_style, fc colorspec, tc textcolor).
  // Order MUST match the externals list in grammar.js.
  KW_SA,
  KW_LT, KW_LC, KW_DT, KW_PT, KW_PS,
  KW_FS, KW_FC, KW_TC,
  // Generic set/show option-body tier tokens. Sub-keywords of option bodies
  // converted to the shared _gopts/_gopts_style grammar rules are matched here
  // (GOPT_KWS) and tagged with their highlight tier. KW_G_AXISFLAG is the
  // (no)?m?<axis>tics family ((no)mxtics, x2tics, ...), only valid in
  // style-flavor bodies. Order MUST match the externals list in grammar.js.
  // KW_G_ARGV is the value-REQUIRED flavor of KW_G_ARG: its grammar branch has
  // no `optional()` around the value, so the state right after the keyword
  // admits only an expression and every keyword-table token drops out of
  // valid_symbols there.
  KW_G_ARG, KW_G_ARGV, KW_G_FLAG, KW_G_MOD, KW_G_COORD, KW_G_AXISFLAG,
  KW_G_AXISRANGE,  // autoscale-only: <axis>{min|max|fix|fixmin|fixmax}?
  // Zero-width separator between an arg/coord keyword and its value inside
  // generic bodies. Matches ONLY when the value is on the SAME logical line
  // (spaces/tabs or a \-newline continuation ahead) — a raw newline or ';'
  // declines, so a next-line identifier is a new statement, never a value.
  GVAL_SEP,
  // Value-binding variant of GVAL_SEP, used only between an arg/coord tier
  // keyword and its value inside _gopts items. Split from GVAL_SEP so the
  // scanner can refuse to bind grammar-literal keywords (`font`) as values
  // while option-head body gates (which use GVAL_SEP) still open.
  GVAL_BIND,
  // Detached angle unit `pi` in `binary rotate=<val> pi`. Own external token so
  // valid_symbols can disambiguate against KW_SA's `pi` (pointinterval alias),
  // which is valid in the SAME merged plot-element state.
  UNIT_PI,
  // Same-line gate for the cmd_bare (replot/refresh/...) plot-element tail.
  // Identical to GVAL_SEP except it ALSO opens on '[', so `replot [0:1] x/2`
  // reaches plot_element's leading range_block repeat. Own token so the ~70
  // set/show body gates keep declining '['.
  GVAL_TAIL,
  // The word `if` opening a plot-element datafile filter. Emitted ONLY when the
  // word sits on the same logical line as the element it attaches to; the
  // grammar has no line boundaries, so without this an old-style
  // `if (cond) <command>` statement on the line AFTER a plot command silently
  // becomes that element's filter.
  KW_FILTER_IF,
};

// Keyword table entry for prefix-abbreviation matching.
// A word matches when min_chars <= len(word) <= len(keyword) and word is a
// prefix of keyword, or when word equals alt exactly.
typedef struct {
  const char* keyword;
  const char* alt;
  int min_chars;
} KwEntry;

// Plain plot styles: leaf nodes in plot_element with no style-specific
// continuation. Styles with trailing options (labels, vectors, isosurface,
// candlesticks, ellipses, filledcurves, fillsteps, image, pm3d) stay as
// regex tokens in grammar.js. min_chars mirror the old reg() calls.
static const KwEntry PLT_STYLE_KWS[] = {
    {"linespoints", "lp", 6},  // before "lines": "linesp..." must not be cut at 5
    {"lines", NULL, 1},
    {"points", NULL, 1},
    {"financebars", NULL, 3},
    {"dots", NULL, 1},
    {"impulses", NULL, 1},
    {"surface", NULL, 3},
    {"steps", NULL, 2},
    {"fsteps", NULL, 6},
    {"histeps", NULL, 7},
    {"arrows", NULL, 3},
    {"sectors", NULL, 3},
    {"xerrorbars", NULL, 9},    // reg("errorbars", -1): "errorbar(s)?"
    {"yerrorbars", NULL, 9},
    {"xyerrorbars", NULL, 10},
    {"xerrorlines", NULL, 11},
    {"yerrorlines", NULL, 11},
    {"xyerrorlines", NULL, 12},
    {"parallelaxes", NULL, 12},
    {"boxerrorbars", NULL, 12},
    {"boxxyerror", NULL, 10},
    {"boxplot", NULL, 7},
    {"boxes", NULL, 5},
    {"circles", NULL, 7},
    {"zerrorfill", NULL, 6},
    {"contourfill", NULL, 11},
    {"spiderplot", NULL, 6},
    {"histograms", NULL, 4},
    {"rgbalpha", NULL, 8},
    {"rgbimage", NULL, 8},
    {"polygons", NULL, 8},
    {"table", NULL, 5},
    {"mask", NULL, 4},
    {NULL, NULL, 0},
};

static bool match_kw_table(const char* word, int wlen, const KwEntry* table) {
  for (int i = 0; table[i].keyword != NULL; i++) {
    const KwEntry* e = &table[i];
    int klen = (int)strlen(e->keyword);
    if (wlen >= e->min_chars && wlen <= klen && strncmp(word, e->keyword, (size_t)wlen) == 0)
      return true;
    if (e->alt && strcmp(word, e->alt) == 0)
      return true;
  }
  return false;
}

// Style attribute keywords. Like KwEntry but each maps to its own token
// (distinct grammar continuations). min_chars/alt mirror the old K.* reg()
// calls in grammar.js.
typedef struct {
  const char* keyword;
  const char* alt;
  int min_chars;
  int symbol;
} StyleKwEntry;

static const StyleKwEntry STYLE_KWS[] = {
    {"linewidth", "lw", 5, KW_SA},
    {"linestyle", "ls", 5, KW_SA},
    {"pointinterval", "pi", 6, KW_SA},
    {"pointnumber", "pn", 6, KW_SA},
    {"arrowstyle", "as", 10, KW_SA},
    {"dashlength", "dl", 5, KW_SA},
    {"linetype", "lt", 8, KW_LT},
    {"linecolor", "lc", 5, KW_LC},
    {"dashtype", "dt", 5, KW_DT},
    {"pointtype", "pt", 6, KW_PT},
    {"pointsize", "ps", 6, KW_PS},
    {"fillstyle", "fs", 4, KW_FS},
    {"fillcolor", "fc", 5, KW_FC},
    {"textcolor", "tc", 5, KW_TC},
    {NULL, NULL, 0, 0},
};

// Words that are gnuplot built-in CONSTANTS, never option keywords.
static bool is_expr_constant(const char* w, int len) {
  return (len == 2 && memcmp(w, "pi", 2) == 0) ||
         (len == 3 && memcmp(w, "NaN", 3) == 0) ||
         (len == 3 && memcmp(w, "Inf", 3) == 0);
}

// True inside the generic _gopts/_gopts_style bodies, where a bare expression
// item is always a valid alternative — so a keyword-table hit on a constant
// word is never what the author meant.
static bool in_generic_body(const bool* v) {
  return v[KW_G_ARG] || v[KW_G_FLAG] || v[KW_G_MOD] || v[KW_G_COORD] ||
         v[KW_G_AXISFLAG] || v[KW_G_AXISRANGE];
}

// Match word against STYLE_KWS, returning the token if a currently-valid one
// matches, else -1.
static int match_style_kw(const char* word, int wlen, const bool* valid_symbols) {
  for (int i = 0; STYLE_KWS[i].keyword != NULL; i++) {
    const StyleKwEntry* e = &STYLE_KWS[i];
    if (!valid_symbols[e->symbol])
      continue;
    int klen = (int)strlen(e->keyword);
    if ((wlen >= e->min_chars && wlen <= klen && strncmp(word, e->keyword, (size_t)wlen) == 0) ||
        (e->alt && strcmp(word, e->alt) == 0))
      return e->symbol;
  }
  return -1;
}

// Generic option-body sub-keywords: one global table shared by every option
// body converted to the _gopts/_gopts_style grammar rules. `symbol` is the
// highlight tier token; `no_prefix` marks (no)?X toggles ("noinvert" etc.).
// The tokens only fire in states where they are valid (inside converted
// bodies), so rows never shadow words in bespoke rules. First match wins:
// when one keyword is a prefix of another, the longer row comes first.
typedef struct {
  const char* keyword;
  int min_chars;
  int symbol;
  int no_prefix;
} GoptKwEntry;

static const GoptKwEntry GOPT_KWS[] = {
    // on/off first: they must win over the one/offset prefix rows below
    {"on", 2, KW_G_MOD, 0},
    {"off", 3, KW_G_MOD, 0},
    // cntrparam
    {"linear", 2, KW_G_MOD, 0},
    {"levels", 2, KW_G_ARG, 0},
    {"cubicspline", 2, KW_G_ARG, 0},
    {"bspline", 2, KW_G_ARG, 0},
    {"points", 1, KW_G_ARG, 0},
    {"order", 1, KW_G_ARG, 0},
    {"origin", 1, KW_G_ARG, 0},
    {"auto", 4, KW_G_ARG, 0},
    {"discrete", 8, KW_G_ARG, 0},
    {"incremental", 2, KW_G_ARG, 0},
    {"unsorted", 8, KW_G_ARG, 0},
    {"sorted", 6, KW_G_ARG, 0},
    {"firstlinetype", 5, KW_G_ARG, 0},
    // palette defined — before the default/defaults prefix rows ("def")
    {"defined", 3, KW_G_ARG, 0},
    // style histogram errorbars (option head is separate; row is body-only)
    {"errorbars", 5, KW_G_ARG, 0},
    // watch/textbox labels boxed toggle
    {"boxed", 5, KW_G_FLAG, 1},
    // `set encoding` values. Enumerated names, so KW_G_MOD. min_chars probed
    // against gnuplot 6.0.4 by RESOLUTION, not acceptance: each prefix is fed
    // to `set encoding <p>; show encoding` and kept only when gnuplot reports
    // back this same keyword. gnuplot resolves an ambiguous prefix to the
    // first entry of its own table, so `iso` is iso_8859_1 and `koi8` is
    // koi8r; the losing members of each family need their full name.
    {"iso_8859_1", 3, KW_G_MOD, 0},
    {"iso_8859_15", 11, KW_G_MOD, 0},
    {"iso_8859_2", 10, KW_G_MOD, 0},
    {"iso_8859_9", 10, KW_G_MOD, 0},
    {"koi8r", 4, KW_G_MOD, 0},
    {"koi8u", 5, KW_G_MOD, 0},
    {"cp437", 3, KW_G_MOD, 0},
    {"cp850", 5, KW_G_MOD, 0},
    {"cp852", 5, KW_G_MOD, 0},
    {"cp950", 5, KW_G_MOD, 0},
    {"cp1250", 6, KW_G_MOD, 0},
    {"cp1251", 6, KW_G_MOD, 0},
    {"cp1252", 6, KW_G_MOD, 0},
    {"cp1254", 6, KW_G_MOD, 0},
    {"sjis", 2, KW_G_MOD, 0},
    {"utf8", 3, KW_G_MOD, 0},
    // colorbox
    {"vertical", 3, KW_G_FLAG, 1},  // `ve` is not accepted by gnuplot; `ver` is
    {"horizontal", 3, KW_G_ARG, 0},  // NOT 1: gnuplot resolves `h` to `height`
    {"invert", 3, KW_G_FLAG, 1},
    {"user", 1, KW_G_ARG, 0},
    {"default", 3, KW_G_ARG, 0},
    {"size", 1, KW_G_ARG, 0},
    {"front", 2, KW_G_FLAG, 0},
    {"back", 2, KW_G_FLAG, 0},
    {"noborder", 4, KW_G_FLAG, 0},
    {"bdefault", 2, KW_G_MOD, 0},
    {"border", 2, KW_G_ARG, 0},
    {"cbtics", 6, KW_G_ARG, 0},
    // grid
    {"polar", 2, KW_G_FLAG, 1},
    {"layerdefault", 6, KW_G_ARG, 0},
    {"spiderplot", 6, KW_G_ARG, 0},
    // angles
    {"degrees", 1, KW_G_ARG, 0},
    {"radians", 2, KW_G_ARG, 0},
    // boxwidth / boxdepth
    {"absolute", 1, KW_G_ARG, 0},
    {"relative", 1, KW_G_ARG, 0},
    {"square", 6, KW_G_FLAG, 1},
    // clip
    {"one", 1, KW_G_ARG, 0},
    {"two", 2, KW_G_ARG, 0},
    {"radial", 2, KW_G_ARG, 0},
    // colorsequence
    {"classic", 7, KW_G_MOD, 0},
    {"podo", 4, KW_G_MOD, 0},
    // contour (surface after size: bare "s" keeps meaning size)
    {"base", 2, KW_G_MOD, 0},
    {"both", 2, KW_G_MOD, 0},
    {"surface", 1, KW_G_MOD, 0},
    // contourfill
    {"ztics", 5, KW_G_ARG, 0},
    {"palette", 3, KW_G_ARG, 0},
    // decimalsign
    {"locale", 6, KW_G_ARG, 0},
    // coordinate systems (offsets, positions in converted bodies)
    {"first", 3, KW_G_COORD, 0},
    {"second", 3, KW_G_COORD, 0},
    {"graph", 2, KW_G_COORD, 0},
    {"screen", 2, KW_G_COORD, 0},
    {"character", 4, KW_G_COORD, 0},
    // history
    {"quiet", 5, KW_G_ARG, 0},
    {"numbers", 3, KW_G_ARG, 0},
    {"full", 4, KW_G_MOD, 0},
    {"trip", 4, KW_G_MOD, 0},
    // hidden3d (offset toggle; trianglepattern; (no)undefined; alt/bent)
    {"offset", 3, KW_G_ARG, 1},
    {"trianglepattern", 15, KW_G_ARG, 0},
    {"undefined", 5, KW_G_ARG, 1},
    {"altdiagonal", 3, KW_G_FLAG, 1},
    {"bentover", 4, KW_G_FLAG, 1},
    {"defaults", 3, KW_G_MOD, 0},
    // isosurface
    {"mixed", 3, KW_G_ARG, 0},
    {"triangles", 6, KW_G_ARG, 0},
    {"insidecolor", 6, KW_G_ARG, 1},
    // jitter
    {"overlap", 4, KW_G_ARG, 0},
    {"spread", 6, KW_G_ARG, 0},
    {"wrap", 4, KW_G_ARG, 0},
    {"swarm", 5, KW_G_MOD, 0},
    // mapping
    {"cartesian", 9, KW_G_MOD, 0},
    {"spherical", 9, KW_G_MOD, 0},
    {"cylindrical", 11, KW_G_MOD, 0},
    // mouse ("do" must stay the do-loop command: doubleclick min 4)
    {"doubleclick", 4, KW_G_ARG, 1},
    {"zoomcoordinates", 6, KW_G_ARG, 1},
    {"zoomfactors", 6, KW_G_ARG, 0},
    {"ruler", 5, KW_G_ARG, 1},
    {"polardistancedeg", 16, KW_G_ARG, 1},
    {"polardistancetan", 16, KW_G_ARG, 1},
    {"polardistance", 13, KW_G_ARG, 1},
    {"mouseformat", 11, KW_G_ARG, 0},
    {"function", 8, KW_G_ARG, 0},
    {"labels", 3, KW_G_ARG, 1},
    {"zoomjump", 5, KW_G_ARG, 1},
    {"verbose", 3, KW_G_ARG, 1},
    // cntrlabel
    {"start", 5, KW_G_ARG, 0},
    {"interval", 6, KW_G_ARG, 0},
    {"onecolor", 8, KW_G_ARG, 0},
    // errorbars
    {"small", 5, KW_G_MOD, 0},
    {"large", 5, KW_G_MOD, 0},
    {"fullwidth", 9, KW_G_MOD, 0},
    // walls
    {"x0", 2, KW_G_MOD, 0},
    {"x1", 2, KW_G_MOD, 0},
    {"y0", 2, KW_G_MOD, 0},
    {"y1", 2, KW_G_MOD, 0},
    {"z0", 2, KW_G_MOD, 0},
    // theta direction words. The position rows below own the bare letters:
    // gnuplot reads `set k t l` as `top left`, so l/r/t/b/c carry min 1 and
    // their one-letter rivals (two, radians, radial, bspline, cubicspline)
    // sit at gnuplot's own 2-char minimums (tw/ra/ra/bs/cu, probed on 6.0.4).
    // Cost, accepted: `set clip t`, `set angles r`, `set cntrparam b` now
    // read the position word — same arg tier, one mislabelled leaf, no
    // structural damage. An option-blind table cannot have both.
    {"counterclockwise", 16, KW_G_MOD, 0},
    {"clockwise", 9, KW_G_MOD, 0},
    {"ccw", 3, KW_G_MOD, 0},
    {"cw", 2, KW_G_MOD, 0},
    {"left", 1, KW_G_ARG, 0},
    {"right", 1, KW_G_ARG, 0},
    {"top", 1, KW_G_ARG, 0},
    {"bottom", 1, KW_G_ARG, 0},
    // view
    {"map", 3, KW_G_ARG, 0},
    {"scale", 5, KW_G_ARG, 0},
    {"projection", 10, KW_G_ARG, 0},
    {"azimuth", 7, KW_G_ARG, 0},
    {"equal", 5, KW_G_FLAG, 1},
    {"xyz", 3, KW_G_MOD, 0},
    {"xy", 2, KW_G_MOD, 0},
    {"xz", 2, KW_G_MOD, 0},
    {"yz", 2, KW_G_MOD, 0},
    // size
    {"ratio", 2, KW_G_ARG, 1},
    // pixmap
    {"width", 3, KW_G_ARG, 0},  // gnuplot accepts `w`; kept at 3 so a bare `w` stays a variable
    {"height", 6, KW_G_ARG, 0},
    {"center", 1, KW_G_ARG, 0},
    {"behind", 6, KW_G_FLAG, 0},
    {"at", 2, KW_G_ARG, 0},
    {"colormap", 8, KW_G_ARG, 0},
    // print
    {"append", 6, KW_G_ARG, 0},
    // colormap
    {"new", 3, KW_G_ARG, 0},
    // autoscale
    {"fix", 3, KW_G_MOD, 0},
    {"keepfix", 4, KW_G_MOD, 0},
    {"noextend", 5, KW_G_FLAG, 0},
    // format
    {"numeric", 7, KW_G_MOD, 0},
    {"timedate", 8, KW_G_MOD, 0},
    {"geographic", 3, KW_G_MOD, 0},
    // linetype
    {"cycle", 5, KW_G_ARG, 0},
    // termoption
    {"fontscale", 9, KW_G_ARG, 0},
    // palette
    {"gray", 4, KW_G_MOD, 0},
    {"color", 5, KW_G_MOD, 0},
    {"gamma", 5, KW_G_ARG, 0},
    {"gradient", 4, KW_G_ARG, 0},
    {"fit2rgbformulae", 7, KW_G_ARG, 0},
    {"rgbformulae", 3, KW_G_ARG, 0},
    {"functions", 4, KW_G_ARG, 0},
    {"cubehelix", 4, KW_G_ARG, 0},
    {"cycles", 6, KW_G_ARG, 0},
    {"saturation", 10, KW_G_ARG, 0},
    {"positive", 3, KW_G_ARG, 0},
    {"negative", 3, KW_G_ARG, 0},
    {"nops_allcF", 10, KW_G_MOD, 0},
    {"ps_allcF", 8, KW_G_MOD, 0},
    {"maxcolors", 4, KW_G_ARG, 0},
    // NOTE: no "int" row — int() is a builtin function; a row would split
    // calls like `int(n/2)` inside bodies. "int" degrades to an identifier.
    {"float", 5, KW_G_MOD, 0},
    {"hex", 3, KW_G_MOD, 0},
    // style (boxplot / histogram / circle / textbox / arrow tails)
    {"range", 5, KW_G_ARG, 0},
    {"fraction", 8, KW_G_ARG, 0},
    // min 4, NOT 3: "out" is a common variable name (see "outside")
    {"outliers", 4, KW_G_FLAG, 1},
    {"medianlinewidth", 15, KW_G_ARG, 0},
    {"separation", 10, KW_G_ARG, 0},
    {"candlesticks", 12, KW_G_MOD, 0},
    {"financebars", 11, KW_G_MOD, 0},
    {"clustered", 5, KW_G_ARG, 0},
    {"gap", 3, KW_G_ARG, 0},
    {"rowstacked", 4, KW_G_ARG, 0},
    {"columnstacked", 7, KW_G_ARG, 0},
    {"nokeyseparators", 5, KW_G_ARG, 0},
    {"radius", 3, KW_G_ARG, 0},
    {"nodraw", 6, KW_G_MOD, 0},
    {"margins", 7, KW_G_ARG, 0},
    {"transparent", 5, KW_G_MOD, 0},
    {"heads", 5, KW_G_FLAG, 1},
    {"head", 4, KW_G_FLAG, 1},
    {"backheads", 9, KW_G_FLAG, 0},
    {"backhead", 8, KW_G_FLAG, 0},
    {"filled", 6, KW_G_FLAG, 1},
    {"empty", 5, KW_G_MOD, 0},
    {"none", 4, KW_G_MOD, 0},
    {"point", 5, KW_G_ARG, 0},
    // object (before key: "to" must win over the "top" prefix row)
    {"rectangle", 3, KW_G_MOD, 0},
    {"circle", 4, KW_G_MOD, 0},
    {"ellipse", 3, KW_G_MOD, 0},
    {"polygon", 4, KW_G_MOD, 0},
    {"from", 4, KW_G_ARG, 0},
    {"rto", 3, KW_G_ARG, 0},
    {"to", 2, KW_G_ARG, 0},
    {"arc", 3, KW_G_ARG, 0},
    {"angle", 5, KW_G_ARG, 0},
    {"wedge", 2, KW_G_FLAG, 1},
    {"units", 5, KW_G_ARG, 0},
    {"xx", 2, KW_G_MOD, 0},
    {"yy", 2, KW_G_MOD, 0},
    {"depthorder", 5, KW_G_FLAG, 0},
    {"clip", 4, KW_G_FLAG, 1},
    // key
    {"autotitle", 1, KW_G_ARG, 1},
    {"columnheader", 3, KW_G_ARG, 0},
    {"box", 3, KW_G_FLAG, 1},
    {"opaque", 6, KW_G_FLAG, 1},
    {"reverse", 3, KW_G_FLAG, 1},
    {"samplen", 7, KW_G_ARG, 0},
    {"spacing", 2, KW_G_ARG, 0},  // `set key sp 2` resolves to spacing
    {"keywidth", 4, KW_G_ARG, 0},
    {"columns", 7, KW_G_ARG, 0},
    {"maxcols", 6, KW_G_ARG, 0},
    {"maxrows", 6, KW_G_ARG, 0},
    {"inside", 3, KW_G_ARG, 0},
    // min 4, NOT gnuplot's 1: "out" is a common variable name (output paths)
    {"outside", 4, KW_G_ARG, 0},
    {"Left", 2, KW_G_ARG, 0},
    {"Right", 2, KW_G_ARG, 0},
    {"fixed", 5, KW_G_MOD, 0},
    {"title", 2, KW_G_ARG, 1},
    {"lmargin", 2, KW_G_ARG, 0},
    {"rmargin", 2, KW_G_ARG, 0},
    {"tmargin", 2, KW_G_ARG, 0},
    {"bmargin", 2, KW_G_ARG, 0},
    // terminal options (t_opts generic conversion). min_chars mirror the old
    // key()/reg() forms exactly (mostly full-word). Deliberately ABSENT:
    // name/eps/input (common variable names — a global row would steal them
    // from value positions in every generic body), reset/raise (command words
    // on a following line would be swallowed by the body), font/position/
    // background/animate (structured values, bespoke branches in t_opts),
    // size/scale/width/title/default/clip/fixed/small/large (rows exist).
    {"enhanced", 3, KW_G_FLAG, 1},
    {"crop", 4, KW_G_FLAG, 1},
    {"truecolor", 4, KW_G_FLAG, 1},
    {"interlace", 5, KW_G_FLAG, 1},
    {"anchor", 6, KW_G_MOD, 0},
    {"scroll", 6, KW_G_FLAG, 0},
    {"tiny", 4, KW_G_MOD, 0},
    {"medium", 6, KW_G_MOD, 0},
    {"giant", 5, KW_G_MOD, 0},
    {"window", 6, KW_G_ARG, 0},
    {"fsize", 5, KW_G_ARG, 0},
    {"pointsmax", 9, KW_G_ARG, 0},
    {"fontsize", 8, KW_G_ARG, 0},
    {"pointscale", 10, KW_G_ARG, 0},
    {"plotsize", 8, KW_G_ARG, 0},
    {"charsize", 8, KW_G_ARG, 0},
    {"resolution", 10, KW_G_ARG, 0},
    {"palfuncparam", 12, KW_G_ARG, 0},
    {"aspect", 6, KW_G_ARG, 0},
    {"fillchar", 8, KW_G_ARG, 0},
    {"jsdir", 5, KW_G_ARG, 0},
    {"header", 6, KW_G_ARG, 1},
    {"fontscale", 9, KW_G_ARG, 0},
    {"rotate", 6, KW_G_FLAG, 1},
    {"timestamp", 9, KW_G_FLAG, 1},
    {"attributes", 10, KW_G_FLAG, 1},
    {"feed", 4, KW_G_FLAG, 1},
    {"replotonresize", 14, KW_G_FLAG, 1},
    {"antialias", 9, KW_G_FLAG, 1},
    {"persist", 7, KW_G_FLAG, 1},
    {"ctrl", 4, KW_G_FLAG, 1},
    {"ctrlq", 5, KW_G_FLAG, 1},
    {"close", 5, KW_G_MOD, 0},
    {"eject", 5, KW_G_MOD, 0},
    {"noproportional", 14, KW_G_FLAG, 0},
    {"originreset", 11, KW_G_FLAG, 1},
    {"gparrows", 8, KW_G_FLAG, 1},
    {"gppoints", 8, KW_G_FLAG, 1},
    {"picenvironment", 14, KW_G_FLAG, 1},
    {"tightboundingbox", 16, KW_G_FLAG, 1},
    {"fulldoc", 7, KW_G_FLAG, 1},
    {"standalone", 10, KW_G_FLAG, 1},
    {"tikzarrows", 10, KW_G_FLAG, 1},
    {"externalimages", 14, KW_G_FLAG, 1},
    {"inlineimages", 12, KW_G_FLAG, 0},
    {"noanimate", 9, KW_G_FLAG, 0},
    {"auxfile", 7, KW_G_FLAG, 1},
    {"pspoints", 8, KW_G_FLAG, 1},
    {"mouse", 5, KW_G_MOD, 0},
    {"pdf", 3, KW_G_MOD, 0},
    {"png", 3, KW_G_MOD, 0},
    {"level1", 6, KW_G_MOD, 0},
    {"leveldefault", 12, KW_G_MOD, 0},
    {"level3", 6, KW_G_MOD, 0},
    {"blacktext", 9, KW_G_MOD, 0},
    {"colortext", 9, KW_G_MOD, 0},
    {"colourtext", 10, KW_G_MOD, 0},
    {"landscape", 9, KW_G_MOD, 0},
    {"portrait", 8, KW_G_MOD, 0},
    {"big", 3, KW_G_MOD, 0},
    {"solid", 5, KW_G_MOD, 0},
    {"dashed", 6, KW_G_MOD, 0},
    {"defaultplex", 11, KW_G_MOD, 0},
    {"simplex", 7, KW_G_MOD, 0},
    {"duplex", 6, KW_G_MOD, 0},
    {"mitered", 7, KW_G_MOD, 0},
    {"beveled", 7, KW_G_MOD, 0},
    {"mpoints", 7, KW_G_MOD, 0},
    {"texpoints", 9, KW_G_MOD, 0},
    {"texarrows", 9, KW_G_MOD, 0},
    {"smallpoints", 11, KW_G_MOD, 0},
    {"tinypoints", 10, KW_G_MOD, 0},
    {"normalpoints", 12, KW_G_MOD, 0},
    {"textnormal", 10, KW_G_MOD, 0},
    {"textspecial", 11, KW_G_MOD, 0},
    {"texthidden", 10, KW_G_MOD, 0},
    {"textrigid", 9, KW_G_MOD, 0},
    {"mono", 4, KW_G_MOD, 0},
    {"ansi", 4, KW_G_MOD, 0},
    {"ansi256", 7, KW_G_MOD, 0},
    {"ansirgb", 7, KW_G_MOD, 0},
    {"latex", 5, KW_G_MOD, 0},
    {"tex", 3, KW_G_MOD, 0},
    {"context", 7, KW_G_MOD, 0},
    {"dynamic", 7, KW_G_MOD, 0},
    // tkcanvas (script-language alternatives + toggles). perltkx before perl
    // (prefix rule). All full-word: short language names are plausible
    // identifiers, so no abbreviation.
    {"perltkx", 7, KW_G_MOD, 0},
    {"perl", 4, KW_G_MOD, 0},
    {"tcl", 3, KW_G_MOD, 0},
    {"python", 6, KW_G_MOD, 0},
    {"ruby", 4, KW_G_MOD, 0},
    {"rexx", 4, KW_G_MOD, 0},
    {"interactive", 11, KW_G_FLAG, 0},
    {"rottext", 7, KW_G_FLAG, 1},
    {"pixels", 6, KW_G_MOD, 0},
    // pstricks (output flavor + arrows + unit sizing). `unit` must stay after
    // the `units` row above (first match wins; units min 5 so bare `unit`
    // falls through here). nopstricks/nopsarrows rejected live (6.0.4),
    // nounit accepted — no_prefix set accordingly.
    {"pstricks", 8, KW_G_MOD, 0},
    {"pdftricks2", 10, KW_G_MOD, 0},
    {"psarrows", 8, KW_G_FLAG, 0},
    {"unit", 4, KW_G_MOD, 1},
    // tics (tics_opts generic conversion). rotate/enhanced/offset/justify
    // arrive via existing rows or the style_opts branch. NOT rows: in/out
    // (for-loop keyword / common variable — degrade to identifier items),
    // "log" alone (log() is a builtin: logscale min 4, like the no-int rule)
    {"axis", 4, KW_G_MOD, 0},
    {"mirror", 2, KW_G_FLAG, 1},  // `set xtics nomi` is valid; `min` stays builtin
    {"add", 3, KW_G_ARG, 0},
    {"autofreq", 4, KW_G_ARG, 0},
    // effective from "autoj": shorter prefixes hit the autotitle row first
    {"autojustify", 2, KW_G_ARG, 0},
    {"by", 2, KW_G_ARGV, 0},
    {"format", 6, KW_G_ARG, 0},
    {"logscale", 4, KW_G_FLAG, 1},
    {"rangelimited", 5, KW_G_FLAG, 1},
    // "time" full word only ("tim"/"t" are variables in 6.0.4); can't shadow
    // the timedate/timestamp rows — a word longer than a row's keyword never
    // matches it. Enables `set xtics format "%b %d" time` (as an identifier
    // the body used to stop at the statement boundary after the bound value)
    {"time", 4, KW_G_MOD, 0},
    // fit ("log"/"min"/"exp" stay identifiers — builtins; "error" hits the
    // errorbars row first: mislabeled tier, still parses)
    // explicit no-form: gnuplot accepts `nolog` (5 chars) while bare `log`
    // stays min 4 (builtin function) — the generic no-strip can't reach it
    {"nologfile", 5, KW_G_FLAG, 0},
    {"logfile", 4, KW_G_ARG, 1},
    {"results", 7, KW_G_MOD, 0},
    {"brief", 5, KW_G_MOD, 0},
    {"errorvariables", 3, KW_G_FLAG, 1},
    {"covariancevariables", 3, KW_G_FLAG, 1},
    {"errorscaling", 6, KW_G_FLAG, 1},
    {"prescale", 8, KW_G_FLAG, 1},
    {"maxiter", 7, KW_G_ARG, 0},
    {"limit_abs", 9, KW_G_ARG, 0},
    {"limit", 5, KW_G_ARG, 0},
    {"script", 6, KW_G_MOD, 0},
    {"v4", 2, KW_G_MOD, 0},
    {"v5", 2, KW_G_MOD, 0},
    // dgrid3d / polar grid kernels
    {"splines", 7, KW_G_MOD, 0},
    {"qnorm", 5, KW_G_ARG, 0},
    {"gauss", 5, KW_G_MOD, 0},
    {"cauchy", 6, KW_G_MOD, 0},
    {"hann", 4, KW_G_MOD, 0},
    {"kdensity", 8, KW_G_MOD, 0},
    // mxtics time units ("sec".."second" abbreviations hit the coord row)
    {"seconds", 3, KW_G_MOD, 0},
    {"minutes", 4, KW_G_MOD, 0},
    {"hours", 4, KW_G_MOD, 0},
    {"days", 3, KW_G_MOD, 0},
    {"weeks", 4, KW_G_MOD, 0},
    {"months", 3, KW_G_MOD, 0},
    {"years", 4, KW_G_MOD, 0},
    // x*label
    {"parallel", 8, KW_G_MOD, 0},
    // polar grid theta range (`theta [0:pi]`): without a row the identifier
    // glues to the bracket as an array subscript. Bare `r [0:1]` keeps that
    // limitation — `r` is far too common a variable for a global row.
    {"theta", 5, KW_G_ARG, 0},
    // surface (explicit min 4 — exp() is a builtin)
    {"implicit", 3, KW_G_MOD, 0},
    {"explicit", 4, KW_G_MOD, 0},
    {NULL, 0, 0, 0},
};

// Match word against GOPT_KWS honoring valid_symbols and (no)? prefixes.
static int match_gopt_kw(const char* word, int wlen, const bool* valid_symbols) {
  for (int pass = 0; pass < 2; pass++) {
    const char* w = word;
    int len = wlen;
    if (pass == 1) {  // second pass: strip "no" for no_prefix rows
      if (wlen < 3 || word[0] != 'n' || word[1] != 'o')
        break;
      w = word + 2;
      len = wlen - 2;
    }
    for (int i = 0; GOPT_KWS[i].keyword != NULL; i++) {
      const GoptKwEntry* e = &GOPT_KWS[i];
      if (!valid_symbols[e->symbol])
        continue;
      if (pass == 1 && !e->no_prefix)
        continue;
      int klen = (int)strlen(e->keyword);
      if (len >= e->min_chars && len <= klen && strncmp(w, e->keyword, (size_t)len) == 0)
        return e->symbol;
    }
  }
  return -1;
}

// Axis-word matchers. <axis> is one of x2/y2/cb/vx/vy/vz/xy (2 chars, tried
// first) or x/y/z/r/t/u/v.
//
// match_axis_word(word, wlen, suffix_kind):
//   kind 0: (no)?m?<axis><tics-prefix>  — nomxtics, x2tics, "tics" may
//           abbreviate to zero chars (mirrors the old grid regex).
//   kind 1: <axis>{min|max|fix|fixmin|fixmax}? — autoscale axis words. This
//           kind is ONLY valid in the autoscale body (own token): words like
//           "rmax"/"xmin" are common user variable names, so they must not
//           become keywords in every generic body.
static bool axis_word_suffix(const char* word, int j, int wlen, int kind) {
  if (j == wlen) return true;  // bare axis
  if (kind == 1) {
    static const char* sfx[] = {"min", "max", "fix", "fixmin", "fixmax", NULL};
    for (int s = 0; sfx[s] != NULL; s++)
      if ((int)strlen(sfx[s]) == wlen - j && strncmp(word + j, sfx[s], (size_t)(wlen - j)) == 0)
        return true;
    return false;
  }
  int k = 0, i = j;
  while (i < wlen && k < 4 && word[i] == "tics"[k]) { i++; k++; }
  return i == wlen;
}

static bool match_axis_word(const char* word, int wlen, int kind) {
  int i = 0;
  if (kind == 0) {
    if (wlen >= 2 && word[0] == 'n' && word[1] == 'o') i = 2;
    if (i < wlen && word[i] == 'm') i++;
  }
  static const char* axes2[] = {"x2", "y2", "cb", "vx", "vy", "vz", "xy", NULL};
  static const char axes1[] = "xyzrtuv";
  for (int a = 0; axes2[a] != NULL; a++) {
    if (wlen - i >= 2 && word[i] == axes2[a][0] && word[i + 1] == axes2[a][1]) {
      if (axis_word_suffix(word, i + 2, wlen, kind)) return true;
    }
  }
  for (int a = 0; axes1[a] != '\0'; a++) {
    if (wlen - i >= 1 && word[i] == axes1[a]) {
      if (axis_word_suffix(word, i + 1, wlen, kind)) return true;
    }
  }
  return false;
}

// Command keyword table: maps each prefix-abbreviated command word to its
// external token. Groups sharing a token have identical continuations in the
// grammar. Order is first-match (mirrors the old if-else chain).
typedef struct {
  const char* keyword;
  int min_chars;
  int symbol;
} CmdKwEntry;

static const CmdKwEntry CMD_KWS[] = {
    {"fit", 1, CMD_FIT_KW},
    {"plot", 1, CMD_PLOT_KW},
    {"splot", 2, CMD_SPLOT_KW},
    {"pause", 2, CMD_PAUSE_KW},
    {"print", 2, CMD_PRINT_KW},
    // Longer than "print", so the row above can never shadow it.
    {"printerror", 8, CMD_PRINT_KW},
    {"help", 2, CMD_HELP_KW},
    {"load", 1, CMD_LOAD_KW},
    // Argument-less commands collapsed into one token:
    {"break", 5, KW_CMD_BARE},
    {"clear", 2, KW_CMD_BARE},
    {"continue", 8, KW_CMD_BARE},
    {"pwd", 3, KW_CMD_BARE},
    {"replot", 3, KW_CMD_BARE},
    {"reread", 6, KW_CMD_BARE},
    {"refresh", 3, KW_CMD_BARE},
    {"remultiplot", 7, KW_CMD_BARE},
    // Commands followed by one optional expression:
    {"raise", 2, KW_CMD_OPTEXPR},
    {"lower", 3, KW_CMD_OPTEXPR},
    {"vclear", 6, KW_CMD_OPTEXPR},
    {"toggle", 6, KW_CMD_OPTEXPR},
    {"warn", 4, KW_CMD_OPTEXPR},
    {"exit", 2, KW_CMD_EXIT},
    {"quit", 1, KW_CMD_EXIT},
    // Commands followed by one required expression:
    {"cd", 2, KW_CMD_EXPR},
    {"evaluate", 4, KW_CMD_EXPR},
    {NULL, 0, 0},
};

typedef struct {
  char word[MAX_WORD_LENGTH];
} Scanner;

static inline void consume(TSLexer* lexer) {
  lexer->advance(lexer, false);
}
static inline void skip(TSLexer* lexer) {
  lexer->advance(lexer, true);
}

// Mirror the grammar's extras regex /\s|\\|;/ — the internal lexer skips these
// characters inside one lex call, so the external scanner must skip them too;
// otherwise it fails at a ';' and never gets a second chance at the word that
// follows (the internal lexer consumes it as identifier in the same call).
static inline void skip_whitespaces(TSLexer* lexer) {
  while (iswspace(lexer->lookahead) || lexer->lookahead == ';' || lexer->lookahead == '\\') skip(lexer);
}

void* tree_sitter_gnuplot_external_scanner_create() {
  return calloc(1, sizeof(Scanner));
}
void tree_sitter_gnuplot_external_scanner_destroy(void* payload) {
  free(payload);
}

unsigned tree_sitter_gnuplot_external_scanner_serialize(void* payload, char* buffer) {
  Scanner* s = (Scanner*)payload;
  unsigned len = (unsigned)strlen(s->word);
  memcpy(buffer, s->word, len);
  return len;
}

void tree_sitter_gnuplot_external_scanner_deserialize(void* payload, const char* buffer, unsigned length) {
  Scanner* s = (Scanner*)payload;
  if (length > 0) memcpy(s->word, buffer, length);
  s->word[length] = '\0';
}

static bool scan_datablock_start(TSLexer* lexer, Scanner* s) {
  if (!iswalpha(lexer->lookahead))
    return false;
  memset(s->word, 0, sizeof(s->word));
  int i = 0;
  while (iswalpha(lexer->lookahead) && i < MAX_WORD_LENGTH - 1) {
    s->word[i++] = lexer->lookahead;
    consume(lexer);
  }
  s->word[i] = '\0';
  return true;
}

static bool scan_datablock_end(TSLexer* lexer, Scanner* s) {
  // Guard: if no datablock is open, empty word would match any non-alpha pos
  if (s->word[0] == '\0')
    return false;
  int i = 0;
  while (iswalpha(lexer->lookahead) && s->word[i] != '\0' && lexer->lookahead == s->word[i]) {
    consume(lexer);
    i++;
  }
  if (s->word[i] == '\0' && !iswalpha(lexer->lookahead)) {
    return true;
  }
  return false;
}

static bool is_word_char(int32_t c) {
  return iswalnum(c) || c == '_' || c > 127;
}

// Atomically read the word at the current position into buf (cap includes the
// terminating NUL). Returns its length, or -1 when empty or longer than fits:
// tree-sitter only resets the lexer position between full scanner invocations,
// so the word must be read once and matched against all candidates.
static int read_word(TSLexer* lexer, char* buf, int cap) {
  int len = 0;
  while (len < cap - 1 && is_word_char(lexer->lookahead)) {
    buf[len++] = (char)lexer->lookahead;
    consume(lexer);
  }
  buf[len] = '\0';
  if (len == 0 || is_word_char(lexer->lookahead))
    return -1;
  return len;
}

// After reading the keyword and calling mark_end, check whether the token is
// followed by assignment syntax (= or (args)= or [idx]=). If so, this is an
// identifier in an assignment, not a command keyword.
//
// NOTE: all advances here use consume() not skip(). Calling skip() after
// mark_end causes tree-sitter to reset the token start to the mark_end
// position (it interprets skip-after-mark_end as "searching for next token
// start"), producing a zero-length anonymous node. consume() does not trigger
// that behaviour. Characters consumed here are discarded when the lexer resets
// to mark_end on a successful scan.
static bool is_assignment_context(TSLexer* lexer) {
  while (lexer->lookahead == ' ' || lexer->lookahead == '\t') consume(lexer);

  if (lexer->lookahead == '=') {
    consume(lexer);
    return lexer->lookahead != '=';  // '=' but not '=='
  }

  if (lexer->lookahead == '(') {
    int depth = 1;
    consume(lexer);
    while (lexer->lookahead != 0 && depth > 0) {
      int32_t c = lexer->lookahead;
      consume(lexer);
      if (c == '(')
        depth++;
      else if (c == ')')
        depth--;
    }
    while (lexer->lookahead == ' ' || lexer->lookahead == '\t') consume(lexer);
    return lexer->lookahead == '=';
  }

  // Array element assignment p[idx] = expr vs range p [lo:hi] expr:
  // A range block contains ':', an array index does not.
  if (lexer->lookahead == '[') {
    consume(lexer);
    bool has_colon = false;
    int depth = 1;
    while (lexer->lookahead != 0 && depth > 0) {
      int32_t c = lexer->lookahead;
      consume(lexer);
      if (c == '[')
        depth++;
      else if (c == ']')
        depth--;
      else if (c == ':' && depth == 1)
        has_colon = true;
    }
    if (has_colon)
      return false;
    while (lexer->lookahead == ' ' || lexer->lookahead == '\t') consume(lexer);
    return lexer->lookahead == '=';
  }

  return false;
}

// Read the full word ONCE, then match it (in priority order) against command
// keywords, plain plot-style names, and style-attribute keywords — whichever
// tokens are currently valid. One read per scan() call: command, plot-style and
// style-attr tokens can all be valid in the same state (e.g. `plot x lw 2` — at
// the plot-element tail, statement-start command tokens AND style attrs are both
// valid), and tree-sitter resets the lexer between scanner invocations but NOT
// between sub-scanners, so the word must be consumed exactly once.
static bool scan_keywords(TSLexer* lexer, const bool* valid_symbols, bool any_cmd_valid,
                          bool same_line) {
  char word[24];
  int word_len = read_word(lexer, word, sizeof(word));
  if (word_len < 0)
    return false;

  lexer->mark_end(lexer);  // mark end of keyword token before lookahead

  // Plot-element filter `if` — same-line only (see KW_FILTER_IF). On a new
  // logical line the scan declines and the internal lexer produces the cmd_if
  // literal instead, so the statement is not swallowed as a filter.
  if (valid_symbols[KW_FILTER_IF] && same_line && word_len == 2 &&
      word[0] == 'i' && word[1] == 'f') {
    lexer->result_symbol = KW_FILTER_IF;
    return true;
  }

  // Command keywords (statement-start). The assignment-context guard keeps
  // `plot = 1` an assignment rather than the plot command.
  if (any_cmd_valid) {
    for (int i = 0; CMD_KWS[i].keyword != NULL; i++) {
      const CmdKwEntry* e = &CMD_KWS[i];
      if (valid_symbols[e->symbol] && word_len >= e->min_chars &&
          word_len <= (int)strlen(e->keyword) && strncmp(word, e->keyword, (size_t)word_len) == 0) {
        if (is_assignment_context(lexer))
          return false;
        lexer->result_symbol = e->symbol;
        return true;
      }
    }
  }

  // Detached angle unit `pi` (binary rotate=<val> pi). Checked BEFORE the
  // style-attr table: in plot/splot elements KW_SA is valid in the same state
  // (`pi` = pointinterval), and gnuplot resolves the word as the unit there.
  // UNIT_PI is only valid right after a rotate= value, so pointinterval `pi`
  // keeps working everywhere else.
  if (valid_symbols[UNIT_PI] && word_len == 2 && memcmp(word, "pi", 2) == 0) {
    lexer->result_symbol = UNIT_PI;
    return true;
  }

  // Constant words decline every keyword table inside generic option bodies:
  // there a bare expression is always a legal item, so `rotate by pi` means the
  // number, not the `pi`(=pointinterval) abbreviation. Style bodies (plot
  // elements, `set style line ...`) are unaffected — no KW_G_* is valid there,
  // so `pi 5` keeps parsing as pointinterval.
  if (in_generic_body(valid_symbols) && is_expr_constant(word, word_len))
    return false;

  // A word immediately followed by '.' inside a generic body is string concat
  // on a variable (`set print pal.'.gp'`): decline every keyword table so the
  // internal lexer produces the identifier and the item parses as an
  // expression. Spaced leading-dot numbers (`at graph .5`) are unaffected —
  // their '.' is not adjacent to the word.
  if (in_generic_body(valid_symbols) && lexer->lookahead == '.')
    return false;

  // Plot style names take priority over style attrs (e.g. "lines" is the style,
  // not linestyle).
  if (valid_symbols[KW_PLT_ST] && match_kw_table(word, word_len, PLT_STYLE_KWS)) {
    lexer->result_symbol = KW_PLT_ST;
    return true;
  }

  // Style attribute keywords (lw/lt/ls/...).
  int sym = match_style_kw(word, word_len, valid_symbols);
  if (sym >= 0) {
    lexer->result_symbol = sym;
    return true;
  }

  // Generic option-body sub-keywords (tier tokens). The per-axis families
  // are tried first: they are more specific than any GOPT_KWS row.
  if (valid_symbols[KW_G_AXISRANGE] && match_axis_word(word, word_len, 1)) {
    lexer->result_symbol = KW_G_AXISRANGE;
    return true;
  }
  if (valid_symbols[KW_G_AXISFLAG] && match_axis_word(word, word_len, 0)) {
    lexer->result_symbol = KW_G_AXISFLAG;
    return true;
  }
  sym = match_gopt_kw(word, word_len, valid_symbols);
  if (sym >= 0) {
    lexer->result_symbol = sym;
    return true;
  }
  return false;
}

bool tree_sitter_gnuplot_external_scanner_scan(void* payload, TSLexer* lexer, const bool* valid_symbols) {
  Scanner* s = (Scanner*)payload;

  // GVAL_SEP/GVAL_BIND: zero-width, same-line only. Must run BEFORE
  // skip_whitespaces (which also skips newlines and ';'). Skips spaces/tabs
  // and \-newline continuations; succeeds iff the next content is on the
  // same logical line. When both are valid, the body gate (GVAL_SEP) wins.
  // GVAL_TAIL is the cmd_bare variant: same semantics plus '[' opens it.
  if (valid_symbols[GVAL_SEP] || valid_symbols[GVAL_BIND] || valid_symbols[GVAL_TAIL]) {
    const int SEP = valid_symbols[GVAL_SEP] ? GVAL_SEP
                  : (valid_symbols[GVAL_BIND] ? GVAL_BIND : GVAL_TAIL);
    for (;;) {
      if (lexer->lookahead == ' ' || lexer->lookahead == '\t' || lexer->lookahead == '\r') {
        skip(lexer);
      } else if (lexer->lookahead == '\\') {
        skip(lexer);
        if (lexer->lookahead == '\r') skip(lexer);
        if (lexer->lookahead == '\n') skip(lexer);
      } else {
        break;
      }
    }
    if (lexer->lookahead != '\n' && lexer->lookahead != ';' && lexer->lookahead != 0 &&
        lexer->lookahead != '#') {
      lexer->mark_end(lexer);  // zero-width mark: the GVAL_SEP token itself
      // If the next word is itself a keyword (style attr, per-axis word, or
      // another option keyword), it is NOT a value: return THAT token
      // directly (this scan call is the only chance to lex it externally).
      if (is_word_char(lexer->lookahead)) {
        char peek[24];
        int plen = 0;
        while (plen < (int)sizeof(peek) - 1 && is_word_char(lexer->lookahead)) {
          peek[plen++] = (char)lexer->lookahead;
          consume(lexer);
        }
        peek[plen] = '\0';
        bool word_ended = !is_word_char(lexer->lookahead);
        // If the word is immediately used in expression syntax (operator,
        // call, subscript, comma), it is a VALUE even when it matches a
        // keyword row: `palette functions gray,1,1`, `samples points(3)`.
        // '-'/'+' are NOT in this set: a following sign is far more often a
        // signed value of the keyword (`levels incremental -20, 5, 20`) than
        // `kw - x` arithmetic on a variable shadowing a keyword name.
        // '.' splits on spacing. IMMEDIATELY after the word it is string
        // concat on a variable (`set print pal.'.gp'`) — the word is a value;
        // the eccentric `set size.5` (gnuplot tokenizes it as `size .5`)
        // degrades to a value expression, still a valid tree. With space
        // before it, a leading-dot number follows a keyword (`at graph .5`)
        // and the keyword must win; mark_end cannot rewind, so the spaced
        // form cannot be probed past the dot.
        if (lexer->lookahead == '.') {
          lexer->result_symbol = SEP;
          return true;
        }
        {
          int32_t c = lexer->lookahead;
          while (c == ' ' || c == '\t') { consume(lexer); c = lexer->lookahead; }
          if (c == ',' || c == '*' || c == '/' ||
              c == '%' || c == '^' || c == '(' || c == '[' ||
              c == '=' || c == '<' || c == '>' || c == '&' || c == '|' ||
              c == '?' || c == ':') {
            lexer->result_symbol = SEP;
            return true;
          }
        }
        if (word_ended) {
          // "font" is a grammar-level literal (fontspec), not a scanner row:
          // emitting GVAL_BIND here would bind it as the previous keyword's
          // value (`set style watchpoint labels font "..."`); declining the
          // scan lets the internal lexer produce the literal instead. Body
          // gates (GVAL_SEP) still open — fontspec is a valid first item.
          if (plen == 4 && memcmp(peek, "font", 4) == 0) {
            if (valid_symbols[GVAL_SEP]) {
              lexer->result_symbol = GVAL_SEP;
              return true;
            }
            return false;
          }
          // Same constant denylist as scan_keywords: inside a generic body a
          // constant word is a value, so bind it as one instead of letting a
          // keyword table steal it.
          if (in_generic_body(valid_symbols) && is_expr_constant(peek, plen)) {
            lexer->result_symbol = SEP;
            return true;
          }
          int s = match_style_kw(peek, plen, valid_symbols);
          if (s < 0 && valid_symbols[KW_G_AXISRANGE] && match_axis_word(peek, plen, 1))
            s = KW_G_AXISRANGE;
          if (s < 0 && valid_symbols[KW_G_AXISFLAG] && match_axis_word(peek, plen, 0))
            s = KW_G_AXISFLAG;
          if (s < 0)
            s = match_gopt_kw(peek, plen, valid_symbols);
          if (s >= 0) {
            lexer->mark_end(lexer);  // extend token to cover the word
            lexer->result_symbol = s;
            return true;
          }
        }
        lexer->result_symbol = SEP;
        return true;
      }
      // Non-word ahead: emit the separator only for characters that can
      // start an expression ('[' starts a range_block item, not a value).
      // ',' opens bodies whose first positional slot may be EMPTY
      // (`set view ,,0.5`, `set dummy ,v`); in bodies without a comma item
      // the parse fails on the ',' itself, exactly as it did at the gate.
      // '{' starts a complex literal (`print {1,2}`); no option head takes a
      // brace, so there the parse fails on the '{' itself, same as at the gate.
      {
        int32_t c = lexer->lookahead;
        if ((c >= '0' && c <= '9') || c == '.' || c == '"' || c == '\'' ||
            c == '(' || c == '-' || c == '+' || c == '~' || c == '!' ||
            c == '$' || c == '@' || c == ',' || c == '{' ||
            // '[' opens plot_element's leading range_block — cmd_bare tail only
            (c == '[' && SEP == GVAL_TAIL)) {
          lexer->result_symbol = SEP;
          return true;
        }
      }
    }
    // Declined: fall through — other externals (next statement's command
    // keyword, datablock end, ...) may still match from here.
  }

  // Same-line probe for the plot-element filter `if`. Must run BEFORE
  // skip_whitespaces (which crosses newlines and ';'). Only skip() is used, so
  // the position is left exactly where skip_whitespaces would take over and the
  // sub-scanners below are unaffected. Falls through either way — never an
  // early return, which would starve the other sub-scanners of this state.
  bool same_line = true;
  if (valid_symbols[KW_FILTER_IF]) {
    for (;;) {
      if (lexer->lookahead == ' ' || lexer->lookahead == '\t' || lexer->lookahead == '\r') {
        skip(lexer);
      } else if (lexer->lookahead == '\\') {
        skip(lexer);
        if (lexer->lookahead == '\r') skip(lexer);
        if (lexer->lookahead == '\n') skip(lexer);
      } else {
        break;
      }
    }
    if (lexer->lookahead == '\n' || lexer->lookahead == ';' || lexer->lookahead == '#' ||
        lexer->lookahead == 0)
      same_line = false;
  }

  skip_whitespaces(lexer);

  // Datablock end has highest priority: if we're inside an open datablock
  // (s->word non-empty), check for the closing identifier first.
  if (valid_symbols[DATABLOCK_END] && scan_datablock_end(lexer, s)) {
    lexer->result_symbol = DATABLOCK_END;
    return true;
  }

  // Command keywords take priority over DATABLOCK_START. During error
  // recovery the parser marks all external symbols as valid; without this
  // ordering, scan_datablock_start would consume command keywords like
  // "print" or "fit" as DATABLOCK_START before the cmd scanner gets a
  // chance to match them.
  bool any_cmd_valid = valid_symbols[CMD_FIT_KW] || valid_symbols[CMD_PLOT_KW] || valid_symbols[CMD_SPLOT_KW] ||
                       valid_symbols[CMD_PAUSE_KW] || valid_symbols[CMD_PRINT_KW] || valid_symbols[CMD_HELP_KW] ||
                       valid_symbols[CMD_LOAD_KW] || valid_symbols[KW_CMD_BARE] || valid_symbols[KW_CMD_OPTEXPR] ||
                       valid_symbols[KW_CMD_EXIT] || valid_symbols[KW_CMD_EXPR];

  // Command, plot-style and style-attribute keywords share one word read (they
  // can be valid in the same state). Runs before DATABLOCK_START so that during
  // error recovery (all externals valid) scan_datablock_start does not swallow a
  // keyword.
  bool any_style_valid =
      valid_symbols[KW_PLT_ST] || valid_symbols[KW_SA] || valid_symbols[KW_LT] ||
      valid_symbols[KW_LC] || valid_symbols[KW_DT] || valid_symbols[KW_PT] ||
      valid_symbols[KW_PS] || valid_symbols[KW_FS] || valid_symbols[KW_FC] ||
      valid_symbols[KW_TC];

  bool any_gopt_valid =
      valid_symbols[KW_G_ARG] || valid_symbols[KW_G_ARGV] || valid_symbols[KW_G_FLAG] ||
      valid_symbols[KW_G_MOD] || valid_symbols[KW_G_COORD] || valid_symbols[KW_G_AXISFLAG] ||
      valid_symbols[KW_G_AXISRANGE];

  if ((any_cmd_valid || any_style_valid || any_gopt_valid || valid_symbols[UNIT_PI] ||
       valid_symbols[KW_FILTER_IF]) &&
      scan_keywords(lexer, valid_symbols, any_cmd_valid, same_line)) {
    return true;
  }

  if (valid_symbols[DATABLOCK_START] && scan_datablock_start(lexer, s)) {
    lexer->result_symbol = DATABLOCK_START;
    return true;
  }

  return false;
}
