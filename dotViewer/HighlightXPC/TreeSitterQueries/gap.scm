; Curated structural captures: no editor-specific predicates or overlapping identifier rules.
(comment) @comment
(string) @string
(char) @string
(integer) @number
(float) @number
(bool) @builtin
(tilde) @builtin
(call function: (identifier) @function)
(assignment_statement left: (identifier) @function right: [(function) (atomic_function) (lambda)])
(parameters (identifier) @parameter)
(qualified_parameters (identifier) @parameter)
(lambda_parameters (identifier) @parameter)
(locals (identifier) @parameter)
(record_entry left: (identifier) @property)
(record_selector selector: (identifier) @property)
[
 "function" "local" "end" "if" "then" "elif" "else" "fi"
 "for" "while" "do" "od" "repeat" "until" "return"
 "and" "in" "mod" "not" "or" "rec" "atomic" "readonly" "readwrite"
] @keyword
(break_statement) @keyword
(continue_statement) @keyword
(quit_statement) @keyword
(pragma) @keyword
[ "+" "-" "*" "/" "^" "->" ":=" "<" "<=" "<>" "=" ">" ">=" ".." ] @operator
