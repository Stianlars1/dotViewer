# BrianGilbert/QLColorCode-extra

- Source: https://github.com/BrianGilbert/QLColorCode-extra
- Summary: Prebuilt QLColorCode bundle with extra UTIs for additional source file extensions.
- Primary file types: Additional source code extensions (conf, haml, scss, etc.)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: GPLv2 (LICENSE.txt)
- Feature tags: utis, highlight, qlgenerator, distribution-bundle

## Directory Tree
```text
QLColorCode-extra
|-- QLColorCode.qlgenerator
|   `-- Contents
|       |-- MacOS
|       |   `-- QLColorCode
|       |-- Resources
|       |   |-- English.lproj
|       |   |   `-- InfoPlist.strings
|       |   |-- etc
|       |   |   `-- highlight
|       |   |       `-- filetypes.conf
|       |   |-- highlight
|       |   |   |-- bin
|       |   |   |   `-- highlight
|       |   |   `-- share
|       |   |       |-- doc
|       |   |       |   `-- highlight
|       |   |       |       |-- examples
|       |   |       |       |   |-- plugins
|       |   |       |       |   |   |-- dokuwiki
|       |   |       |       |   |   |   `-- syntax.php
|       |   |       |       |   |   |-- movabletype
|       |   |       |       |   |   |   |-- highlight.pl
|       |   |       |       |   |   |   `-- README
|       |   |       |       |   |   `-- wordpress
|       |   |       |       |   |       |-- highlight.php
|       |   |       |       |   |       `-- README
|       |   |       |       |   |-- swig
|       |   |       |       |   |   |-- highlight.i
|       |   |       |       |   |   |-- makefile
|       |   |       |       |   |   |-- testmod.pl
|       |   |       |       |   |   `-- testmod.py
|       |   |       |       |   |-- highlight_pipe.php
|       |   |       |       |   |-- highlight_pipe.pm
|       |   |       |       |   `-- highlight_pipe.py
|       |   |       |       |-- AUTHORS
|       |   |       |       |-- ChangeLog
|       |   |       |       |-- COPYING
|       |   |       |       |-- INSTALL
|       |   |       |       |-- README
|       |   |       |       |-- README_DE
|       |   |       |       |-- README_LANGLIST
|       |   |       |       |-- README_REGEX
|       |   |       |       `-- README_SWIG
|       |   |       |-- highlight
|       |   |       |   |-- langDefs
|       |   |       |   |   |-- 4gl.lang
|       |   |       |   |   |-- a4c.lang
|       |   |       |   |   |-- abp.lang
|       |   |       |   |   |-- ada.lang
|       |   |       |   |   |-- agda.lang
|       |   |       |   |   |-- ampl.lang
|       |   |       |   |   |-- amtrix.lang
|       |   |       |   |   |-- applescript.lang
|       |   |       |   |   |-- arc.lang
|       |   |       |   |   |-- arm.lang
|       |   |       |   |   |-- as.lang
|       |   |       |   |   |-- asm.lang
|       |   |       |   |   |-- asp.lang
|       |   |       |   |   |-- aspect.lang
|       |   |       |   |   |-- ats.lang
|       |   |       |   |   |-- au3.lang
|       |   |       |   |   |-- avenue.lang
|       |   |       |   |   |-- awk.lang
|       |   |       |   |   |-- bat.lang
|       |   |       |   |   |-- bb.lang
|       |   |       |   |   |-- bib.lang
|       |   |       |   |   |-- bms.lang
|       |   |       |   |   |-- boo.lang
|       |   |       |   |   |-- c.lang
|       |   |       |   |   |-- cb.lang
|       |   |       |   |   |-- cfc.lang
|       |   |       |   |   |-- chl.lang
|       |   |       |   |   |-- clipper.lang
|       |   |       |   |   |-- clj.lang
|       |   |       |   |   |-- clojure.lang
|       |   |       |   |   |-- clp.lang
|       |   |       |   |   |-- cob.lang
|       |   |       |   |   |-- cs.lang
|       |   |       |   |   |-- css.lang
|       |   |       |   |   |-- d.lang
|       |   |       |   |   |-- diff.lang
|       |   |       |   |   |-- dot.lang
|       |   |       |   |   |-- dylan.lang
|       |   |       |   |   |-- e.lang
|       |   |       |   |   |-- erl.lang
|       |   |       |   |   |-- euphoria.lang
|       |   |       |   |   |-- exp.lang
|       |   |       |   |   |-- f77.lang
|       |   |       |   |   |-- f90.lang
|       |   |       |   |   |-- flx.lang
|       |   |       |   |   |-- frink.lang
|       |   |       |   |   |-- fs.lang
|       |   |       |   |   |-- haskell.lang
|       |   |       |   |   |-- hcl.lang
|       |   |       |   |   |-- html.lang
|       |   |       |   |   |-- httpd.lang
|       |   |       |   |   |-- hx.lang
|       |   |       |   |   |-- icn.lang
|       |   |       |   |   |-- idl.lang
|       |   |       |   |   |-- idlang.lang
|       |   |       |   |   |-- ili.lang
|       |   |       |   |   |-- inc_luatex.lang
|       |   |       |   |   |-- ini.lang
|       |   |       |   |   |-- inp.lang
|       |   |       |   |   |-- io.lang
|       |   |       |   |   |-- iss.lang
|       |   |       |   |   |-- j.lang
|       |   |       |   |   |-- java.lang
|       |   |       |   |   |-- js.lang
|       |   |       |   |   |-- jsp.lang
|       |   |       |   |   |-- lbn.lang
|       |   |       |   |   |-- ldif.lang
|       |   |       |   |   |-- lgt.lang
|       |   |       |   |   |-- lhs.lang
|       |   |       |   |   |-- lisp.lang
|       |   |       |   |   |-- lotos.lang
|       |   |       |   |   |-- ls.lang
|       |   |       |   |   |-- lsl.lang
|       |   |       |   |   |-- lua.lang
|       |   |       |   |   |-- ly.lang
|       |   |       |   |   |-- m.lang
|       |   |       |   |   |-- make.lang
|       |   |       |   |   |-- mel.lang
|       |   |       |   |   |-- mercury.lang
|       |   |       |   |   |-- mib.lang
|       |   |       |   |   |-- miranda.lang
|       |   |       |   |   |-- ml.lang
|       |   |       |   |   |-- mo.lang
|       |   |       |   |   |-- mod3.lang
|       |   |       |   |   |-- mpl.lang
|       |   |       |   |   |-- ms.lang
|       |   |       |   |   |-- mssql.lang
|       |   |       |   |   |-- n.lang
|       |   |       |   |   |-- nas.lang
|       |   |       |   |   |-- nice.lang
|       |   |       |   |   |-- nrx.lang
|       |   |       |   |   |-- nsi.lang
|       |   |       |   |   |-- nut.lang
|       |   |       |   |   |-- oberon.lang
|       |   |       |   |   |-- objc.lang
|       |   |       |   |   |-- octave.lang
|       |   |       |   |   |-- oorexx.lang
|       |   |       |   |   |-- os.lang
|       |   |       |   |   |-- oz.lang
|       |   |       |   |   |-- pas.lang
|       |   |       |   |   |-- php.lang
|       |   |       |   |   |-- pike.lang
|       |   |       |   |   |-- pl.lang
|       |   |       |   |   |-- pl1.lang
|       |   |       |   |   |-- pov.lang
|       |   |       |   |   |-- pro.lang
|       |   |       |   |   |-- progress.lang
|       |   |       |   |   |-- ps.lang
|       |   |       |   |   |-- ps1.lang
|       |   |       |   |   |-- psl.lang
|       |   |       |   |   |-- py.lang
|       |   |       |   |   |-- pyx.lang
|       |   |       |   |   |-- q.lang
|       |   |       |   |   |-- qmake.lang
|       |   |       |   |   |-- qu.lang
|       |   |       |   |   |-- r.lang
|       |   |       |   |   |-- rb.lang
|       |   |       |   |   |-- rebol.lang
|       |   |       |   |   |-- rexx.lang
|       |   |       |   |   |-- rnc.lang
|       |   |       |   |   |-- s.lang
|       |   |       |   |   |-- sas.lang
|       |   |       |   |   |-- sc.lang
|       |   |       |   |   |-- scala.lang
|       |   |       |   |   |-- scilab.lang
|       |   |       |   |   |-- sh.lang
|       |   |       |   |   |-- sma.lang
|       |   |       |   |   |-- smalltalk.lang
|       |   |       |   |   |-- sml.lang
|       |   |       |   |   |-- sno.lang
|       |   |       |   |   |-- spec.lang
|       |   |       |   |   |-- spn.lang
|       |   |       |   |   |-- sql.lang
|       |   |       |   |   |-- sybase.lang
|       |   |       |   |   |-- tcl.lang
|       |   |       |   |   |-- tcsh.lang
|       |   |       |   |   |-- test_re.lang
|       |   |       |   |   |-- tex.lang
|       |   |       |   |   |-- ttcn3.lang
|       |   |       |   |   |-- txt.lang
|       |   |       |   |   |-- vala.lang
|       |   |       |   |   |-- vb.lang
|       |   |       |   |   |-- verilog.lang
|       |   |       |   |   |-- vhd.lang
|       |   |       |   |   |-- xml.lang
|       |   |       |   |   |-- xpp.lang
|       |   |       |   |   |-- y.lang
|       |   |       |   |   `-- znn.lang
|       |   |       |   `-- themes
|       |   |       |       |-- acid.style
|       |   |       |       |-- bipolar.style
|       |   |       |       |-- blacknblue.style
|       |   |       |       |-- bright.style
|       |   |       |       |-- contrast.style
|       |   |       |       |-- darkblue.style
|       |   |       |       |-- darkness.style
|       |   |       |       |-- desert.style
|       |   |       |       |-- easter.style
|       |   |       |       |-- emacs.style
|       |   |       |       |-- golden.style
|       |   |       |       |-- greenlcd.style
|       |   |       |       |-- ide-anjuta.style
|       |   |       |       |-- ide-codewarrior.style
|       |   |       |       |-- ide-eclipse.style
|       |   |       |       |-- ide-kdev.style
|       |   |       |       |-- ide-msvs2008.style
|       |   |       |       |-- ide-xcode.style
|       |   |       |       |-- jedit.style
|       |   |       |       |-- kwrite.style
|       |   |       |       |-- lucretia.style
|       |   |       |       |-- matlab.style
|       |   |       |       |-- moe.style
|       |   |       |       |-- navy.style
|       |   |       |       |-- nedit.style
|       |   |       |       |-- neon.style
|       |   |       |       |-- night.style
|       |   |       |       |-- orion.style
|       |   |       |       |-- pablo.style
|       |   |       |       |-- peachpuff.style
|       |   |       |       |-- print.style
|       |   |       |       |-- rand01.style
|       |   |       |       |-- seashell.style
|       |   |       |       |-- the.style
|       |   |       |       |-- typical.style
|       |   |       |       |-- vampire.style
|       |   |       |       |-- vim-dark.style
|       |   |       |       |-- vim.style
|       |   |       |       |-- whitengrey.style
|       |   |       |       `-- zellner.style
|       |   |       `-- man
|       |   |           `-- man1
|       |   |               `-- highlight.1.gz
|       |   |-- override
|       |   |   |-- config
|       |   |   |   `-- filetypes.conf
|       |   |   |-- langDefs
|       |   |   |   |-- c.lang
|       |   |   |   |-- coffee.lang
|       |   |   |   |-- css.lang
|       |   |   |   |-- ml.lang
|       |   |   |   `-- objc.lang
|       |   |   `-- themes
|       |   |       |-- ide-xcode.style
|       |   |       `-- slateGreen.style
|       |   `-- colorize.sh
|       `-- Info.plist
|-- ChangeLog.txt
|-- LICENSE.txt
|-- README.md
`-- README.txt
```

## Relevant Paths (for dotViewer)
- `QLColorCode.qlgenerator/Contents/Info.plist`: added UTIs/extensions beyond upstream QLColorCode.
- `QLColorCode.qlgenerator/Contents/Resources/etc/highlight/filetypes.conf`: Highlight filetype mappings.
- `QLColorCode.qlgenerator/Contents/Resources/highlight/`: bundled Highlight binaries, language defs, and themes.

## Non-Relevant Paths (scanned)
- Bundled docs, sample files, and release packaging.

## Architecture Notes
- No source changes; distribution of a configured QLColorCode bundle.

## Performance Tactics
- Same performance characteristics as QLColorCode.

## Build / Setup Notes
- No build steps; this repo ships a compiled plugin bundle.

## Reuse Notes
- Reference for expanding UTIs and Highlight filetype mappings safely.
