(invocation
  (object_reference
    name: (identifier) @function.call))

(relation
  alias: (identifier) @variable)

(field
  name: (identifier) @variable.member)

(column_definition
  name: (identifier) @variable.member)

(term
  alias: (identifier) @variable)

(literal) @string

(comment) @comment
(marginalia) @comment

(parameter) @variable.parameter

[
  (keyword_true)
  (keyword_false)
] @boolean

[
  (keyword_asc)
  (keyword_desc)
  (keyword_default)
  (keyword_collate)
  (keyword_auto_increment)
] @attribute

[
  (keyword_case)
  (keyword_when)
  (keyword_then)
  (keyword_else)
] @keyword.conditional

[
  (keyword_select)
  (keyword_from)
  (keyword_where)
  (keyword_index)
  (keyword_join)
  (keyword_primary)
  (keyword_delete)
  (keyword_create)
  (keyword_insert)
  (keyword_distinct)
  (keyword_replace)
  (keyword_update)
  (keyword_into)
  (keyword_values)
  (keyword_set)
  (keyword_left)
  (keyword_right)
  (keyword_outer)
  (keyword_inner)
  (keyword_full)
  (keyword_order)
  (keyword_partition)
  (keyword_group)
  (keyword_with)
  (keyword_as)
  (keyword_having)
  (keyword_limit)
  (keyword_offset)
  (keyword_table)
  (keyword_key)
  (keyword_references)
  (keyword_foreign)
  (keyword_constraint)
  (keyword_force)
  (keyword_if)
  (keyword_exists)
  (keyword_column)
  (keyword_alter)
  (keyword_drop)
  (keyword_add)
  (keyword_view)
  (keyword_end)
  (keyword_is)
  (keyword_using)
  (keyword_between)
  (keyword_window)
  (keyword_type)
  (keyword_rename)
  (keyword_to)
  (keyword_schema)
  (keyword_all)
  (keyword_any)
  (keyword_returning)
  (keyword_begin)
  (keyword_commit)
  (keyword_rollback)
  (keyword_transaction)
  (keyword_only)
  (keyword_like)
  (keyword_over)
  (keyword_range)
  (keyword_rows)
  (keyword_function)
  (keyword_return)
  (keyword_returns)
  (keyword_trigger)
  (keyword_database)
  (keyword_sequence)
  (keyword_start)
  (keyword_each)
  (keyword_execute)
  (keyword_procedure)
] @keyword

[
  (keyword_unique)
  (keyword_cascade)
  (keyword_restrict)
  (keyword_check)
  (keyword_option)
  (keyword_local)
  (keyword_cascaded)
  (keyword_nothing)
  (keyword_temp)
  (keyword_temporary)
] @keyword.modifier

[
  (keyword_int)
  (keyword_null)
  (keyword_boolean)
  (keyword_binary)
  (keyword_bit)
  (keyword_character)
  (keyword_smallserial)
  (keyword_serial)
  (keyword_bigserial)
  (keyword_smallint)
  (keyword_bigint)
  (keyword_decimal)
  (keyword_float)
  (keyword_double)
  (keyword_numeric)
  (keyword_real)
  (keyword_char)
  (keyword_varchar)
  (keyword_text)
  (keyword_uuid)
  (keyword_json)
  (keyword_jsonb)
  (keyword_xml)
  (keyword_bytea)
  (keyword_enum)
  (keyword_date)
  (keyword_datetime)
  (keyword_time)
  (keyword_timestamp)
  (keyword_interval)
] @type.builtin

[
  (keyword_in)
  (keyword_and)
  (keyword_or)
  (keyword_not)
  (keyword_by)
  (keyword_on)
  (keyword_do)
  (keyword_union)
  (keyword_except)
  (keyword_intersect)
] @keyword.operator

[
  "+"
  "-"
  "*"
  "/"
  "%"
  "^"
  ":="
  "="
  "<"
  "<="
  "!="
  ">="
  ">"
  "<>"
] @operator

[
  "("
  ")"
] @punctuation.bracket

[
  ";"
  ","
  "."
] @punctuation.delimiter
