; Variables
(identifier) @variable

; Types
(type_identifier) @type

; Modules
(module) @module

; Functions
(function
  name: (identifier) @function)

(external_function
  name: (identifier) @function)

(function_call
  function: (identifier) @function.call)

(field_access
  record: (identifier) @variable
  field: (label) @variable.member)

; Parameters
(function_parameter
  name: (identifier) @variable.parameter)

; Labels
(label) @variable.member

; Constructors
(constructor_name) @constructor

; Keywords
[
  "as"
  "assert"
  "auto"
  "delegate"
  "derive"
  "echo"
  "let"
  "todo"
  "panic"
  "opaque"
  "const"
] @keyword

[
  "type"
] @keyword.type

[
  "fn"
] @keyword.function

[
  "case"
  "if"
  "else"
] @keyword.conditional

[
  "use"
  "import"
] @keyword.import

[
  "pub"
  "external"
] @keyword.modifier

; Operators
[
  "="
  "=="
  "!="
  "<"
  "<="
  ">"
  ">="
  "+"
  "-"
  "*"
  "/"
  "%"
  "<>"
  "|>"
  ".."
  "->"
  "<-"
  "|"
  "&&"
  "||"
] @operator

; Literals
(integer) @number
(float) @number.float
(string) @string

[
  "True"
  "False"
] @boolean

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
  "."
  ":"
  "#"
  "<<"
  ">>"
] @punctuation.delimiter

; Comments
(comment) @comment
(module_comment) @comment
(statement_comment) @comment

