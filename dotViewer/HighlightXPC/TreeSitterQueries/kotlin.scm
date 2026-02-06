; Identifiers
(simple_identifier) @variable

[
  "this"
  "super"
  "this@"
  "super@"
] @variable.builtin

(super_expression
  "@" @variable.builtin)

(class_parameter
  (simple_identifier) @variable.member)

(_
  (navigation_suffix
    (simple_identifier) @variable.member))

(enum_entry
  (simple_identifier) @constant)

(type_identifier) @type

(type_alias
  (type_identifier) @type.definition)

(package_header
  "package" @keyword)

(import_header
  "import" @keyword.import)

(wildcard_import) @character.special

(label) @label

; Function definitions
(function_declaration
  (simple_identifier) @function)

(getter
  "get" @function.builtin)

(setter
  "set" @function.builtin)

(primary_constructor) @constructor

(secondary_constructor
  "constructor" @constructor)

(constructor_invocation
  (user_type
    (type_identifier) @constructor))

(anonymous_initializer
  "init" @constructor)

(parameter
  (simple_identifier) @variable.parameter)

(parameter_with_optional_type
  (simple_identifier) @variable.parameter)

; Function calls
(call_expression
  .
  (simple_identifier) @function.call)

(callable_reference
  .
  (simple_identifier) @function.call)

(call_expression
  (navigation_expression
    (navigation_suffix
      (simple_identifier) @function.call) .))

; Literals
[
  (line_comment)
  (multiline_comment)
] @comment

(shebang_line) @keyword.directive

(real_literal) @number.float

[
  (integer_literal)
  (long_literal)
  (hex_literal)
  (bin_literal)
  (unsigned_literal)
] @number

[
  (null_literal)
  (boolean_literal)
] @boolean

(character_literal) @character
(string_literal) @string

(character_literal
  (character_escape_seq) @string.escape)

; Keywords
(type_alias
  "typealias" @keyword)

(companion_object
  "companion" @keyword)

[
  (class_modifier)
  (member_modifier)
  (function_modifier)
  (property_modifier)
  (platform_modifier)
  (variance_modifier)
  (parameter_modifier)
  (visibility_modifier)
  (reification_modifier)
  (inheritance_modifier)
] @keyword.modifier

[
  "val"
  "var"
] @keyword

[
  "enum"
  "class"
  "object"
  "interface"
] @keyword.type

[
  "return"
  "return@"
] @keyword.return

"suspend" @keyword.coroutine

"fun" @keyword.function

[
  "if"
  "else"
  "when"
] @keyword.conditional

[
  "for"
  "do"
  "while"
  "continue"
  "continue@"
  "break"
  "break@"
] @keyword.repeat

[
  "try"
  "catch"
  "throw"
  "finally"
] @keyword.exception

(annotation
  "@" @attribute)

(annotation
  (user_type
    (type_identifier) @attribute))

; Operators & Punctuation
[
  "!"
  "!="
  "!=="
  "="
  "=="
  "==="
  ">"
  ">="
  "<"
  "<="
  "||"
  "&&"
  "+"
  "++"
  "+="
  "-"
  "--"
  "-="
  "*"
  "*="
  "/"
  "/="
  "%"
  "%="
  "?."
  "?:"
  "!!"
  "is"
  "!is"
  "in"
  "!in"
  "as"
  "as?"
  ".."
  "->"
] @operator

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  "."
  ","
  ";"
  ":"
  "::"
] @punctuation.delimiter

(type_arguments
  [
    "<"
    ">"
  ] @punctuation.delimiter)

(type_parameters
  [
    "<"
    ">"
  ] @punctuation.delimiter)

(string_literal
  "$" @punctuation.special)

(string_literal
  "${" @punctuation.special
  "}" @punctuation.special)
