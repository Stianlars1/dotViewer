import SwiftUI

// The building blocks every Settings pane is made of. The pane is a grouped `Form`, which puts the
// label on the leading edge and the control on the trailing edge of each row; these components keep
// the label side identical everywhere — a title, optionally one secondary line under it.

/// A row label: the setting's name and, when it needs one, a short secondary description.
struct SettingsLabel: View {
    private let title: String
    private let description: String?

    init(_ title: String, description: String? = nil) {
        self.title = title
        self.description = description
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            if let description {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// A slider row: label leading; a fixed-width slider and its value trailing, so sliders line up
/// down the pane and the value never makes the slider jump.
struct SettingsSliderRow: View {
    private let title: String
    private let description: String?
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let format: (Double) -> String

    init(
        _ title: String,
        description: String? = nil,
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double,
        format: @escaping (Double) -> String
    ) {
        self.title = title
        self.description = description
        self._value = value
        self.range = range
        self.step = step
        self.format = format
    }

    var body: some View {
        LabeledContent {
            HStack(spacing: 10) {
                Slider(value: $value, in: range, step: step)
                    .labelsHidden()
                    .frame(width: 180)
                Text(format(value))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 58, alignment: .trailing)
            }
        } label: {
            SettingsLabel(title, description: description)
        }
    }
}

/// A status row for things macOS grants outside the app, such as permissions: a green check or an
/// orange warning before the label, actions trailing.
struct SettingsStatusRow<Actions: View>: View {
    private let isOK: Bool
    private let title: String
    private let description: String?
    private let actions: Actions

    init(isOK: Bool, title: String, description: String? = nil, @ViewBuilder actions: () -> Actions) {
        self.isOK = isOK
        self.title = title
        self.description = description
        self.actions = actions()
    }

    var body: some View {
        LabeledContent {
            HStack(spacing: 8) { actions }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: isOK ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(isOK ? Color.green : Color.orange)
                    .accessibilityLabel(isOK ? "Granted" : "Needs attention")
                SettingsLabel(title, description: description)
            }
        }
    }
}

/// A font menu with a Reset button that appears only when the choice differs from the default.
struct SettingsFontPicker: View {
    @Binding var selection: String
    let families: [String]
    let defaultFamily: String

    var body: some View {
        HStack(spacing: 8) {
            if selection != defaultFamily {
                Button("Reset") { selection = defaultFamily }
                    .controlSize(.small)
            }
            Picker("Font", selection: $selection) {
                ForEach(families, id: \.self) { family in
                    Text(PreviewFontMenu.title(for: family)).tag(family)
                }
            }
            .labelsHidden()
            .fixedSize()
        }
    }
}

extension View {
    /// The one look every pane shares: System Settings-style grouped rows, switches for on/off.
    func settingsPaneStyle() -> some View {
        formStyle(.grouped)
            .toggleStyle(.switch)
    }
}

extension EnvironmentValues {
    /// The setting a search result pointed at; its row is highlighted briefly.
    @Entry var highlightedSetting: SettingID? = nil
}

private struct SettingsAnchor: ViewModifier {
    let id: SettingID
    @Environment(\.highlightedSetting) private var highlighted

    func body(content: Content) -> some View {
        content
            .id(id)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(highlighted == id ? 0.18 : 0))
                    .padding(.horizontal, -8)
                    .padding(.vertical, -5)
                    .animation(.easeOut(duration: 0.3), value: highlighted)
            }
    }
}

extension View {
    /// Marks a row as the home of a catalog setting, so search can scroll to it and highlight it.
    func settingsAnchor(_ id: SettingID) -> some View {
        modifier(SettingsAnchor(id: id))
    }
}

extension Binding where Value == Int {
    /// Lets a `Slider` (which works in `Double`) edit a whole-number setting.
    var asDouble: Binding<Double> {
        Binding<Double>(
            get: { Double(wrappedValue) },
            set: { wrappedValue = Int($0.rounded()) }
        )
    }
}
