(identifier) @variable

(method_declaration
  name: (identifier) @function.method)

(local_function_statement
  name: (identifier) @function.method)

(event_declaration
  name: (identifier) @variable.member)

(member_access_expression
  name: (identifier) @variable.member)

(invocation_expression
  (member_access_expression
    name: (identifier) @function.method.call))

(namespace_declaration
  name: [
    (qualified_name)
    (identifier)
  ] @module)

(invocation_expression
  (identifier) @function.method.call)

(field_declaration
  (variable_declaration
    (variable_declarator
      (identifier) @variable.member)))

(initializer_expression
  (assignment_expression
    left: (identifier) @variable.member))

(parameter
  name: (identifier) @variable.parameter)

(integer_literal) @number
(real_literal) @number.float
(null_literal) @constant.builtin
(character_literal) @character

[
  (string_literal)
  (raw_string_literal)
  (verbatim_string_literal)
  (interpolated_string_expression)
] @string

(escape_sequence) @string.escape

[
  "true"
  "false"
] @boolean

(predefined_type) @type.builtin
(implicit_type) @keyword

(comment) @comment

(using_directive
  (identifier) @type)

(property_declaration
  name: (identifier) @property)

(property_declaration
  type: (identifier) @type)

(nullable_type
  type: (identifier) @type)

(interface_declaration
  name: (identifier) @type)

(class_declaration
  name: (identifier) @type)

(record_declaration
  name: (identifier) @type)

(struct_declaration
  name: (identifier) @type)

(enum_declaration
  name: (identifier) @type)

(delegate_declaration
  name: (identifier) @type)

(enum_member_declaration
  name: (identifier) @variable.member)

(type_identifier) @type

[
  "assembly"
  "module"
  "this"
  "base"
] @variable.builtin

(constructor_declaration
  name: (identifier) @constructor)

(destructor_declaration
  name: (identifier) @constructor)

(variable_declaration
  (identifier) @type)

(object_creation_expression
  (identifier) @type)

(base_list
  (identifier) @type)

(type_argument_list
  (identifier) @type)

(type_parameter_list
  (type_parameter) @type)

(attribute
  name: (identifier) @attribute)

[
  "#define"
  "#undef"
] @keyword.directive.define

[
  "#if"
  "#elif"
  "#else"
  "#endif"
  "#region"
  "#endregion"
  "#line"
  "#pragma"
  "#nullable"
  "#error"
  (shebang_directive)
] @keyword.directive

[
  "if"
  "else"
  "switch"
  "break"
  "case"
  "when"
] @keyword.conditional

[
  "while"
  "for"
  "do"
  "continue"
  "goto"
  "foreach"
] @keyword.repeat

[
  "try"
  "catch"
  "throw"
  "finally"
] @keyword.exception

[
  "+"
  "?"
  ":"
  "++"
  "-"
  "--"
  "&"
  "&&"
  "|"
  "||"
  "!"
  "!="
  "=="
  "*"
  "/"
  "%"
  "<"
  "<="
  ">"
  ">="
  "="
  "-="
  "+="
  "*="
  "/="
  "%="
  "^"
  "^="
  "&="
  "|="
  "~"
  ">>"
  ">>>"
  "<<"
  "<<="
  ">>="
  ">>>="
  "=>"
  "??"
  "??="
  ".."
] @operator

[
  ";"
  "."
  ","
  ":"
  "::"
] @punctuation.delimiter

[
  "["
  "]"
  "{"
  "}"
  "("
  ")"
] @punctuation.bracket

(interpolation_brace) @punctuation.special

(type_parameter_list
  [
    "<"
    ">"
  ] @punctuation.bracket)

(type_argument_list
  [
    "<"
    ">"
  ] @punctuation.bracket)

[
  "using"
  "as"
] @keyword.import

[
  "with"
  "new"
  "typeof"
  "sizeof"
  "is"
  "and"
  "or"
  "not"
  "stackalloc"
  "in"
  "out"
  "ref"
] @keyword.operator

[
  "lock"
  "params"
  "operator"
  "default"
  "implicit"
  "explicit"
  "override"
  "get"
  "set"
  "init"
  "where"
  "add"
  "remove"
  "checked"
  "unchecked"
  "fixed"
  "alias"
  "unsafe"
] @keyword

[
  "enum"
  "record"
  "class"
  "struct"
  "interface"
  "namespace"
  "event"
  "delegate"
] @keyword.type

[
  "async"
  "await"
] @keyword.coroutine

[
  "const"
  "extern"
  "readonly"
  "static"
  "volatile"
  "required"
  "abstract"
  "private"
  "protected"
  "internal"
  "public"
  "partial"
  "sealed"
  "virtual"
  "global"
] @keyword.modifier

[
  "return"
  "yield"
] @keyword.return
