; Variables
(variable_name) @variable
(variable_expansion) @variable

; Commands
(command
  name: (word) @function.call)

; Functions
(function_definition
  name: (word) @function)

; Strings
(double_quote_string) @string
(single_quote_string) @string

; Escape sequences
(escape_sequence) @string.escape

; Numbers
(integer) @number
(float) @number.float

; Comments
(comment) @comment

; Keywords
[
  "and"
  "or"
  "not"
] @keyword.operator

[
  "if"
  "else"
  "switch"
  "case"
] @keyword.conditional

[
  "for"
  "while"
  "break"
  "continue"
] @keyword.repeat

[
  "function"
  "end"
  "begin"
  "return"
] @keyword

[
  "set"
  "set_color"
  "test"
  "command"
  "builtin"
  "exec"
  "eval"
  "source"
  "emit"
  "read"
  "string"
  "math"
  "count"
  "contains"
  "status"
  "argparse"
  "abbr"
  "alias"
  "bind"
  "block"
  "cd"
  "complete"
  "echo"
  "exit"
  "fg"
  "bg"
  "jobs"
  "printf"
  "random"
  "realpath"
  "time"
  "type"
  "ulimit"
  "wait"
] @function.builtin

; Redirection
(file_redirect) @operator
(stream_redirect) @operator

; Pipes
(pipe) @operator

; Glob
(glob) @string.special

; Operators
[
  "="
  "!="
  "-eq"
  "-ne"
  "-lt"
  "-gt"
  "-le"
  "-ge"
  "-n"
  "-z"
  "-f"
  "-d"
  "-e"
  "-r"
  "-w"
  "-x"
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
  ";"
] @punctuation.delimiter

