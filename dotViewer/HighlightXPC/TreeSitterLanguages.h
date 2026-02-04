#pragma once

#include "tree_sitter/api.h"

#ifdef __cplusplus
extern "C" {
#endif

const TSLanguage *tree_sitter_swift(void);
const TSLanguage *tree_sitter_python(void);
const TSLanguage *tree_sitter_javascript(void);
const TSLanguage *tree_sitter_typescript(void);
const TSLanguage *tree_sitter_tsx(void);
const TSLanguage *tree_sitter_json(void);
const TSLanguage *tree_sitter_yaml(void);
const TSLanguage *tree_sitter_markdown(void);
const TSLanguage *tree_sitter_bash(void);
const TSLanguage *tree_sitter_html(void);
const TSLanguage *tree_sitter_css(void);
const TSLanguage *tree_sitter_xml(void);
const TSLanguage *tree_sitter_ini(void);
const TSLanguage *tree_sitter_toml(void);

#ifdef __cplusplus
}
#endif
