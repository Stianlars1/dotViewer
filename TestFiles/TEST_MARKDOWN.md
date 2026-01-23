# Task List Test File

This file tests TaskItem UUID stability in dotViewer.

## Sprint Backlog

- [x] Implement syntax highlighting
- [x] Add theme support
- [ ] Fix progressive rendering
- [ ] Add file type detection
- [x] Cache highlighted results

## Notes

Regular paragraph text between task items to test mixed content.

- [ ] Write unit tests
- [ ] Update documentation
- [x] Code review complete

## Code Reference

```swift
struct TaskItem: Identifiable {
    let id: UUID
    let isChecked: Bool
    let text: String
}
```

End of test file.
