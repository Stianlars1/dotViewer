; Punctuation
[
  ","
  ";"
] @punctuation.delimiter

[
  "("
  ")"
  "<<"
  ">>"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

"%" @punctuation.special

; Identifiers
(identifier) @variable

; Comments
(comment) @comment

; Strings
(string) @string

; Modules
(alias) @module

; Atoms & Keywords
[
  (atom)
  (quoted_atom)
  (keyword)
  (quoted_keyword)
] @string.special

; Interpolation
(interpolation
  [
    "#{"
    "}"
  ] @string.special)

; Escape sequences
(escape_sequence) @string.escape

; Integers
(integer) @number

; Floats
(float) @number.float

; Characters
[
  (char)
  (charlist)
] @character

; Booleans
(boolean) @boolean

; Nil
(nil) @constant.builtin

; Operators
(operator_identifier) @operator

(unary_operator
  operator: _ @operator)

(binary_operator
  operator: _ @operator)

(binary_operator
  operator: "|>"
  right: (identifier) @function)

(dot
  operator: _ @operator)

(stab_clause
  operator: _ @operator)

; Local Function Calls
(call
  target: (identifier) @function.call)

; Remote Function Calls
(call
  target: (dot
    left: [
      (atom) @type
      (_)
    ]
    right: (identifier) @function.call)
  (arguments))

; Reserved Keywords
[
  "after"
  "catch"
  "do"
  "end"
  "fn"
  "rescue"
  "when"
  "else"
] @keyword

; Operator Keywords
[
  "and"
  "in"
  "not in"
  "not"
  "or"
] @keyword.operator

; Module attributes
(unary_operator
  operator: "@"
  operand: [
    (identifier)
    (call
      target: (identifier))
  ] @constant) @constant
