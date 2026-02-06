(comment) @comment

(conditional
  (_
    [
      "ifeq"
      "else"
      "ifneq"
      "ifdef"
      "ifndef"
    ] @keyword.conditional)
  "endif" @keyword.conditional)

(rule
  (targets
    (word) @function))

(rule
  [
    "&:"
    ":"
    "::"
    "|"
  ] @operator)

[
  "export"
  "unexport"
] @keyword.import

(override_directive
  "override" @keyword)

(include_directive
  [
    "include"
    "-include"
  ] @keyword.import)

(variable_assignment
  name: (word) @string.special
  [
    "?="
    ":="
    "::="
    "+="
    "="
  ] @operator)

(shell_assignment
  name: (word) @string.special
  "!=" @operator)

(define_directive
  "define" @keyword
  name: (word) @string.special
  "endef" @keyword)

; Use string to match bash
(variable_reference
  (word) @string) @operator

(shell_function
  [
    "$"
    "("
    ")"
  ] @operator
  "shell" @function.builtin)

(function_call
  [
    "$"
    "("
    ")"
  ] @operator)

(substitution_reference
  [
    "$"
    "("
    ")"
  ] @operator)

"\\" @punctuation.special
