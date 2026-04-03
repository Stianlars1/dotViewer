import CoreGraphics

public enum PreviewSizing {
    public static func initialContentSize(
        lineCount: Int,
        fontSize: Double,
        showHeader: Bool,
        windowSizeMode: String,
        fixedWidth: Int,
        fixedHeight: Int
    ) -> CGSize {
        if windowSizeMode == "fixed" {
            return CGSize(
                width: CGFloat(max(420, min(1600, fixedWidth))),
                height: CGFloat(max(220, min(1400, fixedHeight)))
            )
        }

        let lineHeight = fontSize * 1.45
        let headerHeight: CGFloat = showHeader ? 48 : 0
        let padding: CGFloat = 32
        let contentHeight = CGFloat(lineCount) * lineHeight
        let estimatedHeight = contentHeight + headerHeight + padding

        return CGSize(
            width: lineCount <= 5 ? 420 : 700,
            height: min(max(estimatedHeight, 160), 1000)
        )
    }
}
