[
  "use"
  "no"
  "require"
] @keyword.import

[
  "if"
  "elsif"
  "unless"
  "else"
] @keyword.conditional

[
  "while"
  "until"
  "for"
  "foreach"
] @keyword.repeat

[
  "try"
  "catch"
  "finally"
] @keyword.exception

"return" @keyword.return

[
  "sub"
  "method"
] @keyword.function

[
  "async"
  "await"
] @keyword.coroutine

[
  "map"
  "grep"
  "sort"
] @function.builtin

[
  "package"
  "class"
  "role"
] @keyword.import

[
  "defer"
  "do"
  "eval"
  "my"
  "our"
  "local"
  "state"
  "field"
  "last"
  "next"
  "redo"
  "goto"
  "undef"
] @keyword

(_
  operator: _ @operator)

"\\" @operator

(phaser_statement
  phase: _ @keyword)

[
  "or"
  "xor"
  "and"
  "eq"
  "ne"
  "cmp"
  "lt"
  "le"
  "ge"
  "gt"
  "isa"
] @keyword.operator

(eof_marker) @keyword.directive
(data_section) @comment

[
  (number)
  (version)
] @number

(boolean) @boolean

[
  (string_literal)
  (interpolated_string_literal)
  (quoted_word_list)
  (command_string)
  (heredoc_content)
  (replacement)
  (transliteration_content)
] @string

[
  (heredoc_token)
  (command_heredoc_token)
  (heredoc_end)
] @label

[
  (escape_sequence)
  (escaped_delimiter)
] @string.escape

[
  (quoted_regexp)
  (match_regexp)
  (regexp_content)
] @string.regexp

(use_statement
  (package) @type)

(package_statement
  (package) @type)

(class_statement
  (package) @type)

(require_expression
  (bareword) @type)

(subroutine_declaration_statement
  name: (bareword) @function)

(method_declaration_statement
  name: (bareword) @function)

(attribute_name) @attribute
(attribute_value) @string

(label) @label

(statement_label
  label: _ @label)

(function_call_expression
  (function) @function.call)

(method_call_expression
  (method) @function.method.call)

(method_call_expression
  invocant: (bareword) @type)

(func0op_call_expression
  function: _ @function.builtin)

(func1op_call_expression
  function: _ @function.builtin)

(function) @function

[
  (scalar)
  (array)
  (hash)
  (glob)
] @variable

(comment) @comment

[
  "=>"
  ","
  ";"
  "->"
] @punctuation.delimiter

[
  "["
  "]"
  "{"
  "}"
  "("
  ")"
] @punctuation.bracket
