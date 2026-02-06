; Selectors
(tag_name) @type
(universal_selector) @type
(class_selector
  (class_name) @variable)
(id_selector
  (id_name) @variable)
(pseudo_class_selector
  (class_name) @attribute)
(pseudo_element_selector
  (tag_name) @attribute)
(attribute_selector
  (attribute_name) @attribute)
(nesting_selector) @variable.builtin
(namespace_name) @module

; Properties
(property_name) @variable.member
(feature_name) @variable.member

; Values
(plain_value) @string
(color_value) @string.special
(string_value) @string
(integer_value) @number
(float_value) @number.float

; Units
(unit) @type

; Functions
(function_name) @function.call
(call_expression
  function: (identifier) @function.call)

; Variables
(variable) @variable
(variable_name) @variable

; Keywords
[
  "and"
  "not"
  "or"
  "only"
  "from"
  "to"
  "through"
  "selector"
] @keyword

[
  "@media"
  "@import"
  "@charset"
  "@namespace"
  "@supports"
  "@keyframes"
  "@font-face"
  "@layer"
  "@at-root"
  "@use"
  "@forward"
  "@extend"
  "@mixin"
  "@include"
  "@function"
  "@return"
  "@error"
  "@warn"
  "@debug"
  "@content"
] @keyword.import

[
  "@if"
  "@else"
] @keyword.conditional

[
  "@each"
  "@for"
  "@while"
] @keyword.repeat

; Important
"!important" @keyword

; Operators
[
  "~"
  ">"
  "+"
  "-"
  "*"
  "/"
  "%"
  "="
  "=="
  "!="
  ">"
  ">="
  "<="
  "<"
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
  ","
  ";"
  ":"
  "::"
] @punctuation.delimiter

; Comments
(comment) @comment
(single_line_comment) @comment

