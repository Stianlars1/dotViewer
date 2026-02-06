; Types
(value_type) @type.builtin

; Identifiers
(identifier) @variable

; Instructions
(instr_plain) @function.builtin
(instr_call) @function.call

; Functions
(func
  (identifier) @function)

(func_type
  (identifier) @function)

; Keywords
[
  "module"
  "func"
  "param"
  "result"
  "local"
  "global"
  "type"
  "table"
  "memory"
  "elem"
  "data"
  "start"
  "export"
  "import"
  "mut"
  "offset"
  "block"
  "loop"
  "end"
  "then"
  "else"
  "if"
] @keyword

; Instructions as keywords
[
  "call"
  "call_indirect"
  "return"
  "br"
  "br_if"
  "br_table"
  "drop"
  "select"
  "unreachable"
  "nop"
] @keyword

; Operators
[
  "i32"
  "i64"
  "f32"
  "f64"
] @type.builtin

; Literals
(nat) @number
(int) @number
(float) @number.float

; Strings
(string) @string

; Punctuation
[
  "("
  ")"
] @punctuation.bracket

; Comments
(comment) @comment
(block_comment) @comment

