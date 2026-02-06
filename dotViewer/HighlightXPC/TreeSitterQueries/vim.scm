; Variables
(identifier) @variable
(scope) @module
(scoped_identifier
  (scope) @module)

; Options
(option_name) @variable.builtin
(set_value) @string

; Environment variables
(env_variable) @constant

; Register
(register) @string.special

; Keywords
[
  "let"
  "unlet"
  "const"
  "set"
  "setlocal"
  "setglobal"
  "execute"
  "call"
  "normal"
  "silent"
  "echo"
  "echon"
  "echohl"
  "echomsg"
  "echoerr"
  "autocmd"
  "augroup"
  "highlight"
  "command"
  "comclear"
  "delcommand"
  "syntax"
  "filetype"
  "source"
  "runtime"
  "map"
  "nmap"
  "vmap"
  "xmap"
  "smap"
  "omap"
  "imap"
  "lmap"
  "cmap"
  "tmap"
  "noremap"
  "nnoremap"
  "vnoremap"
  "xnoremap"
  "snoremap"
  "onoremap"
  "inoremap"
  "lnoremap"
  "cnoremap"
  "tnoremap"
  "unmap"
  "mapclear"
  "abort"
  "range"
  "bang"
  "bar"
  "buffer"
  "register"
  "complete"
  "keepjumps"
  "silent"
  "verbose"
  "wincmd"
  "sign"
] @keyword

[
  "function"
  "endfunction"
] @keyword.function

[
  "if"
  "else"
  "elseif"
  "endif"
] @keyword.conditional

[
  "for"
  "endfor"
  "while"
  "endwhile"
  "break"
  "continue"
] @keyword.repeat

[
  "try"
  "catch"
  "finally"
  "endtry"
  "throw"
] @keyword.exception

"return" @keyword.return

; Functions
(function_definition
  name: (_) @function)

(call_expression
  function: (identifier) @function.call)

(call_expression
  function: (scoped_identifier
    (identifier) @function.call))

; Numbers
(integer_literal) @number
(float_literal) @number.float

; Strings
(string_literal) @string
(literal_dictionary) @string

; Booleans
[
  "true"
  "false"
  "v:true"
  "v:false"
  "v:none"
  "v:null"
] @boolean

; Operators
[
  "="
  "+="
  "-="
  ".="
  "..="
  "*="
  "/="
  "%="
  "=="
  "!="
  ">"
  ">="
  "<"
  "<="
  "=~"
  "!~"
  "+"
  "-"
  "*"
  "/"
  "%"
  "."
  ".."
  "!"
  "&&"
  "||"
  "is"
  "isnot"
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
  ":"
  "|"
  "#"
] @punctuation.delimiter

; Comments
(comment) @comment

