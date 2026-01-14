# Codebase Structure

**Analysis Date:** 2026-01-14

## Directory Layout

```
dotViewer/
├── dotViewer/                    # Main app target
│   ├── dotViewerApp.swift        # App entry point
│   ├── ContentView.swift         # Navigation hub (Status/FileTypes/Settings)
│   ├── FileTypesView.swift       # File type toggle UI
│   ├── AddCustomExtensionSheet.swift # Custom extension modal
│   ├── ExtensionStatusChecker.swift  # pluginkit integration
│   ├── Info.plist                # App configuration
│   ├── dotViewer.entitlements    # App sandbox permissions
│   └── Assets.xcassets/          # App icons and colors
│
├── QuickLookPreview/             # Quick Look extension target
│   ├── PreviewViewController.swift   # QLPreviewingController impl
│   ├── PreviewContentView.swift      # Preview rendering (1,371 lines)
│   ├── MarkdownWebView.swift         # Markdown component
│   ├── MarkdownStyles.swift          # Markdown styling
│   ├── marked.min.js                 # Markdown parser (vendored)
│   ├── Info.plist                    # Extension config (70+ UTIs)
│   └── QuickLookPreview.entitlements # Extension permissions
│
├── Shared/                       # Shared framework
│   ├── FileTypeRegistry.swift    # File type registry (O(1) lookups)
│   ├── FileTypeModel.swift       # Data models
│   ├── SharedSettings.swift      # Thread-safe settings
│   ├── ThemeManager.swift        # Theme state management
│   ├── LanguageDetector.swift    # Language detection
│   ├── SyntaxHighlighter.swift   # Highlighting wrapper
│   ├── HighlightCache.swift      # LRU cache
│   └── Logger.swift              # Unified logging
│
├── scripts/                      # Build automation
│   └── release.sh                # Release build script
│
├── installer-assets/             # DMG creation assets
│   └── dmg-background.png        # DMG window background
│
├── dotViewer.xcodeproj/          # Xcode project
├── ExportOptions-DevID.plist     # Developer ID export config
├── ExportOptions-AppStore.plist  # App Store export config
│
├── README.md                     # User documentation
├── PRIVACY.md                    # Privacy policy
├── HOW_TO_RELEASE.md             # Release guide
├── QA_FINDINGS.md                # QA test results
├── PRODUCTION_READY.md           # Production readiness report
└── .claude/                      # Claude Code configuration
```

## Directory Purposes

**dotViewer/**
- Purpose: Main application UI and entry point
- Contains: SwiftUI views, app configuration
- Key files: `dotViewerApp.swift` (entry), `ContentView.swift` (navigation)
- Subdirectories: `Assets.xcassets/` for icons and colors

**QuickLookPreview/**
- Purpose: Quick Look extension for file previews
- Contains: Preview controller, SwiftUI preview views
- Key files: `PreviewViewController.swift` (entry), `PreviewContentView.swift` (render)
- Subdirectories: None (flat structure)

**Shared/**
- Purpose: Cross-target code shared between app and extension
- Contains: Business logic, models, utilities
- Key files: `FileTypeRegistry.swift`, `SharedSettings.swift`, `LanguageDetector.swift`
- Subdirectories: None (flat structure)

**scripts/**
- Purpose: Build and release automation
- Contains: Shell scripts for CI/CD
- Key files: `release.sh` (build, sign, notarize)

**installer-assets/**
- Purpose: DMG creation resources
- Contains: Background image for installer window

## Key File Locations

**Entry Points:**
- `dotViewer/dotViewerApp.swift` - Main app entry point
- `QuickLookPreview/PreviewViewController.swift` - Extension entry point

**Configuration:**
- `dotViewer/Info.plist` - App bundle configuration
- `QuickLookPreview/Info.plist` - Extension configuration with UTI declarations
- `dotViewer.xcodeproj/project.pbxproj` - Build settings
- `*.entitlements` - Sandbox and App Group permissions

**Core Logic:**
- `Shared/FileTypeRegistry.swift` - File type management
- `Shared/LanguageDetector.swift` - Language detection
- `Shared/SyntaxHighlighter.swift` - Syntax highlighting
- `Shared/SharedSettings.swift` - Settings persistence

**Testing:**
- No dedicated test directory (manual QA process)
- `QA_FINDINGS.md` - Test results documentation

**Documentation:**
- `README.md` - User-facing documentation
- `HOW_TO_RELEASE.md` - Release process guide
- `PRODUCTION_READY.md` - Technical audit report

## Naming Conventions

**Files:**
- PascalCase for Swift files matching type name: `FileTypeRegistry.swift`
- Descriptive suffixes: `*View.swift`, `*Manager.swift`, `*Detector.swift`
- UPPERCASE.md for important documentation: `README.md`, `PRIVACY.md`

**Directories:**
- PascalCase for Xcode targets: `dotViewer/`, `QuickLookPreview/`
- PascalCase for framework: `Shared/`
- lowercase for utilities: `scripts/`, `installer-assets/`

**Special Patterns:**
- `Info.plist` - Standard Apple configuration
- `*.entitlements` - Sandbox permissions
- `*.xcassets` - Asset catalogs

## Where to Add New Code

**New Feature (App UI):**
- Primary code: `dotViewer/NewFeatureView.swift`
- Tests: Manual QA (no automated tests)
- Config if needed: Update `dotViewer/Info.plist`

**New Feature (Preview):**
- Primary code: `QuickLookPreview/NewPreviewFeature.swift`
- Update: `QuickLookPreview/PreviewContentView.swift`
- UTI registration: `QuickLookPreview/Info.plist`

**New Shared Logic:**
- Implementation: `Shared/NewService.swift`
- Update imports in both targets

**New File Type Support:**
- Registry: `Shared/FileTypeRegistry.swift` (add to allTypes array)
- Detection: `Shared/LanguageDetector.swift` (add extension mapping)
- UTI: `QuickLookPreview/Info.plist` (register content type)

**Utilities:**
- Shared helpers: `Shared/NewUtility.swift`
- Build scripts: `scripts/new-script.sh`

## Special Directories

**dotViewer.xcodeproj/**
- Purpose: Xcode project configuration
- Source: Managed by Xcode
- Committed: Yes (source of truth for build settings)

**Assets.xcassets/**
- Purpose: App icons, accent colors
- Source: Xcode asset catalog format
- Committed: Yes

**.claude/**
- Purpose: Claude Code configuration
- Contains: `settings.local.json`
- Committed: Project-specific settings

---

*Structure analysis: 2026-01-14*
*Update when directory structure changes*
