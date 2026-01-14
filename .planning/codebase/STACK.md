# Technology Stack

**Analysis Date:** 2026-01-14

## Languages

**Primary:**
- Swift 5.0 - All application code (`dotViewer.xcodeproj/project.pbxproj`)

**Secondary:**
- JavaScript - Bundled markdown parser (`QuickLookPreview/marked.min.js`)

## Runtime

**Environment:**
- macOS 13.0 (Ventura) or later - Deployment target
- macOS 14.0 minimum for build - `dotViewer.xcodeproj/project.pbxproj`
- Xcode 15+ required for development

**Package Manager:**
- Swift Package Manager (SPM) - Integrated in Xcode project
- No lockfile (uses SPM internal resolution)

## Frameworks

**Core:**
- SwiftUI - UI framework (`dotViewer/dotViewerApp.swift`)
- AppKit/Cocoa - macOS compatibility layer (`Shared/ThemeManager.swift`)
- Quartz - Quick Look integration (`QuickLookPreview/PreviewViewController.swift`)

**System:**
- Foundation - Core runtime (`Shared/SharedSettings.swift`)
- UniformTypeIdentifiers - File type handling (`dotViewer/ContentView.swift`)
- os.log - Unified logging (`Shared/Logger.swift`)

**Testing:**
- No test framework configured (manual QA process)

**Build/Dev:**
- Xcode project (`dotViewer.xcodeproj`)
- Two targets: Main app + Quick Look extension
- Hardened runtime enabled

## Key Dependencies

**Critical:**
- HighlightSwift 1.0+ - Syntax highlighting engine (`Shared/SyntaxHighlighter.swift`, `Shared/ThemeManager.swift`)
  - GitHub: `https://github.com/appstefan/HighlightSwift`
  - Provides 50+ language support with multiple color themes

**Infrastructure:**
- App Groups - Inter-process settings sync (`group.stianlars1.dotViewer.shared`)
- UserDefaults - Settings persistence (`Shared/SharedSettings.swift`)

## Configuration

**Environment:**
- No environment variables required
- All configuration via UserDefaults with App Groups
- Settings synced between main app and Quick Look extension

**Build:**
- `dotViewer.xcodeproj/project.pbxproj` - Xcode project configuration
- `dotViewer/Info.plist` - Main app configuration
- `QuickLookPreview/Info.plist` - Extension configuration with 70+ UTI registrations
- `*.entitlements` - Sandbox and App Group permissions

## Platform Requirements

**Development:**
- macOS with Xcode 15+
- No external dependencies beyond SPM packages

**Production:**
- macOS 13.0 (Ventura) or later
- Quick Look extension enabled in System Settings
- Distributed as signed/notarized DMG or Mac App Store

---

*Stack analysis: 2026-01-14*
*Update after major dependency changes*
