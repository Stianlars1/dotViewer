(identifier) @variable

; Methods
(method_declaration
  name: (identifier) @function.method)

(method_invocation
  name: (identifier) @function.method.call)

(super) @function.builtin

; Parameters
(formal_parameter
  name: (identifier) @variable.parameter)

(spread_parameter
  (variable_declarator
    name: (identifier) @variable.parameter))

(inferred_parameters
  (identifier) @variable.parameter)

(lambda_expression
  parameters: (identifier) @variable.parameter)

; Operators
[
  "+"
  ":"
  "++"
  "-"
  "--"
  "&"
  "&&"
  "|"
  "||"
  "!"
  "!="
  "=="
  "*"
  "/"
  "%"
  "<"
  "<="
  ">"
  ">="
  "="
  "-="
  "+="
  "*="
  "/="
  "%="
  "->"
  "^"
  "^="
  "&="
  "|="
  "~"
  ">>"
  ">>>"
  "<<"
  "::"
] @operator

; Types
(interface_declaration
  name: (identifier) @type)

(annotation_type_declaration
  name: (identifier) @type)

(class_declaration
  name: (identifier) @type)

(record_declaration
  name: (identifier) @type)

(enum_declaration
  name: (identifier) @type)

(constructor_declaration
  name: (identifier) @type)

(type_identifier) @type

; Fields
(field_declaration
  declarator: (variable_declarator
    name: (identifier) @variable.member))

(field_access
  field: (identifier) @variable.member)

[
  (boolean_type)
  (integral_type)
  (floating_point_type)
  (void_type)
] @type.builtin

(this) @variable.builtin

; Annotations
(annotation
  "@" @attribute
  name: (identifier) @attribute)

(marker_annotation
  "@" @attribute
  name: (identifier) @attribute)

; Literals
(string_literal) @string
(escape_sequence) @string.escape
(character_literal) @character

[
  (hex_integer_literal)
  (decimal_integer_literal)
  (octal_integer_literal)
  (binary_integer_literal)
] @number

[
  (decimal_floating_point_literal)
  (hex_floating_point_literal)
] @number.float

[
  (true)
  (false)
] @boolean

(null_literal) @constant.builtin

; Keywords
[
  "assert"
  "default"
  "extends"
  "implements"
  "instanceof"
  "@interface"
  "permits"
  "to"
  "with"
] @keyword

[
  "record"
  "class"
  "enum"
  "interface"
] @keyword.type

[
  "abstract"
  "final"
  "native"
  "private"
  "protected"
  "public"
  "sealed"
  "static"
] @keyword.modifier

[
  "return"
  "yield"
] @keyword.return

"new" @keyword.operator

[
  "if"
  "else"
  "switch"
  "case"
  "when"
] @keyword.conditional

[
  "for"
  "while"
  "do"
  "continue"
  "break"
] @keyword.repeat

[
  "exports"
  "import"
  "module"
  "package"
] @keyword.import

; Punctuation
[
  ";"
  "."
  "..."
  ","
] @punctuation.delimiter

[
  "{"
  "}"
  "["
  "]"
  "("
  ")"
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

; Exceptions
[
  "throw"
  "throws"
  "finally"
  "try"
  "catch"
] @keyword.exception

; Comments
[
  (line_comment)
  (block_comment)
] @comment
