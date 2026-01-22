import SwiftUI

struct AddCustomExtensionSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var extensionName = ""
    @State private var displayName = ""
    @State private var selectedLanguage = "plaintext"
    @State private var showError = false
    @State private var errorMessage = ""

    let onAdd: (CustomExtension) -> Void

    // MARK: - Validation Constants

    /// Reserved system extensions that should not be added as custom types
    private static let reservedExtensions: Set<String> = [
        "app", "framework", "bundle", "plugin", "kext", "xpc",
        "dylib", "a", "o", "so", "dll", "exe", "bin",
        "dmg", "pkg", "mpkg", "iso", "img",
        "zip", "tar", "gz", "bz2", "xz", "rar", "7z",
        "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx",
        "jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic", "heif",
        "mp3", "mp4", "wav", "aac", "flac", "mov", "avi", "mkv", "webm"
    ]

    /// Maximum allowed extension length (reasonable limit)
    private static let maxExtensionLength = 20

    /// Characters that are not allowed in file extensions
    private static let invalidExtensionChars = CharacterSet(charactersIn: "/\\:*?\"<>|. \t\n\r")

    private var isValid: Bool {
        let ext = cleanedExtension
        return !ext.isEmpty &&
               !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
               validateExtension(ext) == nil
    }

    private var cleanedExtension: String {
        extensionName
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
    }

    /// Validates an extension and returns an error message if invalid, nil if valid
    private func validateExtension(_ ext: String) -> String? {
        // Check for empty extension after cleaning
        if ext.isEmpty {
            return "Extension cannot be empty."
        }

        // Check length
        if ext.count > Self.maxExtensionLength {
            return "Extension is too long (max \(Self.maxExtensionLength) characters)."
        }

        // Check for path traversal attempts
        if ext.contains("..") || ext.contains("/") || ext.contains("\\") {
            return "Extension contains invalid characters."
        }

        // Check for invalid characters
        if ext.unicodeScalars.contains(where: { Self.invalidExtensionChars.contains($0) }) {
            return "Extension contains invalid characters (spaces, special characters, etc.)."
        }

        // Check for reserved system extensions
        if Self.reservedExtensions.contains(ext) {
            return "'\(ext)' is a reserved system extension and cannot be added."
        }

        // Must be alphanumeric (with optional hyphens/underscores)
        let allowedChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        if !ext.unicodeScalars.allSatisfy({ allowedChars.contains($0) }) {
            return "Extension must contain only letters, numbers, hyphens, or underscores."
        }

        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Custom Extension")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Form
            Form {
                Section {
                    HStack {
                        Text(".")
                            .foregroundStyle(.secondary)
                        TextField("Extension (e.g. tsx)", text: $extensionName)
                            .textFieldStyle(.plain)
                    }
                } header: {
                    Text("File Extension")
                } footer: {
                    Text("Enter the extension without the dot")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    TextField("Display Name", text: $displayName)
                } header: {
                    Text("Display Name")
                } footer: {
                    Text("How this file type appears in the list")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(HighlightLanguage.all) { lang in
                            Text(lang.displayName).tag(lang.id)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Syntax Highlighting")
                } footer: {
                    Text("Choose which language to use for syntax highlighting")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)

            Divider()

            // Footer buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Add Extension") {
                    addExtension()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 400, height: 420)
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func addExtension() {
        let ext = cleanedExtension

        // Run validation checks
        if let validationError = validateExtension(ext) {
            errorMessage = validationError
            showError = true
            return
        }

        // Check if extension already exists in built-in types
        if FileTypeRegistry.shared.fileType(for: ext) != nil {
            errorMessage = "This extension is already supported as a built-in type."
            showError = true
            return
        }

        // Check if extension already exists in custom extensions
        let existingCustom = SharedSettings.shared.customExtensions
        if existingCustom.contains(where: { $0.extensionName == ext }) {
            errorMessage = "This extension has already been added as a custom type."
            showError = true
            return
        }

        let customExt = CustomExtension(
            extensionName: ext,
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            highlightLanguage: selectedLanguage
        )

        onAdd(customExt)
        dismiss()
    }
}

#Preview {
    AddCustomExtensionSheet(onAdd: { _ in })
}
