# External Integrations

**Analysis Date:** 2026-01-14

## APIs & External Services

**Payment Processing:**
- Not detected - Local-only application

**Email/SMS:**
- Not detected - No communication features

**External APIs:**
- Not detected - 100% local processing, no network calls

## Data Storage

**Databases:**
- Not detected - No database integration

**File Storage:**
- Local file system only - Read-only access to user-selected files
- App sandbox restrictions apply

**Caching:**
- In-memory LRU cache for highlighted content (`Shared/HighlightCache.swift`)
- UserDefaults for settings persistence (`Shared/SharedSettings.swift`)

## Authentication & Identity

**Auth Provider:**
- Not detected - No user accounts or authentication

**OAuth Integrations:**
- Not detected - No external auth providers

## Monitoring & Observability

**Error Tracking:**
- Not detected - No crash reporting service

**Analytics:**
- Not detected - No telemetry or analytics

**Logs:**
- Apple os.log - Local unified logging system (`Shared/Logger.swift`)
- Subsystem: `com.stianlars1.dotViewer`
- Categories: Preview, Settings, App, Cache
- Viewable in Console.app

## CI/CD & Deployment

**Hosting:**
- Direct distribution via GitHub Releases (DMG)
- Mac App Store (planned)

**CI Pipeline:**
- Manual build process via `scripts/release.sh`
- No automated CI/CD detected

## Environment Configuration

**Development:**
- No environment variables required
- All settings via Xcode project configuration

**Staging:**
- Not applicable - Single release channel

**Production:**
- Code signing with Developer ID
- Notarization via Apple notarytool
- Credentials stored in macOS Keychain (`AC_PASSWORD`)

## Webhooks & Callbacks

**Incoming:**
- Not detected - No server-side components

**Outgoing:**
- Not detected - No external notifications

## Apple System Integration

**Quick Look Framework:**
- `QLPreviewingController` implementation (`QuickLookPreview/PreviewViewController.swift`)
- Registers 70+ content types via `QuickLookPreview/Info.plist`
- Extension enabled via System Settings > Privacy & Security > Extensions

**App Groups:**
- Suite: `group.stianlars1.dotViewer.shared`
- Purpose: Settings sync between main app and Quick Look extension
- Files: `Shared/SharedSettings.swift`

**Uniform Type Identifiers (UTIs):**
- Custom UTI definitions in `dotViewer/Info.plist`
- Covers: TypeScript, TSX, JSX, Rust, Go, TOML, MDX, Vue, Svelte, Kotlin, Dockerfile, GraphQL, Prisma, .env, Zsh
- System UTI support for standard file types

**System Appearance:**
- Dark mode detection (`Shared/ThemeManager.swift`)
- Auto theme switching based on system appearance

## Third-Party Libraries (Bundled)

**HighlightSwift:**
- GitHub: `https://github.com/appstefan/HighlightSwift`
- Purpose: Syntax highlighting for 50+ programming languages
- Files: `Shared/SyntaxHighlighter.swift`, `Shared/ThemeManager.swift`

**marked.min.js (vendored):**
- Purpose: Markdown parsing (deprecated - now using native AttributedString)
- File: `QuickLookPreview/marked.min.js`
- Status: Bundled but no longer actively used

## Security & Sandboxing

**App Sandbox:**
- Enabled for Quick Look extension (`QuickLookPreview/QuickLookPreview.entitlements`)
- Read-only file access to user-selected files

**Hardened Runtime:**
- Enabled for both targets
- Required for notarization

**Privacy:**
- 100% local processing
- No data collection or transmission
- No network permissions requested

---

*Integration audit: 2026-01-14*
*Update when adding/removing external services*
