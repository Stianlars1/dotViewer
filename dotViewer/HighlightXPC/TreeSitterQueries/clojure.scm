; Variables
(sym_lit) @variable

; Keywords
(kwd_lit) @string.special

; Strings
(str_lit) @string

; Numbers
(num_lit) @number

; Characters
(char_lit) @character

; Nil
(nil_lit) @constant.builtin

; Booleans
(bool_lit) @boolean

; Regular expressions
(regex_lit) @string.special

; Symbols in special positions
(list_lit
  .
  (sym_lit) @function.call)

; Special forms
(list_lit
  .
  (sym_lit) @keyword)

; Comments
(comment) @comment
(dis_expr) @comment

; Punctuation
[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

; Metadata
(meta_lit) @attribute

; Quote/Syntax quote
(quoting_lit) @operator
(syn_quoting_lit) @operator
(unquoting_lit) @operator
(unquote_splicing_lit) @operator

; Deref
(derefing_lit) @operator

; Anonymous function
(anon_fn_lit) @function

; Tags
(tagged_or_ctor_lit
  tag: (sym_lit) @attribute)

; Var quote
(var_quoting_lit) @operator

; Symbolic values
(symbolic_lit) @constant.builtin

