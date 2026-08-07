import SwiftUI

/// Shared chrome for a settings tab: each page scrolls independently so a small window still
/// reaches every control, and pages stay top-aligned instead of centring in the tab area.
extension View {
    func settingsTabPage() -> some View {
        ScrollView {
            self
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
