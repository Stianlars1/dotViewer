# github/cmark-gfm

- Source: https://github.com/github/cmark-gfm
- Summary: GitHub-flavored Markdown parser in C, used by several Markdown Quick Look plugins.
- Primary file types: Library (Markdown/GFM)
- Plugin type: Library (not a QL plugin)
- License: BSD-style (COPYING)
- Feature tags: markdown, c, gfm, parser

## Directory Tree
```text
cmark-gfm
|-- .github
|   `-- workflows
|       |-- ci.yml
|       `-- codeql.yml
|-- api_test
|   |-- CMakeLists.txt
|   |-- cplusplus.cpp
|   |-- cplusplus.h
|   |-- harness.c
|   |-- harness.h
|   `-- main.c
|-- bench
|   |-- samples
|   |   |-- block-bq-flat.md
|   |   |-- block-bq-nested.md
|   |   |-- block-code.md
|   |   |-- block-fences.md
|   |   |-- block-heading.md
|   |   |-- block-hr.md
|   |   |-- block-html.md
|   |   |-- block-lheading.md
|   |   |-- block-list-flat.md
|   |   |-- block-list-nested.md
|   |   |-- block-ref-flat.md
|   |   |-- block-ref-nested.md
|   |   |-- inline-autolink.md
|   |   |-- inline-backticks.md
|   |   |-- inline-em-flat.md
|   |   |-- inline-em-nested.md
|   |   |-- inline-em-worst.md
|   |   |-- inline-entity.md
|   |   |-- inline-escape.md
|   |   |-- inline-html.md
|   |   |-- inline-links-flat.md
|   |   |-- inline-links-nested.md
|   |   |-- inline-newlines.md
|   |   |-- lorem1.md
|   |   `-- rawtabs.md
|   |-- statistics.py
|   `-- stats.py
|-- data
|   `-- CaseFolding.txt
|-- extensions
|   |-- autolink.c
|   |-- autolink.h
|   |-- CMakeLists.txt
|   |-- cmark-gfm-core-extensions.h
|   |-- core-extensions.c
|   |-- ext_scanners.c
|   |-- ext_scanners.h
|   |-- ext_scanners.re
|   |-- strikethrough.c
|   |-- strikethrough.h
|   |-- table.c
|   |-- table.h
|   |-- tagfilter.c
|   |-- tagfilter.h
|   |-- tasklist.c
|   `-- tasklist.h
|-- fuzz
|   |-- CMakeLists.txt
|   |-- fuzz_quadratic.c
|   |-- fuzz_quadratic_brackets.c
|   |-- fuzzloop.sh
|   `-- README.md
|-- man
|   |-- man1
|   |   `-- cmark-gfm.1
|   |-- man3
|   |   `-- cmark-gfm.3
|   |-- CMakeLists.txt
|   `-- make_man_page.py
|-- src
|   |-- arena.c
|   |-- blocks.c
|   |-- buffer.c
|   |-- buffer.h
|   |-- case_fold_switch.inc
|   |-- chunk.h
|   |-- CMakeLists.txt
|   |-- cmark-gfm-extension_api.h
|   |-- cmark-gfm.h
|   |-- cmark-gfm_version.h.in
|   |-- cmark.c
|   |-- cmark_ctype.c
|   |-- cmark_ctype.h
|   |-- commonmark.c
|   |-- config.h.in
|   |-- entities.inc
|   |-- footnotes.c
|   |-- footnotes.h
|   |-- houdini.h
|   |-- houdini_href_e.c
|   |-- houdini_html_e.c
|   |-- houdini_html_u.c
|   |-- html.c
|   |-- html.h
|   |-- inlines.c
|   |-- inlines.h
|   |-- iterator.c
|   |-- iterator.h
|   |-- latex.c
|   |-- libcmark-gfm.pc.in
|   |-- linked_list.c
|   |-- main.c
|   |-- man.c
|   |-- map.c
|   |-- map.h
|   |-- node.c
|   |-- node.h
|   |-- parser.h
|   |-- plaintext.c
|   |-- plugin.c
|   |-- plugin.h
|   |-- references.c
|   |-- references.h
|   |-- registry.c
|   |-- registry.h
|   |-- render.c
|   |-- render.h
|   |-- scanners.c
|   |-- scanners.h
|   |-- scanners.re
|   |-- syntax_extension.c
|   |-- syntax_extension.h
|   |-- utf8.c
|   |-- utf8.h
|   `-- xml.c
|-- test
|   |-- afl_test_cases
|   |   `-- test.md
|   |-- CMakeLists.txt
|   |-- cmark-fuzz.c
|   |-- cmark.py
|   |-- entity_tests.py
|   |-- extensions-full-info-string.txt
|   |-- extensions-table-prefer-style-attributes.txt
|   |-- extensions.txt
|   |-- fuzzing_dictionary
|   |-- normalize.py
|   |-- pathological_tests.py
|   |-- regression.txt
|   |-- roundtrip_tests.py
|   |-- run-cmark-fuzz
|   |-- smart_punct.txt
|   |-- spec.txt
|   `-- spec_tests.py
|-- tools
|   |-- appveyor-build.bat
|   |-- Dockerfile
|   |-- make_entities_inc.py
|   |-- mkcasefold.pl
|   |-- xml2md.xsl
|   `-- xml2md_gfm.xsl
|-- wrappers
|   |-- wrapper.js
|   |-- wrapper.py
|   |-- wrapper.rb
|   |-- wrapper.rkt
|   `-- wrapper_ext.py
|-- .editorconfig
|-- .gitignore
|-- .travis.yml
|-- appveyor.yml
|-- benchmarks.md
|-- changelog.txt
|-- CheckFileOffsetBits.c
|-- CheckFileOffsetBits.cmake
|-- CMakeLists.txt
|-- COPYING
|-- FindAsan.cmake
|-- Makefile
|-- Makefile.nmake
|-- nmake.bat
|-- README.md
|-- suppressions
|-- toolchain-mingw32.cmake
`-- why-cmark-and-not-x.md
```

## Relevant Paths (for dotViewer)
- `src/`: core parser and renderers (HTML, plaintext).
- `extensions/`: GFM extensions (tables, task lists, strikethrough).
- `api_test/`: sample usage of the public API.
- `man/`: API docs and CLI usage.

## Non-Relevant Paths (scanned)
- Benchmarks and fuzzing infrastructure.

## Architecture Notes
- C library with extension API; can be embedded or linked statically.

## Performance Tactics
- Designed for speed and correctness; suitable for large Markdown files.

## Build / Setup Notes
- CMake or make; static or shared library build.

## Reuse Notes
- Recommended parser for dotViewer's Markdown previews.
