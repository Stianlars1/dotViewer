; Keywords
[
  "if"
  "elseif"
  "else"
  "endif"
] @keyword.conditional

[
  "foreach"
  "endforeach"
  "while"
  "endwhile"
  "break"
  "continue"
] @keyword.repeat

[
  "function"
  "endfunction"
  "macro"
  "endmacro"
] @keyword.function

[
  "return"
] @keyword.return

[
  "block"
  "endblock"
  "cmake_minimum_required"
  "project"
  "set"
  "unset"
  "option"
  "message"
  "add_executable"
  "add_library"
  "add_subdirectory"
  "add_custom_command"
  "add_custom_target"
  "add_dependencies"
  "add_test"
  "target_link_libraries"
  "target_include_directories"
  "target_compile_definitions"
  "target_compile_options"
  "target_sources"
  "install"
  "find_package"
  "find_library"
  "find_path"
  "find_program"
  "find_file"
  "include"
  "include_directories"
  "link_directories"
  "link_libraries"
  "configure_file"
  "execute_process"
  "file"
  "string"
  "list"
  "math"
  "get_filename_component"
  "get_property"
  "set_property"
  "get_target_property"
  "set_target_properties"
  "get_directory_property"
  "set_directory_properties"
  "mark_as_advanced"
  "separate_arguments"
  "cmake_parse_arguments"
  "cmake_policy"
  "export"
  "try_compile"
  "try_run"
  "enable_testing"
  "enable_language"
] @function.builtin

; Function/macro definitions
(function_def
  (function_command
    (argument) @function))

(macro_def
  (macro_command
    (argument) @function))

; Normal command calls
(normal_command
  (identifier) @function.call)

; Variables
(variable_ref) @variable
(variable) @variable

; Bracket/quoted arguments
(quoted_argument) @string
(bracket_argument) @string

; Unquoted argument
(unquoted_argument) @string

; Comments
(line_comment) @comment
(bracket_comment) @comment

; Punctuation
[
  "("
  ")"
] @punctuation.bracket

