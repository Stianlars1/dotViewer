; Variables
(variable) @variable

; Atoms
(atom) @string.special
(quoted_atom) @string.special

; Strings
(string) @string

; Characters
(char) @character

; Numbers
(integer) @number
(float) @number.float

; Functions
(function_clause
  name: (atom) @function)

(call
  module: (atom) @module
  function: (atom) @function.call)

(call
  function: (atom) @function.call)

(external_fun
  module: (atom) @module
  function: (atom) @function.call)

; Types
(type_alias
  name: (atom) @type)

(opaque
  name: (atom) @type)

(record_decl
  name: (atom) @type)

; Record fields
(record_field_name
  (atom) @variable.member)

; Macros
(macro
  name: (_) @constant)

; Module attributes
(module_attribute
  name: (atom) @keyword.directive)

; Keywords
[
  "after"
  "begin"
  "end"
  "fun"
  "of"
  "when"
] @keyword

[
  "case"
  "if"
] @keyword.conditional

[
  "catch"
  "try"
  "throw"
] @keyword.exception

[
  "receive"
] @keyword

[
  "module"
  "export"
  "import"
  "include"
  "include_lib"
  "define"
  "record"
  "spec"
  "type"
  "opaque"
  "callback"
  "behaviour"
  "export_type"
] @keyword.directive

; Operators
[
  "="
  "=="
  "/="
  "=:="
  "=/="
  "<"
  ">"
  "=<"
  ">="
  "+"
  "-"
  "*"
  "/"
  "!"
  "<-"
  "++"
  "--"
  "=>"
  ":="
  "::"
  ".."
  "->"
  "|"
  (binary_op_expr)
] @operator

[
  "not"
  "and"
  "or"
  "andalso"
  "orelse"
  "band"
  "bor"
  "bxor"
  "bnot"
  "bsl"
  "bsr"
  "div"
  "rem"
] @keyword.operator

; Punctuation
[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
  "<<"
  ">>"
] @punctuation.bracket

[
  ","
  "."
  ";"
  ":"
  "#"
  "?"
] @punctuation.delimiter

; Comments
(comment) @comment

