; Variables
(identifier) @variable
(field_ref) @variable

; Special variables
[
  "ARGC"
  "ARGV"
  "ENVIRON"
  "FILENAME"
  "FNR"
  "FS"
  "NF"
  "NR"
  "OFMT"
  "OFS"
  "ORS"
  "RLENGTH"
  "RS"
  "RSTART"
  "SUBSEP"
] @variable.builtin

; Functions
(func_def
  name: (identifier) @function)

(func_call
  name: (identifier) @function.call)

; Built-in functions
[
  "atan2"
  "cos"
  "sin"
  "exp"
  "log"
  "sqrt"
  "int"
  "rand"
  "srand"
  "gsub"
  "index"
  "length"
  "match"
  "split"
  "sprintf"
  "sub"
  "substr"
  "tolower"
  "toupper"
  "close"
  "fflush"
  "getline"
  "system"
  "mktime"
  "strftime"
  "systime"
  "gensub"
  "patsplit"
] @function.builtin

; Keywords
[
  "BEGIN"
  "END"
  "BEGINFILE"
  "ENDFILE"
] @keyword

[
  "function"
] @keyword.function

"return" @keyword.return

[
  "if"
  "else"
] @keyword.conditional

[
  "for"
  "while"
  "do"
  "break"
  "continue"
] @keyword.repeat

[
  "delete"
  "exit"
  "next"
  "nextfile"
] @keyword

[
  "in"
] @keyword.operator

[
  "print"
  "printf"
] @function.builtin

; Strings
(string) @string
(regex) @string.special

; Numbers
(number) @number

; Operators
[
  "="
  "+="
  "-="
  "*="
  "/="
  "%="
  "^="
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
  "^"
  "!"
  "&&"
  "||"
  "~"
  "!~"
  "++"
  "--"
  ">>"
  "|"
  "|&"
  "?"
  ":"
] @operator

; I/O
[
  ">"
  ">>"
  "<"
  "|"
  "|&"
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

