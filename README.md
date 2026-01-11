# dotViewer

A macOS Quick Look extension for previewing source code, configuration files, and dotfiles directly in Finder.

## Features

- **Syntax Highlighting** - Beautiful syntax highlighting for 50+ programming languages
- **Theme Support** - 10 themes including Atom One, GitHub, Xcode, Solarized, Tokyo Night, and Blackout
- **Markdown Preview** - Toggle between raw and rendered markdown views
- **Dotfile Support** - Preview `.gitignore`, `.env`, `.zshrc`, `.editorconfig`, and more
- **Line Numbers** - Optional line numbers with configurable font size
- **Open in Editor** - Quick button to open files in VS Code, Xcode, Sublime, or your preferred editor
- **Native Performance** - Built with SwiftUI for fast, native macOS experience

## Supported File Types

### Web Development
TypeScript, TSX, JavaScript, JSX, Vue, Svelte, Astro, HTML, CSS, SCSS/Sass, Less

### Systems Languages
Swift, C, C++, Objective-C, Rust, Go, Java, Kotlin, Scala, C#, Zig

### Scripting
Python, Ruby, PHP, Perl, Lua, R, Julia, Elixir, Erlang, Haskell, Clojure

### Data & Config
JSON, YAML, TOML, XML, INI, SQL, GraphQL, Prisma, Protocol Buffers

### Shell & Terminal
Bash, Zsh, Fish, PowerShell, Dockerfile, Makefile

### Documentation
Markdown, MDX, reStructuredText, LaTeX, Plain Text

### Dotfiles
.gitignore, .gitconfig, .env, .editorconfig, .npmrc, .nvmrc, and more

## Installation

### Direct Download (DMG)
1. Download the latest release from [GitHub Releases](https://github.com/stianlars1/dotViewer/releases)
2. Open the DMG and drag dotViewer to Applications
3. Launch dotViewer once to register the Quick Look extension
4. Enable the extension in System Settings > Privacy & Security > Extensions > Quick Look

### Building from Source
```bash
git clone https://github.com/stianlars1/dotViewer.git
cd dotViewer
open dotViewer.xcodeproj
```

Build and run using Xcode 15+ with macOS 13.0+ deployment target.

## Usage

1. Select any supported file in Finder
2. Press Space to preview with Quick Look
3. Use the header buttons to:
   - Toggle markdown rendering (for .md files)
   - Copy file contents to clipboard
   - Open in your preferred code editor

## Configuration

Launch the dotViewer app to configure:

- **Theme** - Choose from 10 syntax highlighting themes
- **Font Size** - Adjust preview font size (8-72pt)
- **Line Numbers** - Show/hide line numbers
- **Preview Limits** - Set maximum file size for preview
- **Default Editor** - Choose your preferred code editor
- **File Types** - Enable/disable specific file types
- **Custom Extensions** - Add your own file extension mappings

## Requirements

- macOS 13.0 (Ventura) or later
- Quick Look extension must be enabled in System Settings

## Privacy

dotViewer processes all files locally on your Mac. No data is collected, transmitted, or stored externally. See [PRIVACY.md](PRIVACY.md) for details.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please open an issue or pull request on GitHub.

## Author

Created by [Stian Larsen](https://github.com/stianlars1)
