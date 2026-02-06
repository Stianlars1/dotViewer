; Identifiers
(identifier) @variable

; Block types
(block
  (identifier) @keyword)

; Block labels
(block
  (string_lit) @string)

; Attributes
(attribute
  (identifier) @variable.member)

; Functions
(function_call
  (identifier) @function.call)

; Strings
(string_lit) @string
(heredoc_template) @string
(template_literal) @string

; Template interpolation
(template_interpolation
  (identifier) @variable)

; Numbers
(numeric_lit) @number

; Booleans
(bool_lit) @boolean

; Null
(null_lit) @constant.builtin

; Keywords
[
  "for"
  "endfor"
  "in"
  "if"
  "else"
  "endif"
] @keyword

; Operators
[
  "="
  "=="
  "!="
  ">"
  ">="
  "<"
  "<="
  "&&"
  "||"
  "!"
  "+"
  "-"
  "*"
  "/"
  "%"
  "?"
  ":"
  "=>"
  "..."
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
  "."
  ","
] @punctuation.delimiter

; Comments
(comment) @comment

