; Variables
(identifier) @variable

; Types
(parametrized_type_expression
  (identifier) @type)

(type_clause
  (identifier) @type)

(typed_expression
  (identifier) @type)

(abstract_definition
  name: (identifier) @type)

(struct_definition
  name: (identifier) @type)

(primitive_definition
  name: (identifier) @type)

; Functions
(function_definition
  name: (identifier) @function)

(short_function_definition
  name: (identifier) @function)

(macro_definition
  name: (identifier) @function.macro)

(call_expression
  (identifier) @function.call)

(broadcast_call_expression
  (identifier) @function.call)

; Parameters
(parameter_list
  (identifier) @variable.parameter)

(typed_parameter
  (identifier) @variable.parameter
  (identifier) @type)

(optional_parameter
  (identifier) @variable.parameter)

(slurp_parameter
  (identifier) @variable.parameter)

; Fields
(field_expression
  (identifier) @variable.member .)

; Modules
(module_definition
  name: (identifier) @module)

; Keywords
[
  "begin"
  "do"
  "end"
  "let"
  "quote"
  "baremodule"
  "module"
  "new"
  "mutable"
  "struct"
  "abstract"
  "type"
  "primitive"
  "macro"
  "const"
  "global"
  "local"
] @keyword

[
  "function"
] @keyword.function

[
  "return"
] @keyword.return

[
  "if"
  "else"
  "elseif"
] @keyword.conditional

[
  "for"
  "while"
  "break"
  "continue"
] @keyword.repeat

[
  "try"
  "catch"
  "finally"
  "throw"
] @keyword.exception

[
  "export"
  "import"
  "using"
] @keyword.import

; Operators
[
  "="
  "+="
  "-="
  "*="
  "/="
  "=="
  "!="
  "<"
  ">"
  "<="
  ">="
  "==="
  "!=="
  "+"
  "-"
  "*"
  "/"
  "\\"
  "^"
  "%"
  "!"
  "&&"
  "||"
  "&"
  "|"
  ":"
  ".."
  "..."
  "->"
  "<:"
  ">:"
  "::"
  "."
  "~"
  "?"
  "$"
  "=>"
  (operator)
] @operator

; Literals
(integer_literal) @number
(float_literal) @number.float
(character_literal) @character
(string_literal) @string
(command_literal) @string
(prefixed_string_literal) @string

[
  "true"
  "false"
] @boolean

"nothing" @constant.builtin

; Interpolation
(interpolation_expression
  "$" @punctuation.special)

(string_interpolation
  "$" @punctuation.special)

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
] @punctuation.delimiter

; Comments
(comment) @comment
(block_comment) @comment

