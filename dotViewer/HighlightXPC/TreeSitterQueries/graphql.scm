; Types
(named_type
  (name) @type)

(scalar_type_definition
  (name) @type)

(object_type_definition
  (name) @type)

(interface_type_definition
  (name) @type)

(union_type_definition
  (name) @type)

(enum_type_definition
  (name) @type)

(input_object_type_definition
  (name) @type)

(type_condition
  (named_type
    (name) @type))

; Variables
(variable) @variable

; Fields
(field
  (name) @variable.member)

; Arguments
(argument
  (name) @variable.parameter)

; Directives
(directive
  (name) @attribute)

; Enum values
(enum_value
  (name) @constant)

; Operations
(operation_definition
  (name) @function)

(fragment_definition
  (name) @function)

(fragment_spread
  (name) @function)

; Strings
(string_value) @string

; Numbers
(int_value) @number
(float_value) @number.float

; Booleans
(boolean_value) @boolean

(null_value) @constant.builtin

; Keywords
[
  "query"
  "mutation"
  "subscription"
  "fragment"
  "on"
  "type"
  "schema"
  "extend"
  "scalar"
  "interface"
  "union"
  "enum"
  "input"
  "directive"
  "implements"
  "repeatable"
] @keyword

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
  ":"
  "="
  "|"
  "&"
  "!"
  "..."
  "@"
] @punctuation.delimiter

; Comments
(comment) @comment

