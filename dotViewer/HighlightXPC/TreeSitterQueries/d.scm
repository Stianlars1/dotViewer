; Identifiers
(identifier) @variable

; Types
(type) @type
(basic_type) @type.builtin

; Functions
(func_declaration
  (identifier) @function)

(call_expression
  (identifier) @function.call)

; Parameters
(parameter
  (identifier) @variable.parameter)

; Keywords
[
  "alias"
  "align"
  "asm"
  "assert"
  "body"
  "cast"
  "const"
  "debug"
  "delete"
  "deprecated"
  "enum"
  "extern"
  "final"
  "immutable"
  "in"
  "inout"
  "invariant"
  "is"
  "lazy"
  "mixin"
  "module"
  "new"
  "nothrow"
  "out"
  "override"
  "package"
  "pragma"
  "pure"
  "ref"
  "scope"
  "shared"
  "static"
  "struct"
  "super"
  "synchronized"
  "template"
  "this"
  "typeid"
  "typeof"
  "union"
  "unittest"
  "version"
  "with"
  "__traits"
  "__gshared"
  "__parameters"
  "__vector"
] @keyword

[
  "class"
  "interface"
] @keyword.type

[
  "function"
  "delegate"
] @keyword.function

"return" @keyword.return

[
  "if"
  "else"
  "switch"
  "case"
  "default"
] @keyword.conditional

[
  "for"
  "foreach"
  "foreach_reverse"
  "while"
  "do"
  "break"
  "continue"
  "goto"
] @keyword.repeat

[
  "try"
  "catch"
  "finally"
  "throw"
] @keyword.exception

[
  "import"
] @keyword.import

[
  "public"
  "private"
  "protected"
  "export"
  "abstract"
  "auto"
  "__gshared"
] @keyword.modifier

; Operators
[
  "="
  "+="
  "-="
  "*="
  "/="
  "%="
  "^="
  "&="
  "|="
  "<<="
  ">>="
  ">>>="
  "~="
  "=="
  "!="
  ">"
  ">="
  "<"
  "<="
  "+"
  "-"
  "*"
  "/"
  "%"
  "~"
  "&"
  "|"
  "^"
  "<<"
  ">>"
  ">>>"
  "!"
  "&&"
  "||"
  "++"
  "--"
  ".."
  "=>"
  "?"
  ":"
] @operator

; Literals
(integer_literal) @number
(float_literal) @number.float
(character_literal) @character
(string_literal) @string

[
  "true"
  "false"
] @boolean

"null" @constant.builtin

; Punctuation
[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  ","
  ";"
  "."
] @punctuation.delimiter

; Comments
(comment) @comment

