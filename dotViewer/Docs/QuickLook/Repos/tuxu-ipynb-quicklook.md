# tuxu/ipynb-quicklook

- Source: https://github.com/tuxu/ipynb-quicklook
- Summary: Jupyter Notebook previewer that injects JSON into an HTML template.
- Primary file types: Jupyter notebooks (.ipynb)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: MIT (LICENSE.md)
- Feature tags: ipynb, json, html, qlgenerator

## Directory Tree
```text
ipynb-quicklook
|-- ipynb-quicklook
|   |-- .gitignore
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- HTMLPreviewBuilder.h
|   |-- HTMLPreviewBuilder.m
|   |-- Info.plist
|   |-- main.c
|   `-- template.html.in
|-- ipynb-quicklook.xcodeproj
|   |-- project.xcworkspace
|   |   |-- xcshareddata
|   |   |   `-- IDEWorkspaceChecks.plist
|   |   `-- contents.xcworkspacedata
|   |-- xcuserdata
|   |   `-- tino.xcuserdatad
|   |       `-- xcschemes
|   |           |-- ipynb-quicklook.xcscheme
|   |           `-- xcschememanagement.plist
|   `-- project.pbxproj
|-- nbviewer.js
|   |-- .github
|   |   `-- workflows
|   |       `-- test.yaml
|   |-- cmd
|   |   |-- build.sh
|   |   |-- README.md
|   |   `-- stub.go
|   |-- lib
|   |   |-- nbv.js
|   |   `-- scaffold.html
|   |-- tests
|   |   |-- notebooks
|   |   |   |-- cell-source-null.html
|   |   |   |-- cell-source-null.ipynb
|   |   |   |-- empty-source.html
|   |   |   |-- empty-source.ipynb
|   |   |   |-- headings.html
|   |   |   |-- headings.ipynb
|   |   |   |-- image-no-dimensions.html
|   |   |   |-- image-no-dimensions.ipynb
|   |   |   |-- pyout-html.html
|   |   |   |-- pyout-html.ipynb
|   |   |   |-- pyout-metadata.html
|   |   |   |-- pyout-metadata.ipynb
|   |   |   |-- pyout-svg-output.html
|   |   |   |-- pyout-svg-output.ipynb
|   |   |   |-- raw-cell-type.html
|   |   |   |-- raw-cell-type.ipynb
|   |   |   |-- repro-pr46.html
|   |   |   |-- repro-pr46.ipynb
|   |   |   |-- repro-pr47.html
|   |   |   `-- repro-pr47.ipynb
|   |   |-- package.json
|   |   `-- test.js
|   |-- .gitignore
|   |-- LICENSE
|   |-- preview.gif
|   |-- README.md
|   `-- viewer.html
|-- .gitignore
|-- .gitmodules
|-- LICENSE.md
`-- README.md
```

## Relevant Paths (for dotViewer)
- `ipynb-quicklook/HTMLPreviewBuilder.{h,m}`: loads HTML template and injects JSON.
- `ipynb-quicklook/template.html.in`: HTML template with placeholder.
- `ipynb-quicklook/GeneratePreviewForURL.m`: QL entry point.

## Non-Relevant Paths (scanned)
- Xcode project metadata.

## Architecture Notes
- JSON -> HTML template; no external dependencies.

## Performance Tactics
- Full JSON load into memory; no size caps.

## Build / Setup Notes
- Xcode generator project.

## Reuse Notes
- Template substitution pattern is reusable for other JSON-backed previews.
