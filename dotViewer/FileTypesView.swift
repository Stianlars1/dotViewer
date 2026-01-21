import SwiftUI

struct FileTypesView: View {
    @State private var searchText = ""
    @State private var showAddCustom = false
    @State private var disabledTypes: Set<String> = SharedSettings.shared.disabledFileTypes
    @State private var customExtensions: [CustomExtension] = SharedSettings.shared.customExtensions
    @State private var editingExtension: CustomExtension? = nil
    @State private var expandedCategories: Set<FileTypeCategory> = []

    private let registry = FileTypeRegistry.shared

    var filteredTypes: [(FileTypeCategory, [SupportedFileType])] {
        let grouped = registry.typesByCategory()

        var result: [(FileTypeCategory, [SupportedFileType])] = []

        for category in FileTypeCategory.allCases.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            guard let types = grouped[category] else { continue }

            let filtered: [SupportedFileType]
            if searchText.isEmpty {
                filtered = types
            } else {
                filtered = types.filter { type in
                    type.displayName.localizedCaseInsensitiveContains(searchText) ||
                    type.extensions.contains { $0.localizedCaseInsensitiveContains(searchText) }
                }
            }

            if !filtered.isEmpty {
                result.append((category, filtered))
            }
        }

        return result
    }

    var filteredCustomExtensions: [CustomExtension] {
        if searchText.isEmpty {
            return customExtensions
        }
        return customExtensions.filter { ext in
            ext.displayName.localizedCaseInsensitiveContains(searchText) ||
            ext.extensionName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with search and add button
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search file types...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    showAddCustom = true
                } label: {
                    Label("Add Custom", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // File types list
            List {
                // Built-in types by category
                ForEach(filteredTypes, id: \.0) { category, types in
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedCategories.contains(category) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedCategories.insert(category)
                                } else {
                                    expandedCategories.remove(category)
                                }
                            }
                        )
                    ) {
                        ForEach(types) { type in
                            FileTypeRow(
                                type: type,
                                isEnabled: !disabledTypes.contains(type.id),
                                onToggle: { toggleType(type) }
                            )
                        }
                    } label: {
                        HStack {
                            Label(category.rawValue, systemImage: category.icon)
                                .font(.headline)
                            Spacer()
                            Text("\(types.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Custom extensions section
                if !customExtensions.isEmpty || !searchText.isEmpty {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedCategories.contains(.custom) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedCategories.insert(.custom)
                                } else {
                                    expandedCategories.remove(.custom)
                                }
                            }
                        )
                    ) {
                        if filteredCustomExtensions.isEmpty && !searchText.isEmpty {
                            Text("No matching custom extensions")
                                .foregroundStyle(.secondary)
                                .italic()
                        } else if filteredCustomExtensions.isEmpty {
                            Text("No custom extensions added yet")
                                .foregroundStyle(.secondary)
                                .italic()
                        } else {
                            ForEach(filteredCustomExtensions) { ext in
                                CustomExtensionRow(
                                    customExtension: ext,
                                    onEdit: { editingExtension = ext },
                                    onDelete: { deleteCustomExtension(ext) }
                                )
                            }
                        }
                    } label: {
                        HStack {
                            Label(FileTypeCategory.custom.rawValue, systemImage: FileTypeCategory.custom.icon)
                                .font(.headline)
                            Spacer()
                            Text("\(customExtensions.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
        }
        .navigationTitle("File Types")
        .sheet(isPresented: $showAddCustom) {
            AddCustomExtensionSheet(
                onAdd: { ext in
                    customExtensions.append(ext)
                    saveCustomExtensions()
                }
            )
        }
        .sheet(item: $editingExtension) { ext in
            EditCustomExtensionSheet(
                customExtension: ext,
                onSave: { updated in
                    updateCustomExtension(updated)
                }
            )
        }
        .onAppear {
            disabledTypes = SharedSettings.shared.disabledFileTypes
            customExtensions = SharedSettings.shared.customExtensions
        }
    }

    private func toggleType(_ type: SupportedFileType) {
        if disabledTypes.contains(type.id) {
            disabledTypes.remove(type.id)
        } else {
            disabledTypes.insert(type.id)
        }
        SharedSettings.shared.disabledFileTypes = disabledTypes
    }

    private func deleteCustomExtension(_ ext: CustomExtension) {
        customExtensions.removeAll { $0.id == ext.id }
        saveCustomExtensions()
    }

    private func updateCustomExtension(_ updated: CustomExtension) {
        if let index = customExtensions.firstIndex(where: { $0.id == updated.id }) {
            customExtensions[index] = updated
            saveCustomExtensions()
        }
    }

    private func saveCustomExtensions() {
        SharedSettings.shared.customExtensions = customExtensions
    }
}

struct FileTypeRow: View {
    let type: SupportedFileType
    let isEnabled: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.switch)
            .labelsHidden()
            .controlSize(.small)

            VStack(alignment: .leading, spacing: 2) {
                Text(type.displayName)
                    .fontWeight(.medium)

                Text(type.extensionDisplay)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if type.isSystemUTI {
                Text("System")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

struct CustomExtensionRow: View {
    let customExtension: CustomExtension
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(customExtension.displayName)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(".\(customExtension.extensionName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Text(customExtension.highlightLanguage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
}

struct EditCustomExtensionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let customExtension: CustomExtension
    let onSave: (CustomExtension) -> Void

    @State private var displayName: String
    @State private var selectedLanguage: String

    init(customExtension: CustomExtension, onSave: @escaping (CustomExtension) -> Void) {
        self.customExtension = customExtension
        self.onSave = onSave
        _displayName = State(initialValue: customExtension.displayName)
        _selectedLanguage = State(initialValue: customExtension.highlightLanguage)
    }

    private var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Custom Extension")
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
                        Text(customExtension.extensionName)
                            .foregroundStyle(.primary)
                    }
                } header: {
                    Text("File Extension")
                } footer: {
                    Text("Extension cannot be changed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    TextField("Display Name", text: $displayName)
                } header: {
                    Text("Display Name")
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

                Button("Save Changes") {
                    let updated = CustomExtension(
                        id: customExtension.id,
                        extensionName: customExtension.extensionName,
                        displayName: displayName.trimmingCharacters(in: .whitespaces),
                        highlightLanguage: selectedLanguage
                    )
                    onSave(updated)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 400, height: 380)
    }
}

#Preview {
    FileTypesView()
        .frame(width: 500, height: 600)
}
