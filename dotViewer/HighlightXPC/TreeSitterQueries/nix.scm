; Variables
(variable_expression) @variable

; Paths
(path_expression) @string.special

; Strings
(string_expression) @string
(indented_string_expression) @string

; Interpolation
(interpolation
  "${" @punctuation.special
  "}" @punctuation.special)

; URIs
(uri_expression) @string.special

; Numbers
(integer_expression) @number
(float_expression) @number.float

; Booleans
(variable_expression
  (identifier) @boolean)

; Keywords
[
  "if"
  "then"
  "else"
] @keyword.conditional

[
  "let"
  "in"
  "inherit"
  "with"
  "rec"
  "assert"
  "or"
] @keyword

; Functions
(function_expression
  (identifier) @variable.parameter)

(formal
  (identifier) @variable.parameter)

(apply_expression
  function: (variable_expression
    (identifier) @function.call))

(apply_expression
  function: (select_expression
    attrpath: (attrpath
      (identifier) @function.call)))

; Attributes
(binding
  attrpath: (attrpath
    (identifier) @variable.member))

(inherit_from) @keyword

; Builtins
(builtins) @function.builtin

; Operators
[
  "+"
  "-"
  "*"
  "/"
  "++"
  "=="
  "!="
  "<"
  ">"
  "<="
  ">="
  "&&"
  "||"
  "->"
  "//"
  "!"
  "?"
  "."
] @operator

; Punctuation
[
  "{"
  "}"
  "("
  ")"
  "["
  "]"
] @punctuation.bracket

[
  ","
  ";"
  ":"
  "="
  "@"
] @punctuation.delimiter

; Comments
(comment) @comment

