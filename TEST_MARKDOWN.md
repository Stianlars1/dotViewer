# dotViewer Markdown Test File

This file tests all markdown rendering features.

## Basic Formatting

**Bold text** and *italic text* and ***bold italic***.

~~Strikethrough text~~

## Lists

### Unordered List
- Item 1
- Item 2
  - Nested item 2.1
  - Nested item 2.2
- Item 3

### Ordered List
1. First item
2. Second item
3. Third item

## Tables

| Feature | Status | Notes |
|---------|--------|-------|
| Tables  | ✓      | Should render with borders |
| Images  | ✓      | Local and remote |
| HTML    | ✓      | Raw HTML support |
| Code    | ✓      | Syntax highlighting |

## Code Blocks

### Swift Code
```swift
func hello() {
    print("Hello, world!")
}

struct User {
    let name: String
    let age: Int
}
```

### JavaScript Code
```javascript
const marked = require('marked');
const html = marked.parse('# Heading');
console.log(html);
```

### Inline Code
Use `let x = 5` for inline code.

## Links

[GitHub](https://github.com)
[Marked.js Documentation](https://marked.js.org/)

## Blockquotes

> This is a blockquote.
> It can span multiple lines.
>
> And multiple paragraphs.

## Horizontal Rule

---

## HTML in Markdown

<p align="center">
  <strong>This is centered HTML text</strong>
</p>

<div style="background: #f0f0f0; padding: 10px; border-radius: 5px;">
  Custom styled div with HTML
</div>

## Task Lists (GFM)

- [x] Implement markdown rendering
- [x] Add table support
- [ ] Add LaTeX math support (future)
- [ ] Add Mermaid diagrams (future)

## Emoji (if supported)

:rocket: :star: :check_mark: :warning:

---

## Expected Results

When viewing this file in dotViewer:
- All headings should be properly sized
- Tables should have borders and proper formatting
- Code blocks should have syntax highlighting
- HTML elements should render correctly
- Lists should be properly indented
- Links should be clickable
- Bold, italic, and strikethrough should work
