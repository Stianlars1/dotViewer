# saalen/highlight

- Source: https://gitlab.com/saalen/highlight
- Summary: C++ syntax highlighting engine used by multiple Quick Look plugins.
- Primary file types: Library (many languages)
- Plugin type: Library (not a QL plugin)
- License: GPLv3 (COPYING)
- Feature tags: highlight, c++, syntax, themes, languages

## Directory Tree
```text
highlight
|-- extras
|   |-- AsciiDoc
|   |   |-- haml
|   |   |   `-- block_listing.html.haml
|   |   |-- sass
|   |   |   |-- _base16-brewer.scss
|   |   |   |-- _hl-adoc-template.scss
|   |   |   |-- _hl-theme_alan.scss
|   |   |   |-- _hl-theme_purebasic.scss
|   |   |   |-- build.sh
|   |   |   |-- highlight_mod.scss
|   |   |   `-- watch.sh
|   |   |-- build.sh
|   |   |-- docinfo.html
|   |   |-- example.asciidoc
|   |   |-- example.html
|   |   |-- example_mod.asciidoc
|   |   |-- example_mod.html
|   |   |-- highlight-treeprocessor.rb
|   |   |-- highlight-treeprocessor_mod.rb
|   |   |-- highlight_mod.css
|   |   |-- highlight_mod.css.map
|   |   |-- README.asciidoc
|   |   `-- README.html
|   |-- eclipse-themes
|   |   `-- eclipse_color_themes.py
|   |-- json
|   |   `-- theme2json.lua
|   |-- langDefs-resources
|   |   |-- cleanslate.lang
|   |   |-- template.lang
|   |   `-- UNLICENCE
|   |-- langs-examples
|   |   |-- _adoc
|   |   |   |-- haml
|   |   |   |   `-- block_listing.html.haml
|   |   |   |-- BUILD.bat
|   |   |   |-- Highlight_Examples-docinfo.html
|   |   |   |-- Highlight_Examples.adoc
|   |   |   `-- README.md
|   |   |-- _sass
|   |   |   |-- .gitignore
|   |   |   |-- _color-schemes.scss
|   |   |   |-- _default-theme.scss
|   |   |   |-- _exapunks.scss
|   |   |   |-- _fonts-ligatures.scss
|   |   |   |-- _fonts.scss
|   |   |   |-- _helpers.scss
|   |   |   |-- _purebasic.scss
|   |   |   |-- BUILD_SASS.bat
|   |   |   |-- README.md
|   |   |   |-- styles.scss
|   |   |   `-- WATCH_SASS.bat
|   |   |-- ex-src
|   |   |   |-- alan.alan
|   |   |   |-- EXAPUNKS.exapunks
|   |   |   `-- PureBasic.pb
|   |   |-- .gitattributes
|   |   |-- .gitignore
|   |   |-- CONTRIBUTING.md
|   |   |-- Highlight_Examples.html
|   |   |-- README.md
|   |   `-- styles.css
|   |-- pandoc
|   |   |-- build-example.bat
|   |   |-- build-example.sh
|   |   |-- example-preprocessed.md
|   |   |-- example.css
|   |   |-- example.html
|   |   |-- example.md
|   |   |-- example.pb
|   |   |-- Highlight.pp
|   |   |-- LICENSE
|   |   `-- README.html
|   |-- pywal
|   |   `-- pywal.theme
|   |-- swig
|   |   |-- highlight.i
|   |   |-- makefile
|   |   |-- README_SWIG
|   |   |-- testmod.php
|   |   |-- testmod.pl
|   |   `-- testmod.py
|   |-- tcl
|   |   |-- makefile
|   |   |-- pkgIndex.tcl
|   |   |-- README_TCL
|   |   `-- tclhighlight.c
|   |-- themes-resources
|   |   |-- base16
|   |   |   |-- base16_highlight.mustache
|   |   |   |-- base16_highlight_light.mustache
|   |   |   |-- example-dark.html
|   |   |   |-- example-light.html
|   |   |   |-- example.bat
|   |   |   |-- example.pb
|   |   |   |-- example.theme
|   |   |   |-- example.yaml
|   |   |   |-- example_light.theme
|   |   |   |-- LICENSE
|   |   |   `-- README.html
|   |   |-- css-themes
|   |   |   |-- example.html
|   |   |   |-- hl-theme-boilerplate.css
|   |   |   |-- hl-theme-boilerplate.scss
|   |   |   |-- README.html
|   |   |   `-- UNLICENCE
|   |   `-- boilerplate.theme
|   |-- highlight-service.py
|   |-- highlight_pipe.php
|   |-- highlight_pipe.pm
|   `-- highlight_pipe.py
|-- gui_files
|   |-- ext
|   |   `-- fileopenfilter.conf
|   `-- l10n
|       |-- highlight_bg_BG.qm
|       |-- highlight_cs_CZ.qm
|       |-- highlight_de_DE.qm
|       |-- highlight_es_ES.qm
|       |-- highlight_fr_FR.qm
|       |-- highlight_it_IT.qm
|       |-- highlight_ja_JP.qm
|       `-- highlight_zh_CN.qm
|-- langDefs
|   |-- abap.lang
|   |-- abc.lang
|   |-- abnf.lang
|   |-- actionscript.lang
|   |-- ada.lang
|   |-- agda.lang
|   |-- alan.lang
|   |-- algol.lang
|   |-- ampl.lang
|   |-- amtrix.lang
|   |-- applescript.lang
|   |-- arc.lang
|   |-- arm.lang
|   |-- as400cl.lang
|   |-- ascend.lang
|   |-- asciidoc.lang
|   |-- asp.lang
|   |-- aspect.lang
|   |-- assembler.lang
|   |-- ats.lang
|   |-- autohotkey.lang
|   |-- autoit.lang
|   |-- avenue.lang
|   |-- awk.lang
|   |-- ballerina.lang
|   |-- bat.lang
|   |-- bbcode.lang
|   |-- bcpl.lang
|   |-- bibtex.lang
|   |-- biferno.lang
|   |-- bison.lang
|   |-- blitzbasic.lang
|   |-- bms.lang
|   |-- bnf.lang
|   |-- boo.lang
|   |-- c.lang
|   |-- carbon.lang
|   |-- ceylon.lang
|   |-- charmm.lang
|   |-- chill.lang
|   |-- chpl.lang
|   |-- clean.lang
|   |-- clearbasic.lang
|   |-- clipper.lang
|   |-- clojure.lang
|   |-- clp.lang
|   |-- cmake.lang
|   |-- cobol.lang
|   |-- coffeescript.lang
|   |-- coldfusion.lang
|   |-- conf.lang
|   |-- cpp2.lang
|   |-- critic.lang
|   |-- crk.lang
|   |-- crystal.lang
|   |-- cs_block_regex.lang
|   |-- csharp.lang
|   |-- css.lang
|   |-- cue.lang
|   |-- d.lang
|   |-- dart.lang
|   |-- delphi.lang
|   |-- diff.lang
|   |-- dockerfile.lang
|   |-- dts.lang
|   |-- dylan.lang
|   |-- ebnf.lang
|   |-- ebnf2.lang
|   |-- eiffel.lang
|   |-- elixir.lang
|   |-- elm.lang
|   |-- email.lang
|   |-- erb.lang
|   |-- erlang.lang
|   |-- euphoria.lang
|   |-- exapunks.lang
|   |-- excel.lang
|   |-- express.lang
|   |-- factor.lang
|   |-- fame.lang
|   |-- fasm.lang
|   |-- fea.lang
|   |-- felix.lang
|   |-- fish.lang
|   |-- fortran77.lang
|   |-- fortran90.lang
|   |-- frink.lang
|   |-- fsharp.lang
|   |-- fstab.lang
|   |-- fx.lang
|   |-- gambas.lang
|   |-- gdb.lang
|   |-- gdscript.lang
|   |-- gleam.lang
|   |-- go.lang
|   |-- graphviz.lang
|   |-- haml.lang
|   |-- hare.lang
|   |-- haskell.lang
|   |-- haxe.lang
|   |-- hcl.lang
|   |-- html.lang
|   |-- httpd.lang
|   |-- hugo.lang
|   |-- icon.lang
|   |-- idl.lang
|   |-- idlang.lang
|   |-- inc_luatex.lang
|   |-- informix.lang
|   |-- ini.lang
|   |-- innosetup.lang
|   |-- interlis.lang
|   |-- io.lang
|   |-- jam.lang
|   |-- jasmin.lang
|   |-- java.lang
|   |-- javascript.lang
|   |-- js_regex.lang
|   |-- json.lang
|   |-- jsp.lang
|   |-- jsx.lang
|   |-- julia.lang
|   |-- kotlin.lang
|   |-- ldif.lang
|   |-- less.lang
|   |-- lhs.lang
|   |-- lilypond.lang
|   |-- limbo.lang
|   |-- lindenscript.lang
|   |-- lisp.lang
|   |-- logtalk.lang
|   |-- lotos.lang
|   |-- lotus.lang
|   |-- lua.lang
|   |-- luban.lang
|   |-- makefile.lang
|   |-- maple.lang
|   |-- markdown.lang
|   |-- matlab.lang
|   |-- maya.lang
|   |-- mercury.lang
|   |-- meson.lang
|   |-- miniscript.lang
|   |-- miranda.lang
|   |-- mod2.lang
|   |-- mod3.lang
|   |-- modelica.lang
|   |-- mojo.lang
|   |-- moon.lang
|   |-- ms.lang
|   |-- msl.lang
|   |-- mssql.lang
|   |-- mxml.lang
|   |-- n3.lang
|   |-- nasal.lang
|   |-- nbc.lang
|   |-- nemerle.lang
|   |-- netrexx.lang
|   |-- nginx.lang
|   |-- nice.lang
|   |-- nim.lang
|   |-- nix.lang
|   |-- nsis.lang
|   |-- nxc.lang
|   |-- oberon.lang
|   |-- objc.lang
|   |-- ocaml.lang
|   |-- octave.lang
|   |-- oorexx.lang
|   |-- org.lang
|   |-- os.lang
|   |-- oz.lang
|   |-- paradox.lang
|   |-- pas.lang
|   |-- pdf.lang
|   |-- perl.lang
|   |-- php.lang
|   |-- pike.lang
|   |-- pl1.lang
|   |-- plperl.lang
|   |-- plpython.lang
|   |-- pltcl.lang
|   |-- po.lang
|   |-- polygen.lang
|   |-- pony.lang
|   |-- pov.lang
|   |-- powershell.lang
|   |-- pro.lang
|   |-- progress.lang
|   |-- ps.lang
|   |-- psl.lang
|   |-- pure.lang
|   |-- purebasic.lang
|   |-- purescript.lang
|   |-- pyrex.lang
|   |-- python.lang
|   |-- q.lang
|   |-- qmake.lang
|   |-- qml.lang
|   |-- qu.lang
|   |-- r.lang
|   |-- rebol.lang
|   |-- rego.lang
|   |-- rexx.lang
|   |-- rnc.lang
|   |-- rpg.lang
|   |-- rpl.lang
|   |-- rst.lang
|   |-- ruby.lang
|   |-- rust.lang
|   |-- s.lang
|   |-- sam.lang
|   |-- sas.lang
|   |-- scad.lang
|   |-- scala.lang
|   |-- scilab.lang
|   |-- scss.lang
|   |-- shellscript.lang
|   |-- slim.lang
|   |-- small.lang
|   |-- smalltalk.lang
|   |-- sml.lang
|   |-- snmp.lang
|   |-- snobol.lang
|   |-- solidity.lang
|   |-- spec.lang
|   |-- spn.lang
|   |-- sql.lang
|   |-- squirrel.lang
|   |-- styl.lang
|   |-- svg.lang
|   |-- swift.lang
|   |-- sybase.lang
|   |-- tcl.lang
|   |-- tcsh.lang
|   |-- terraform.lang
|   |-- tex.lang
|   |-- toml.lang
|   |-- tsql.lang
|   |-- tsx.lang
|   |-- ttcn3.lang
|   |-- txt.lang
|   |-- typescript.lang
|   |-- upc.lang
|   |-- v.lang
|   |-- vala.lang
|   |-- vb.lang
|   |-- verilog.lang
|   |-- vhd.lang
|   |-- vimscript.lang
|   |-- vue.lang
|   |-- wat.lang
|   |-- whiley.lang
|   |-- wren.lang
|   |-- xml.lang
|   |-- xpp.lang
|   |-- yaiff.lang
|   |-- yaml.lang
|   |-- yaml_ansible.lang
|   |-- yang.lang
|   |-- zig.lang
|   `-- znn.lang
|-- man
|   |-- filetypes.conf.5
|   `-- highlight.1
|-- plugins
|   |-- asciidoc_html_add_links.lua
|   |-- bash_functions.lua
|   |-- bash_ref_man7_org.lua
|   |-- comment_links.lua
|   |-- cpp_qt.lua
|   |-- cpp_ref_cplusplus_com.lua
|   |-- cpp_ref_gtk_gnome_org.lua
|   |-- cpp_ref_local_includes.lua
|   |-- cpp_ref_qtproject_org.lua
|   |-- cpp_ref_wxwidgets_org.lua
|   |-- cpp_syslog.lua
|   |-- cpp_wx.lua
|   |-- ctags_html_tooltips.lua
|   |-- java_library.lua
|   |-- keywords_capitalize.lua
|   |-- keywords_lowercase.lua
|   |-- keywords_uppercase.lua
|   |-- latex_single_outfile.lua
|   |-- mark_lines.lua
|   |-- outhtml_add_background_stripes.lua
|   |-- outhtml_add_background_svg.lua
|   |-- outhtml_add_figure.lua
|   |-- outhtml_add_line.lua
|   |-- outhtml_add_shadow.lua
|   |-- outhtml_ansi_esc.lua
|   |-- outhtml_codefold.lua
|   |-- outhtml_copy_clipboard.lua
|   |-- outhtml_curly_brackets_matcher.lua
|   |-- outhtml_focus.lua
|   |-- outhtml_ie7_webctrl.lua
|   |-- outhtml_keyword_matcher.lua
|   |-- outhtml_ligature_fonts.lua
|   |-- outhtml_modern_fonts.lua
|   |-- outhtml_parantheses_matcher.lua
|   |-- outhtml_tooltips.lua
|   |-- perl_ref_perl_org.lua
|   |-- python_ref_python_org.lua
|   |-- reduce_filesize.lua
|   |-- sam_seq.lua
|   |-- scala_ref_scala_lang_org.lua
|   |-- terminal_add_info.lua
|   |-- theme_invert.lua
|   `-- token_add_state_ids.lua
|-- sh-completion
|   |-- gen-completions
|   |-- highlight.bash
|   |-- highlight.fish
|   `-- highlight.zsh
|-- src
|   |-- cli
|   |   |-- arg_parser.cc
|   |   |-- arg_parser.h
|   |   |-- cmdlineoptions.cpp
|   |   |-- cmdlineoptions.h
|   |   |-- help.cpp
|   |   |-- help.h
|   |   |-- main.cpp
|   |   `-- main.h
|   |-- core
|   |   |-- astyle
|   |   |   |-- ASBeautifier.cpp
|   |   |   |-- ASEnhancer.cpp
|   |   |   |-- ASFormatter.cpp
|   |   |   |-- ASResource.cpp
|   |   |   `-- ASStreamIterator.cpp
|   |   |-- Diluculum
|   |   |   |-- InternalUtils.cpp
|   |   |   |-- InternalUtils.hpp
|   |   |   |-- LuaExceptions.cpp
|   |   |   |-- LuaFunction.cpp
|   |   |   |-- LuaState.cpp
|   |   |   |-- LuaUserData.cpp
|   |   |   |-- LuaUtils.cpp
|   |   |   |-- LuaValue.cpp
|   |   |   |-- LuaVariable.cpp
|   |   |   `-- LuaWrappers.cpp
|   |   |-- ansigenerator.cpp
|   |   |-- bbcodegenerator.cpp
|   |   |-- codegenerator.cpp
|   |   |-- datadir.cpp
|   |   |-- elementstyle.cpp
|   |   |-- htmlgenerator.cpp
|   |   |-- keystore.cpp
|   |   |-- latexgenerator.cpp
|   |   |-- lspclient.cpp
|   |   |-- odtgenerator.cpp
|   |   |-- pangogenerator.cpp
|   |   |-- platform_fs.cpp
|   |   |-- preformatter.cpp
|   |   |-- rtfgenerator.cpp
|   |   |-- stringtools.cpp
|   |   |-- stylecolour.cpp
|   |   |-- svggenerator.cpp
|   |   |-- syntaxreader.cpp
|   |   |-- texgenerator.cpp
|   |   |-- themereader.cpp
|   |   |-- xhtmlgenerator.cpp
|   |   `-- xterm256generator.cpp
|   |-- gui-qt
|   |   |-- clipboard.png
|   |   |-- file.png
|   |   |-- folder.png
|   |   |-- highlight-gui.qrc
|   |   |-- highlight-gui.rc
|   |   |-- highlight.icns
|   |   |-- highlight.png
|   |   |-- highlight.pro
|   |   |-- highlight.xpm
|   |   |-- highlight_bg_BG.ts
|   |   |-- highlight_cs_CZ.ts
|   |   |-- highlight_de_DE.ts
|   |   |-- highlight_es_ES.ts
|   |   |-- highlight_fr_FR.ts
|   |   |-- highlight_it_IT.ts
|   |   |-- highlight_ja_JP.ts
|   |   |-- highlight_zh_CN.ts
|   |   |-- hl_icon_exe.ico
|   |   |-- io_report.cpp
|   |   |-- io_report.h
|   |   |-- io_report.ui
|   |   |-- ls_not_supported.png
|   |   |-- ls_supported.png
|   |   |-- main.cpp
|   |   |-- mainwindow.cpp
|   |   |-- mainwindow.h
|   |   |-- mainwindow.ui
|   |   |-- plugin.png
|   |   |-- precomp.h
|   |   |-- script.png
|   |   |-- script_blue.png
|   |   |-- showtextfile.cpp
|   |   |-- showtextfile.h
|   |   |-- showtextfile.ui
|   |   |-- syntax_chooser.cpp
|   |   |-- syntax_chooser.h
|   |   `-- syntax_chooser.ui
|   |-- include
|   |   |-- astyle
|   |   |   |-- ASStreamIterator.h
|   |   |   `-- astyle.h
|   |   |-- Diluculum
|   |   |   |-- CppObject.hpp
|   |   |   |-- LuaExceptions.hpp
|   |   |   |-- LuaFunction.hpp
|   |   |   |-- LuaState.hpp
|   |   |   |-- LuaUserData.hpp
|   |   |   |-- LuaUtils.hpp
|   |   |   |-- LuaValue.hpp
|   |   |   |-- LuaVariable.hpp
|   |   |   |-- LuaWrappers.hpp
|   |   |   `-- Types.hpp
|   |   |-- picojson
|   |   |   `-- picojson.h
|   |   |-- ansigenerator.h
|   |   |-- bbcodegenerator.h
|   |   |-- charcodes.h
|   |   |-- codegenerator.h
|   |   |-- datadir.h
|   |   |-- elementstyle.h
|   |   |-- enums.h
|   |   |-- htmlgenerator.h
|   |   |-- keystore.h
|   |   |-- latexgenerator.h
|   |   |-- lspclient.h
|   |   |-- lspprofile.h
|   |   |-- odtgenerator.h
|   |   |-- pangogenerator.h
|   |   |-- platform_fs.h
|   |   |-- preformatter.h
|   |   |-- regexelement.h
|   |   |-- regextoken.h
|   |   |-- rtfgenerator.h
|   |   |-- semantictoken.h
|   |   |-- stringtools.h
|   |   |-- stylecolour.h
|   |   |-- svggenerator.h
|   |   |-- syntaxreader.h
|   |   |-- texgenerator.h
|   |   |-- themereader.h
|   |   |-- version.h
|   |   |-- xhtmlgenerator.h
|   |   `-- xterm256generator.h
|   |-- w32-projects
|   |   |-- highlight_cli
|   |   |   `-- highlight_cli.pro
|   |   |-- highlight_lib
|   |   |   `-- highlight_lib.pro
|   |   |-- highlight-setup-x86.iss
|   |   |-- highlight-setup.iss
|   |   `-- hl_icon_exe.ico
|   |-- ci_test.sh
|   |-- compile_flags.txt
|   `-- makefile
|-- themes
|   |-- base16
|   |   |-- 3024.theme
|   |   |-- apathy.theme
|   |   |-- ashes.theme
|   |   |-- atelier-cave-light.theme
|   |   |-- atelier-cave.theme
|   |   |-- atelier-dune-light.theme
|   |   |-- atelier-dune.theme
|   |   |-- atelier-estuary-light.theme
|   |   |-- atelier-estuary.theme
|   |   |-- atelier-forest-light.theme
|   |   |-- atelier-forest.theme
|   |   |-- atelier-heath-light.theme
|   |   |-- atelier-heath.theme
|   |   |-- atelier-lakeside-light.theme
|   |   |-- atelier-lakeside.theme
|   |   |-- atelier-plateau-light.theme
|   |   |-- atelier-plateau.theme
|   |   |-- atelier-savanna-light.theme
|   |   |-- atelier-savanna.theme
|   |   |-- atelier-seaside-light.theme
|   |   |-- atelier-seaside.theme
|   |   |-- atelier-sulphurpool-light.theme
|   |   |-- atelier-sulphurpool.theme
|   |   |-- bespin.theme
|   |   |-- brewer.theme
|   |   |-- bright.theme
|   |   |-- brushtrees-dark.theme
|   |   |-- brushtrees.theme
|   |   |-- chalk.theme
|   |   |-- circus.theme
|   |   |-- classic-dark.theme
|   |   |-- classic-light.theme
|   |   |-- codeschool.theme
|   |   |-- cupcake.theme
|   |   |-- cupertino.theme
|   |   |-- darktooth.theme
|   |   |-- default-dark.theme
|   |   |-- default-light.theme
|   |   |-- dracula.theme
|   |   |-- eighties.theme
|   |   |-- embers.theme
|   |   |-- flat.theme
|   |   |-- github.theme
|   |   |-- google-dark.theme
|   |   |-- google-light.theme
|   |   |-- grayscale-dark.theme
|   |   |-- grayscale-light.theme
|   |   |-- greenscreen.theme
|   |   |-- gruvbox-dark-hard.theme
|   |   |-- gruvbox-dark-medium.theme
|   |   |-- gruvbox-dark-pale.theme
|   |   |-- gruvbox-dark-soft.theme
|   |   |-- gruvbox-light-hard.theme
|   |   |-- gruvbox-light-medium.theme
|   |   |-- gruvbox-light-soft.theme
|   |   |-- harmonic-dark.theme
|   |   |-- harmonic-light.theme
|   |   |-- hopscotch.theme
|   |   |-- ia-dark.theme
|   |   |-- ia-light.theme
|   |   |-- icy.theme
|   |   |-- irblack.theme
|   |   |-- isotope.theme
|   |   |-- macintosh.theme
|   |   |-- marrakesh.theme
|   |   |-- materia.theme
|   |   |-- material-darker.theme
|   |   |-- material-lighter.theme
|   |   |-- material-palenight.theme
|   |   |-- material-vivid.theme
|   |   |-- material.theme
|   |   |-- mellow-purple.theme
|   |   |-- mexico-light.theme
|   |   |-- mocha.theme
|   |   |-- monokai.theme
|   |   |-- nord.theme
|   |   |-- ocean.theme
|   |   |-- oceanicnext.theme
|   |   |-- one-light.theme
|   |   |-- onedark.theme
|   |   |-- outrun-dark.theme
|   |   |-- paraiso.theme
|   |   |-- phd.theme
|   |   |-- pico.theme
|   |   |-- pop.theme
|   |   |-- porple.theme
|   |   |-- railscasts.theme
|   |   |-- rebecca.theme
|   |   |-- seti.theme
|   |   |-- snazzy.theme
|   |   |-- solarflare.theme
|   |   |-- solarized-dark.theme
|   |   |-- solarized-light.theme
|   |   |-- spacemacs.theme
|   |   |-- summerfruit-dark.theme
|   |   |-- summerfruit-light.theme
|   |   |-- tomorrow-night.theme
|   |   |-- tomorrow.theme
|   |   |-- tube.theme
|   |   |-- twilight.theme
|   |   |-- unikitty-dark.theme
|   |   |-- unikitty-light.theme
|   |   |-- unikitty-reversible.theme
|   |   |-- woodland.theme
|   |   `-- xcode-dusk.theme
|   |-- acid.theme
|   |-- aiseered.theme
|   |-- andes.theme
|   |-- anotherdark.theme
|   |-- autumn.theme
|   |-- baycomb.theme
|   |-- bclear.theme
|   |-- biogoo.theme
|   |-- bipolar.theme
|   |-- blacknblue.theme
|   |-- bluegreen.theme
|   |-- breeze.theme
|   |-- bright.theme
|   |-- camo.theme
|   |-- candy.theme
|   |-- clarity.theme
|   |-- dante.theme
|   |-- darkblue.theme
|   |-- darkbone.theme
|   |-- darkness.theme
|   |-- darkplus.theme
|   |-- darkslategray.theme
|   |-- darkspectrum.theme
|   |-- denim.theme
|   |-- diff.theme
|   |-- duotone-dark-earth.theme
|   |-- duotone-dark-forest.theme
|   |-- duotone-dark-sea.theme
|   |-- duotone-dark-sky.theme
|   |-- duotone-dark-space.theme
|   |-- dusk.theme
|   |-- earendel.theme
|   |-- easter.theme
|   |-- edit-anjuta.theme
|   |-- edit-bbedit.theme
|   |-- edit-eclipse.theme
|   |-- edit-emacs.theme
|   |-- edit-fasm.theme
|   |-- edit-flashdevelop.theme
|   |-- edit-gedit.theme
|   |-- edit-godot.theme
|   |-- edit-jedit.theme
|   |-- edit-kwrite.theme
|   |-- edit-matlab.theme
|   |-- edit-msvs2008.theme
|   |-- edit-nedit.theme
|   |-- edit-purebasic.theme
|   |-- edit-vim-dark.theme
|   |-- edit-vim.theme
|   |-- edit-xcode.theme
|   |-- ekvoli.theme
|   |-- fineblue.theme
|   |-- freya.theme
|   |-- fruit.theme
|   |-- github.theme
|   |-- golden.theme
|   |-- greenlcd.theme
|   |-- kellys.theme
|   |-- leo.theme
|   |-- lucretia.theme
|   |-- manxome.theme
|   |-- maroloccio.theme
|   |-- matrix.theme
|   |-- moe.theme
|   |-- molokai.theme
|   |-- moria.theme
|   |-- navajo-night.theme
|   |-- navy.theme
|   |-- neon.theme
|   |-- night.theme
|   |-- nightshimmer.theme
|   |-- nord.theme
|   |-- nuvola.theme
|   |-- olive.theme
|   |-- orion.theme
|   |-- oxygenated.theme
|   |-- pablo.theme
|   |-- peaksea.theme
|   |-- print.theme
|   |-- rand01.theme
|   |-- rdark.theme
|   |-- relaxedgreen.theme
|   |-- rootwater.theme
|   |-- seashell.theme
|   |-- solarized-dark.theme
|   |-- solarized-light.theme
|   |-- sourceforge.theme
|   |-- tabula.theme
|   |-- tcsoft.theme
|   |-- the.theme
|   |-- vampire.theme
|   |-- whitengrey.theme
|   |-- xoria256.theme
|   |-- zellner.theme
|   |-- zenburn.theme
|   `-- zmrok.theme
|-- .editorconfig
|-- .gitattributes
|-- .gitignore
|-- .gitlab-ci.yml
|-- AUTHORS
|-- ChangeLog.adoc
|-- CMakeLists.txt
|-- COPYING
|-- filetypes.conf
|-- highlight-langs2adoc.sh
|-- highlight.desktop
|-- highlight3.kdev4
|-- INSTALL
|-- lsp.conf
|-- makefile
|-- meson.build
|-- README.adoc
|-- README_DE.adoc
|-- README_FR.adoc
|-- README_LANGLIST.adoc
|-- README_LSP_CLIENT.adoc
|-- README_PLUGINS.adoc
|-- README_REGEX.adoc
|-- README_RELEASE.adoc
|-- README_TESTCASES.adoc
|-- README_V4_MIGRATION.adoc
`-- validate.sh
```

## Relevant Paths (for dotViewer)
- `src/`: core Highlight engine and CLI implementation.
- `langDefs/`: language definition files (grammar/token rules).
- `themes/`: CSS/theme definitions.
- `plugins/`: output and formatter plugins (e.g., HTML/RTF).
- `extras/`: tooling, conversions, and example integrations.

## Non-Relevant Paths (scanned)
- GUI localization assets and sample data.

## Architecture Notes
- Native C++ parser with Lua support; outputs HTML/RTF/ANSI via plugins.

## Performance Tactics
- Compiled native engine, fast for large files.

## Build / Setup Notes
- Standard make/CMake build; can be embedded or invoked as CLI.

## Reuse Notes
- Primary engine to replace JS highlighting in dotViewer.
