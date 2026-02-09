# Markdown Showcase

This file demonstrates all supported markdown features in dotViewer's **rendered mode**.

## Typography

Regular text with **bold**, *italic*, ***bold italic***, ~~strikethrough~~, and `inline code`.

Backslash escapes: \*not italic\*, \#not a heading, \[not a link\].

A paragraph with a hard line break
on the next line (two trailing spaces).

## Links & Images

Visit [GitHub](https://github.com) for more info. Here's an image:

![Placeholder](https://via.placeholder.com/400x100)

## Blockquotes

> "Any fool can write code that a computer can understand. Good programmers write code that humans can understand."
>
> — Martin Fowler

> Nested blockquotes work too:
>
> > This is nested inside the outer quote.
> > Multiple lines merge correctly.

## Code Blocks

Inline: use `git status` to check your repo.

```swift
struct ContentView: View {
    @State private var count = 0

    var body: some View {
        VStack {
            Text("Count: \(count)")
                .font(.title)
            Button("Increment") {
                count += 1
            }
        }
    }
}
```

```python
def fibonacci(n: int) -> list[int]:
    """Generate Fibonacci sequence up to n terms."""
    fib = [0, 1]
    for _ in range(2, n):
        fib.append(fib[-1] + fib[-2])
    return fib[:n]
```

```
Plain code block without a language label.
Just preformatted text.
```

## Tables

| Feature | Status | Notes |
|:--------|:------:|------:|
| Tables | Done | With alignment |
| Task lists | Done | Checkboxes |
| Code blocks | Done | Language labels |
| Blockquotes | Done | Recursive parsing |
| Images | Done | Alt text support |

## Lists

### Unordered

- First item
- Second item with **bold**
  - Nested item
  - Another nested
    - Deep nesting
- Back to top level

### Ordered

1. Step one
2. Step two
3. Step three

### Task List

- [x] Implement parser
- [x] Add CSS styling
- [ ] Write tests
- [ ] Ship v3.0

## Horizontal Rules

Above the rule.

---

Below the rule.

## HTML Pass-through

<details>
<summary>Click to expand</summary>

This content is hidden by default. It supports **markdown** inside HTML blocks.

</details>

<kbd>Cmd</kbd> + <kbd>Space</kbd> to open Spotlight.

## Mixed Content

Here's a paragraph that references a table below and includes a [link](https://example.com), some `code`, and **emphasis**.

| Syntax | Description | Example |
|--------|-------------|---------|
| `**bold**` | Bold text | **bold** |
| `*italic*` | Italic text | *italic* |
| `` `code` `` | Inline code | `code` |
| `~~strike~~` | Strikethrough | ~~strike~~ |

> **Note:** This blockquote contains a list:
>
> - Item one
> - Item two
> - Item three

---

*End of showcase.*
