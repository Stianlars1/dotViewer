; Identifiers
(identifier) @variable

; Types
(typeIdentifier) @type

; Functions/Procedures
(funcDeclaration
  name: (identifier) @function)

(procDeclaration
  name: (identifier) @function)

(funcHeader
  name: (identifier) @function)

(procHeader
  name: (identifier) @function)

(call
  function: (identifier) @function.call)

; Keywords
[
  "program"
  "unit"
  "library"
  "uses"
  "begin"
  "end"
  "var"
  "const"
  "type"
  "array"
  "of"
  "record"
  "set"
  "file"
  "class"
  "object"
  "interface"
  "implementation"
  "initialization"
  "finalization"
  "constructor"
  "destructor"
  "inherited"
  "property"
  "with"
  "as"
  "is"
  "in"
  "out"
  "nil"
  "self"
  "result"
  "label"
  "goto"
  "packed"
  "inline"
  "absolute"
  "forward"
  "external"
  "resourcestring"
  "threadvar"
  "exports"
  "name"
  "index"
  "read"
  "write"
  "default"
  "stored"
  "nodefault"
  "dispid"
  "implements"
  "overload"
  "override"
  "reintroduce"
  "virtual"
  "dynamic"
  "abstract"
  "message"
  "static"
  "cdecl"
  "pascal"
  "register"
  "safecall"
  "stdcall"
  "published"
  "public"
  "private"
  "protected"
  "strict"
  "automated"
] @keyword

[
  "function"
  "procedure"
] @keyword.function

[
  "if"
  "then"
  "else"
  "case"
] @keyword.conditional

[
  "for"
  "to"
  "downto"
  "while"
  "do"
  "repeat"
  "until"
  "break"
  "continue"
] @keyword.repeat

[
  "try"
  "except"
  "finally"
  "raise"
  "on"
] @keyword.exception

; Operators
[
  ":="
  "="
  "<>"
  "<"
  ">"
  "<="
  ">="
  "+"
  "-"
  "*"
  "/"
  "@"
  "^"
] @operator

[
  "not"
  "and"
  "or"
  "xor"
  "div"
  "mod"
  "shl"
  "shr"
] @keyword.operator

; Literals
(integerLiteral) @number
(realLiteral) @number.float
(stringLiteral) @string
(booleanLiteral) @boolean
(charLiteral) @character

; Punctuation
[
  "("
  ")"
  "["
  "]"
] @punctuation.bracket

[
  ","
  ";"
  ":"
  "."
  ".."
] @punctuation.delimiter

; Comments
(comment) @comment

