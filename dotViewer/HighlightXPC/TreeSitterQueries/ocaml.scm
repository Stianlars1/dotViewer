; Modules
[
  (module_name)
  (module_type_name)
] @module

; Types
[
  (class_name)
  (class_type_name)
  (type_constructor)
] @type

[
  (constructor_name)
  (tag)
] @constructor

; Variables
[
  (value_name)
  (type_variable)
] @variable

(value_pattern) @variable.parameter

; Functions
(let_binding
  pattern: (value_name) @function
  (parameter))

(let_binding
  pattern: (value_name) @function
  body: [
    (fun_expression)
    (function_expression)
  ])

(value_specification
  (value_name) @function)

(external
  (value_name) @function)

(method_name) @function.method

(application_expression
  function: (value_path
    (value_name) @function.call))

; Fields
[
  (field_name)
  (instance_variable_name)
] @variable.member

; Labels
(label_name) @label

; Constants
(boolean) @boolean

[
  (number)
  (signed_number)
] @number

(character) @character

(string) @string

(quoted_string
  "{" @string
  "}" @string) @string

(escape_sequence) @string.escape

; Keywords
[
  "and"
  "as"
  "assert"
  "begin"
  "constraint"
  "end"
  "external"
  "in"
  "inherit"
  "initializer"
  "let"
  "match"
  "method"
  "module"
  "new"
  "of"
  "sig"
  "val"
  "when"
  "with"
] @keyword

[
  "object"
  "class"
  "struct"
  "type"
] @keyword.type

[
  "lazy"
  "mutable"
  "nonrec"
  "rec"
  "private"
  "virtual"
] @keyword.modifier

[
  "fun"
  "function"
  "functor"
] @keyword.function

[
  "if"
  "then"
  "else"
] @keyword.conditional

[
  "exception"
  "try"
] @keyword.exception

[
  "include"
  "open"
] @keyword.import

[
  "for"
  "to"
  "downto"
  "while"
  "do"
  "done"
] @keyword.repeat

; Punctuation
[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
  "[|"
  "|]"
] @punctuation.bracket

[
  ","
  "."
  ";"
  ":"
  "="
  "|"
  "~"
  "?"
  "+"
  "-"
  "!"
  ">"
  "&"
  "->"
  ";;"
  ":>"
  "+="
  ":="
  ".."
] @punctuation.delimiter

; Operators
[
  (prefix_operator)
  (sign_operator)
  (pow_operator)
  (mult_operator)
  (add_operator)
  (concat_operator)
  (rel_operator)
  (and_operator)
  (or_operator)
  (assign_operator)
  (hash_operator)
  (indexing_operator)
  (let_operator)
  (match_operator)
] @operator

[
  "*"
  "#"
  "::"
  "<-"
] @operator

; Attributes
(attribute_id) @attribute

; Comments
[
  (comment)
  (line_number_directive)
  (directive)
] @comment

(shebang) @keyword.directive
