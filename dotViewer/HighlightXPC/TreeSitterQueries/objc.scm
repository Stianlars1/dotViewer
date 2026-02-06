; Types
(type_identifier) @type
(primitive_type) @type.builtin
(sized_type_specifier) @type.builtin

; Variables
(identifier) @variable

; Functions
(function_declarator
  declarator: (identifier) @function)

(call_expression
  function: (identifier) @function.call)

; ObjC Methods
(method_declaration
  selector: (identifier) @function)

(keyword_selector
  (keyword_declarator
    keyword: (identifier) @function))

(message_expression
  selector: (identifier) @function.call)

(keyword_argument
  keyword: (identifier) @function.call)

; ObjC Keywords
[
  "@interface"
  "@implementation"
  "@end"
  "@protocol"
  "@class"
  "@public"
  "@private"
  "@protected"
  "@package"
  "@property"
  "@synthesize"
  "@dynamic"
  "@optional"
  "@required"
  "@selector"
  "@encode"
  "@autoreleasepool"
  "@compatibility_alias"
  "@defs"
  "@synchronized"
  "@try"
  "@catch"
  "@finally"
  "@throw"
  "@available"
] @keyword

; C Keywords
[
  "break"
  "case"
  "continue"
  "default"
  "do"
  "else"
  "enum"
  "extern"
  "for"
  "goto"
  "if"
  "inline"
  "register"
  "return"
  "sizeof"
  "static"
  "struct"
  "switch"
  "typedef"
  "union"
  "volatile"
  "while"
  "const"
  "auto"
] @keyword

; Preprocessor
(preproc_include) @keyword.import
(preproc_def) @keyword.directive
(preproc_ifdef) @keyword.directive
(preproc_if) @keyword.directive
(preproc_else) @keyword.directive
(preproc_endif) @keyword.directive

; Strings
(string_literal) @string
(string_expression) @string
(system_lib_string) @string

; Numbers
(number_literal) @number

; Constants
[
  "nil"
  "Nil"
  "NULL"
  "YES"
  "NO"
  "true"
  "false"
] @constant.builtin

[
  "self"
  "super"
] @variable.builtin

; Operators
[
  "="
  "=="
  "!="
  "<"
  ">"
  "<="
  ">="
  "+"
  "-"
  "*"
  "/"
  "%"
  "&"
  "|"
  "^"
  "~"
  "!"
  "&&"
  "||"
  "<<"
  ">>"
  "+="
  "-="
  "*="
  "/="
  "%="
  "&="
  "|="
  "^="
  "<<="
  ">>="
  "++"
  "--"
  "->"
  "."
  "?"
  ":"
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

[
  ","
  ";"
] @punctuation.delimiter

; Comments
(comment) @comment

