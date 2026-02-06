; Variables
(identifier) @variable

; Types
(derived_type
  (type_name) @type)

(intrinsic_type) @type.builtin

; Functions
(function
  name: (name) @function)

(subroutine
  name: (name) @function)

(function_call
  name: (identifier) @function.call)

(subroutine_call
  name: (identifier) @function.call)

(module
  name: (name) @module)

; Keywords
[
  "program"
  "endprogram"
  "end"
  "implicit"
  "none"
  "contains"
  "block"
  "endblock"
  "associate"
  "endassociate"
  "critical"
  "endcritical"
  "common"
  "equivalence"
  "data"
  "save"
  "target"
  "pointer"
  "allocatable"
  "dimension"
  "parameter"
  "external"
  "intrinsic"
  "intent"
  "optional"
  "value"
  "sequence"
  "result"
  "recursive"
  "pure"
  "elemental"
  "class"
  "abstract"
  "extends"
  "private"
  "public"
  "protected"
  "deferred"
  "non_overridable"
  "nopass"
  "pass"
  "generic"
  "procedure"
  "final"
  "enum"
  "enumerator"
  "endenum"
  "select"
  "rank"
  "where"
  "elsewhere"
  "endwhere"
  "forall"
  "endforall"
  "only"
  "operator"
  "assignment"
  "namelist"
  "volatile"
  "asynchronous"
  "bind"
  "entry"
  "goto"
  "stop"
  "error"
  "backspace"
  "rewind"
  "endfile"
  "flush"
  "inquire"
  "format"
] @keyword

[
  "module"
  "endmodule"
  "submodule"
  "endsubmodule"
  "type"
  "endtype"
  "interface"
  "endinterface"
] @keyword.type

[
  "function"
  "endfunction"
  "subroutine"
  "endsubroutine"
] @keyword.function

"return" @keyword.return

[
  "if"
  "then"
  "else"
  "elseif"
  "endif"
  "selectcase"
  "case"
  "default"
  "endselect"
] @keyword.conditional

[
  "do"
  "enddo"
  "while"
  "cycle"
  "exit"
] @keyword.repeat

[
  "use"
  "include"
  "import"
] @keyword.import

[
  "read"
  "write"
  "print"
  "open"
  "close"
  "allocate"
  "deallocate"
  "nullify"
  "call"
] @keyword

; Operators
[
  "="
  "=="
  "/="
  "<"
  "<="
  ">"
  ">="
  "+"
  "-"
  "*"
  "/"
  "**"
  "//"
  ":"
  "%"
  "=>"
] @operator

[
  ".and."
  ".or."
  ".not."
  ".eqv."
  ".neqv."
  ".eq."
  ".ne."
  ".lt."
  ".le."
  ".gt."
  ".ge."
  ".true."
  ".false."
] @keyword.operator

; Literals
(number_literal) @number
(string_literal) @string
(boolean_literal) @boolean

; Punctuation
[
  "("
  ")"
  "["
  "]"
] @punctuation.bracket

[
  ","
  "::"
] @punctuation.delimiter

; Comments
(comment) @comment

