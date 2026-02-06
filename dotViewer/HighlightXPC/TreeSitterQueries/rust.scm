(identifier) @variable

(type_identifier) @type
(primitive_type) @type.builtin
(field_identifier) @variable.member
(shorthand_field_identifier) @variable.member

(shorthand_field_initializer
  (identifier) @variable.member)

(mod_item
  name: (identifier) @module)

(self) @variable.builtin

(label
  (identifier) @label)

; Function definitions
(function_item
  (identifier) @function)

(function_signature_item
  (identifier) @function)

(parameter
  (identifier) @variable.parameter)

; Function calls
(call_expression
  function: (identifier) @function.call)

(call_expression
  function: (scoped_identifier
    (identifier) @function.call .))

(call_expression
  function: (field_expression
    field: (field_identifier) @function.call))

(generic_function
  function: (identifier) @function.call)

(generic_function
  function: (scoped_identifier
    name: (identifier) @function.call))

(generic_function
  function: (field_expression
    field: (field_identifier) @function.call))

(enum_variant
  name: (identifier) @constant)

(const_item
  name: (identifier) @constant)

(scoped_identifier
  path: (identifier) @module)

(scoped_type_identifier
  path: (identifier) @module)

[
  (crate)
  (super)
] @module

(scoped_use_list
  path: (identifier) @module)

; Macro definitions
"$" @function.macro
(metavariable) @function.macro

(macro_definition
  "macro_rules!" @function.macro)

(attribute_item
  (attribute
    (identifier) @function.macro))

(inner_attribute_item
  (attribute
    (identifier) @function.macro))

(macro_invocation
  macro: (identifier) @function.macro)

; Literals
(boolean_literal) @boolean
(integer_literal) @number
(float_literal) @number.float

[
  (raw_string_literal)
  (string_literal)
] @string

(escape_sequence) @string.escape
(char_literal) @character

; Keywords
[
  "use"
  "mod"
] @keyword.import

[
  "default"
  "impl"
  "let"
  "move"
  "unsafe"
  "where"
] @keyword

[
  "enum"
  "struct"
  "union"
  "trait"
  "type"
] @keyword.type

[
  "async"
  "await"
] @keyword.coroutine

"try" @keyword.exception

[
  "ref"
  "pub"
  (mutable_specifier)
  "const"
  "static"
  "dyn"
  "extern"
] @keyword.modifier

"fn" @keyword.function

[
  "return"
  "yield"
] @keyword.return

[
  "if"
  "else"
  "match"
] @keyword.conditional

[
  "break"
  "continue"
  "in"
  "loop"
  "while"
  "for"
] @keyword.repeat

; Operators
[
  "!"
  "!="
  "%"
  "%="
  "&"
  "&&"
  "&="
  "*"
  "*="
  "+"
  "+="
  "-"
  "-="
  ".."
  "..="
  "..."
  "/"
  "/="
  "<"
  "<<"
  "<<="
  "<="
  "="
  "=="
  ">"
  ">="
  ">>"
  ">>="
  "?"
  "@"
  "^"
  "^="
  "|"
  "|="
  "||"
] @operator

; Punctuation
[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

(type_arguments
  [
    "<"
    ">"
  ] @punctuation.bracket)

(type_parameters
  [
    "<"
    ">"
  ] @punctuation.bracket)

[
  ","
  "."
  ":"
  "::"
  ";"
  "->"
  "=>"
] @punctuation.delimiter

; Comments
[
  (line_comment)
  (block_comment)
] @comment

(line_comment
  (doc_comment)) @comment.documentation

(block_comment
  (doc_comment)) @comment.documentation
