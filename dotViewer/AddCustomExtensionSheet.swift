import SwiftUI

struct AddCustomExtensionSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var extensionName = ""
    @State private var displayName = ""
    @State private var selectedLanguage = "plaintext"
    @State private var showError = false
    @State private var errorMessage = ""

    let onAdd: (CustomExtension) -> Void

    private var isValid: Bool {
        !extensionName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var cleanedExtension: String {
        extensionName
            .lowercased()
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
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
        // Validate extension doesn't already exist
        let ext = cleanedExtension

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
