# jendas1/jupyter-notebook-quick-look

- Source: https://github.com/jendas1/jupyter-notebook-quick-look
- Summary: Alternate Jupyter notebook previewer for Quick Look.
- Primary file types: Jupyter notebooks (.ipynb/.jupyter)
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: Public domain (LICENSE)
- Feature tags: ipynb, html, qlgenerator

## Directory Tree
```text
jupyter-notebook-quick-look
|-- jupyter-notebook-quick-look
|   |-- GenerateHTMLForJupyter.h
|   |-- GenerateHTMLForJupyter.m
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- Info.plist
|   |-- main.c
|   |-- MD5Hash.h
|   `-- MD5Hash.m
|-- jupyter-notebook-quick-look.xcodeproj
|   |-- project.xcworkspace
|   |   `-- contents.xcworkspacedata
|   `-- project.pbxproj
|-- .gitignore
|-- LICENSE
`-- README.md
```

## Relevant Paths (for dotViewer)
- `jupyter-notebook-quick-look/GeneratePreviewForURL.m`: main preview path.
- `jupyter-notebook-quick-look/Info.plist`: UTI registration.
- `jupyter-notebook-quick-look/main.c`: generator entry.

## Non-Relevant Paths (scanned)
- Project metadata.

## Architecture Notes
- Basic HTML output for notebooks (implementation is small/minimal).

## Performance Tactics
- No explicit size limits.

## Build / Setup Notes
- Xcode generator project.

## Reuse Notes
- Minimal skeleton for an ipynb previewer.
