(class_definition
  name: (identifier) @type)

(enum_definition
  name: (identifier) @type)

(object_definition
  name: (identifier) @type)

(trait_definition
  name: (identifier) @type)

(full_enum_case
  name: (identifier) @type)

(simple_enum_case
  name: (identifier) @type)

; variables
(class_parameter
  name: (identifier) @variable.parameter)

; types
(type_definition
  name: (type_identifier) @type.definition)

(type_identifier) @type

; val/var definitions
(val_definition
  pattern: (identifier) @variable)

(var_definition
  pattern: (identifier) @variable)

(val_declaration
  name: (identifier) @variable)

(var_declaration
  name: (identifier) @variable)

; method definition
(function_declaration
  name: (identifier) @function.method)

(function_definition
  name: (identifier) @function.method)

; imports
(import_declaration
  path: (identifier) @module)

(stable_identifier
  (identifier) @module)

(export_declaration
  path: (identifier) @module)

; method invocation
(call_expression
  function: (identifier) @function.call)

(call_expression
  function: (operator_identifier) @function.call)

(call_expression
  function: (field_expression
    field: (identifier) @function.method.call))

(generic_function
  function: (identifier) @function.call)

(interpolated_string_expression
  interpolator: (identifier) @function.call)

; function definitions
(function_definition
  name: (identifier) @function)

(parameter
  name: (identifier) @variable.parameter)

(binding
  name: (identifier) @variable.parameter)

(lambda_expression
  parameters: (identifier) @variable.parameter)

; expressions
(field_expression
  field: (identifier) @variable.member)

(infix_expression
  operator: (identifier) @operator)

(infix_expression
  operator: (operator_identifier) @operator)

; literals
(boolean_literal) @boolean
(integer_literal) @number
(floating_point_literal) @number.float

[
  (string)
  (interpolated_string_expression)
] @string

(character_literal) @character

(interpolation
  "$" @punctuation.special)

; keywords
[
  "case"
  "extends"
  "derives"
  "finally"
  "object"
  "override"
  "val"
  "var"
  "with"
  "given"
  "using"
  "end"
  "implicit"
  "extension"
] @keyword

[
  "enum"
  "class"
  "trait"
  "type"
] @keyword.type

[
  "abstract"
  "final"
  "lazy"
  "sealed"
  "private"
  "protected"
] @keyword.modifier

(null_literal) @constant.builtin

(annotation) @attribute

"new" @keyword.operator

[
  "else"
  "if"
  "match"
  "then"
] @keyword.conditional

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  "."
  ","
  ":"
] @punctuation.delimiter

[
  "do"
  "for"
  "while"
  "yield"
] @keyword.repeat

"def" @keyword.function

[
  "=>"
  "?=>"
  "="
  "!"
  "<-"
  "@"
] @operator

[
  "import"
  "export"
  "package"
] @keyword.import

[
  "try"
  "catch"
  "throw"
] @keyword.exception

"return" @keyword.return

[
  (comment)
  (block_comment)
] @comment

(operator_identifier) @operator
