; C++ extends C patterns

(identifier) @variable

[
  "default"
  "goto"
  "asm"
  "__asm__"
] @keyword

[
  "enum"
  "struct"
  "union"
  "typedef"
] @keyword.type

[
  "sizeof"
  "offsetof"
] @keyword.operator

"return" @keyword.return

[
  "while"
  "for"
  "do"
  "continue"
  "break"
] @keyword.repeat

[
  "if"
  "else"
  "case"
  "switch"
] @keyword.conditional

[
  "#if"
  "#ifdef"
  "#ifndef"
  "#else"
  "#elif"
  "#endif"
  (preproc_directive)
] @keyword.directive

"#define" @keyword.directive
"#include" @keyword.import

[
  ";"
  ":"
  ","
  "."
  "::"
] @punctuation.delimiter

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  "="
  "-"
  "*"
  "/"
  "+"
  "%"
  "~"
  "|"
  "&"
  "^"
  "<<"
  ">>"
  "->"
  "<"
  "<="
  ">="
  ">"
  "=="
  "!="
  "!"
  "&&"
  "||"
  "-="
  "+="
  "*="
  "/="
  "%="
  "|="
  "&="
  "^="
  ">>="
  "<<="
  "--"
  "++"
  "<=>"
] @operator

[
  (true)
  (false)
] @boolean

(string_literal) @string
(raw_string_literal) @string
(system_lib_string) @string
(escape_sequence) @string.escape
(null) @constant.builtin
(number_literal) @number
(char_literal) @character

(field_identifier) @property
(field_designator) @property
(statement_identifier) @label

[
  (type_identifier)
  (type_descriptor)
] @type

(auto) @type.builtin
(primitive_type) @type.builtin

(storage_class_specifier) @keyword.modifier

[
  (type_qualifier)
  "__extension__"
] @keyword.modifier

(type_definition
  declarator: (type_identifier) @type.definition)

(enumerator
  name: (identifier) @constant)

(preproc_def
  name: (_) @constant.macro)

(preproc_ifdef
  name: (identifier) @constant.macro)

(preproc_defined
  (identifier) @constant.macro)

(call_expression
  function: (identifier) @function.call)

(call_expression
  function: (field_expression
    field: (field_identifier) @function.call))

(function_declarator
  declarator: (identifier) @function)

(function_declarator
  declarator: (field_identifier) @function.method)

(preproc_function_def
  name: (identifier) @function.macro)

(comment) @comment

(parameter_declaration
  declarator: (identifier) @variable.parameter)

(parameter_declaration
  declarator: (reference_declarator) @variable.parameter)

(optional_parameter_declaration
  declarator: (_) @variable.parameter)

(field_declaration
  (field_identifier) @variable.member)

(namespace_identifier) @module

(concept_definition
  name: (identifier) @type.definition)

(alias_declaration
  name: (type_identifier) @type.definition)

; C++ keywords
[
  "try"
  "catch"
  "noexcept"
  "throw"
] @keyword.exception

[
  "decltype"
  "explicit"
  "friend"
  "override"
  "using"
  "requires"
  "constexpr"
] @keyword

[
  "class"
  "namespace"
  "template"
  "typename"
  "concept"
] @keyword.type

[
  "co_await"
  "co_yield"
  "co_return"
] @keyword.coroutine

[
  "public"
  "private"
  "protected"
  "final"
  "virtual"
] @keyword.modifier

[
  "new"
  "delete"
  "xor"
  "bitand"
  "bitor"
  "compl"
  "not"
  "xor_eq"
  "and_eq"
  "or_eq"
  "not_eq"
  "and"
  "or"
] @keyword.operator

(this) @variable.builtin

(operator_name) @function
"operator" @function
"static_assert" @function.builtin

[
  "__attribute__"
  "__declspec"
  (attribute_declaration)
] @attribute

(template_argument_list
  [
    "<"
    ">"
  ] @punctuation.bracket)

(template_parameter_list
  [
    "<"
    ">"
  ] @punctuation.bracket)
