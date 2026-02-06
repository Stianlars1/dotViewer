(variable) @variable

; Literals and comments
(integer) @number
(negation) @number
(char) @character
(string) @string
(comment) @comment
(haddock) @comment.documentation

; Punctuation
[
  "("
  ")"
  "{"
  "}"
  "["
  "]"
] @punctuation.bracket

[
  ","
  ";"
] @punctuation.delimiter

; Keywords, operators, includes
[
  "forall"
] @keyword.repeat

(pragma) @keyword.directive

[
  "if"
  "then"
  "else"
  "case"
  "of"
] @keyword.conditional

[
  "import"
  "qualified"
  "module"
] @keyword.import

[
  (operator)
  (constructor_operator)
  (all_names)
  "."
  ".."
  "="
  "|"
  "::"
  "=>"
  "->"
  "<-"
  "\\"
  "`"
  "@"
] @operator

(wildcard) @character.special

(module
  (module_id) @module)

[
  "where"
  "let"
  "in"
  "class"
  "instance"
  "pattern"
  "data"
  "newtype"
  "family"
  "type"
  "as"
  "hiding"
  "deriving"
  "via"
  "stock"
  "anyclass"
  "do"
  "mdo"
  "rec"
  "infix"
  "infixl"
  "infixr"
] @keyword

; Functions and variables
(decl/signature
  name: (variable) @function)

(decl/function
  name: (variable) @function)

(decl/bind
  name: (variable) @function)

(apply
  (expression/variable) @function.call)

; Types
(name) @type
(type/unit) @type
(type/star) @type
(constructor) @constructor

; Fields
(field_name
  (variable) @variable.member)
