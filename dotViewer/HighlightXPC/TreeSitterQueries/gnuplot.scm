; Gnuplot grammar nodes mapped to dotViewer's token palette.
(comment) @comment
"cmd" @keyword
["for" "while" "kw_cond" "kw_fn"] @keyword
["opt" "arg" "attr" "flag" "coord"] @attribute
"mod" @constant
(operator) @operator
(keyword_op) @keyword
(number) @number
(string_literal) @string
(escape_sequence) @escape
(function name: (identifier) @function)
