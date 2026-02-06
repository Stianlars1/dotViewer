; Character classes
(character_class) @character.special

; Escape sequences
(identity_escape) @string.escape
(control_escape) @string.escape
(class_escape) @string.escape
(decimal_escape) @string.escape

; Assertions
[
  (start_assertion)
  (end_assertion)
  (boundary_assertion)
  (non_boundary_assertion)
] @keyword

(lookahead_assertion) @keyword
(lookbehind_assertion) @keyword

; Quantifiers
[
  (zero_or_more)
  (one_or_more)
  (optional)
  (count_quantifier)
  (lazy)
] @operator

; Alternation
(alternation
  "|" @operator)

; Groups
(anonymous_capturing_group
  "(" @punctuation.bracket
  ")" @punctuation.bracket)

(named_capturing_group
  "(" @punctuation.bracket
  ")" @punctuation.bracket)

(non_capturing_group
  "(" @punctuation.bracket
  ")" @punctuation.bracket)

; Group names
(group_name) @variable

; Character class brackets
(character_class
  "[" @punctuation.bracket
  "]" @punctuation.bracket)

; Ranges
(class_range
  "-" @operator)

; Pattern characters
(pattern_character) @string

; Any character
(any_character) @string.special

; Disjunction
(disjunction) @operator

