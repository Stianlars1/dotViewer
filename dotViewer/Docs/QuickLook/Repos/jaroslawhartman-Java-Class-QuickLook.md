# jaroslawhartman/Java-Class-QuickLook

- Source: https://github.com/jaroslawhartman/Java-Class-QuickLook
- Summary: Decompiles Java `.class` files via `java -jar` and displays plain text.
- Primary file types: Java .class
- Plugin type: Quick Look Generator (.qlgenerator, legacy)
- License: GPLv3 (LICENSE)
- Feature tags: java, decompile, external-process, plain-text, qlgenerator

## Directory Tree
```text
Java-Class-QuickLook
|-- img
|   `-- JavaClass.gif
|-- Java Class
|   |-- jd-cli-dist
|   |   |-- jd-cli
|   |   |-- jd-cli.bat
|   |   |-- jd-cli.jar
|   |   `-- LICENSE.txt
|   |-- GeneratePreviewForURL.m
|   |-- GenerateThumbnailForURL.m
|   |-- Info.plist
|   `-- main.c
|-- Java Class.xcodeproj
|   |-- project.xcworkspace
|   |   |-- xcshareddata
|   |   |   `-- IDEWorkspaceChecks.plist
|   |   |-- xcuserdata
|   |   |   `-- jhartman.xcuserdatad
|   |   |       `-- UserInterfaceState.xcuserstate
|   |   `-- contents.xcworkspacedata
|   |-- xcuserdata
|   |   `-- jhartman.xcuserdatad
|   |       `-- xcschemes
|   |           `-- xcschememanagement.plist
|   `-- project.pbxproj
|-- LICENSE
`-- README.md
```

## Relevant Paths (for dotViewer)
- `Java Class/GeneratePreviewForURL.m`: runs `jd-cli.jar` via `java`, returns plain text.
- `Java Class/Info.plist`: UTI registration for `.class`.
- `Java Class/main.c`: generator entry.

## Non-Relevant Paths (scanned)
- Project metadata.

## Architecture Notes
- External Java process; outputs plain text to Quick Look.

## Performance Tactics
- Process spawn per preview; may be heavy for large class files.

## Build / Setup Notes
- Requires Java runtime; jar included in bundle resources.

## Reuse Notes
- Pattern for running bundled decompiler and emitting plain text.
