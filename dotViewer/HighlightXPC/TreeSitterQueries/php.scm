; Keywords
[
  "and"
  "as"
  "instanceof"
  "or"
  "xor"
] @keyword.operator

[
  "fn"
  "function"
] @keyword.function

[
  "clone"
  "declare"
  "default"
  "echo"
  "enddeclare"
  "extends"
  "global"
  "goto"
  "implements"
  "insteadof"
  "print"
  "new"
  "unset"
] @keyword

[
  "enum"
  "class"
  "interface"
  "namespace"
  "trait"
] @keyword.type

[
  "abstract"
  "const"
  "final"
  "private"
  "protected"
  "public"
  "readonly"
  "static"
] @keyword.modifier

[
  "return"
  "exit"
  "yield"
  "yield from"
] @keyword.return

[
  "case"
  "else"
  "elseif"
  "endif"
  "endswitch"
  "if"
  "switch"
  "match"
  "??"
] @keyword.conditional

[
  "break"
  "continue"
  "do"
  "endfor"
  "endforeach"
  "endwhile"
  "for"
  "foreach"
  "while"
] @keyword.repeat

[
  "catch"
  "finally"
  "throw"
  "try"
] @keyword.exception

[
  "include_once"
  "include"
  "require_once"
  "require"
  "use"
] @keyword.import

[
  ","
  ";"
  ":"
  "\\"
] @punctuation.delimiter

[
  (php_tag)
  (php_end_tag)
  "("
  ")"
  "["
  "]"
  "{"
  "}"
  "#["
] @punctuation.bracket

[
  "="
  "."
  "-"
  "*"
  "/"
  "+"
  "%"
  "**"
  "~"
  "|"
  "^"
  "&"
  "<<"
  ">>"
  "<<<"
  "->"
  "?->"
  "=>"
  "<"
  "<="
  ">="
  ">"
  "<>"
  "<=>"
  "=="
  "!="
  "==="
  "!=="
  "!"
  "&&"
  "||"
  ".="
  "-="
  "+="
  "*="
  "/="
  "%="
  "**="
  "&="
  "|="
  "^="
  "<<="
  ">>="
  "??="
  "--"
  "++"
  "@"
  "::"
] @operator

; Variables
(variable_name) @variable

; Constants
(const_declaration
  (const_element
    (name) @constant))

; Types
[
  (primitive_type)
  (cast_type)
  (bottom_type)
] @type.builtin

(named_type
  (name) @type)

(class_declaration
  name: (name) @type)

(enum_declaration
  name: (name) @type)

(interface_declaration
  name: (name) @type)

(trait_declaration
  name: (name) @type)

; Functions
(method_declaration
  name: (name) @function.method)

(function_call_expression
  function: (name) @function.call)

(scoped_call_expression
  name: (name) @function.call)

(member_call_expression
  name: (name) @function.method.call)

(function_definition
  name: (name) @function)

; Parameters
(simple_parameter
  name: (variable_name) @variable.parameter)

; Member
(property_element
  (variable_name) @property)

(member_access_expression
  name: (name) @variable.member)

; Namespace
(namespace_definition
  name: (namespace_name
    (name) @module))

(namespace_name
  (name) @module)

; Attributes
(attribute_list) @attribute

; Basic tokens
[
  (string)
  (encapsed_string)
  (heredoc_body)
  (nowdoc_body)
  (shell_command_expression)
] @string

(escape_sequence) @string.escape

[
  (heredoc_start)
  (heredoc_end)
] @label

(boolean) @boolean
(null) @constant.builtin
(integer) @number
(float) @number.float

(comment) @comment
