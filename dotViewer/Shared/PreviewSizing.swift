import CoreGraphics

public enum PreviewSizing {

    public struct AspectRatio: Sendable {
        public let widthFactor: CGFloat
        public let heightFactor: CGFloat

        public init(_ w: CGFloat, _ h: CGFloat) {
            widthFactor = w
            heightFactor = h
        }

        public func heightForWidth(_ width: CGFloat) -> CGFloat {
            (width / widthFactor) * heightFactor
        }

        public static let r16x10 = AspectRatio(16, 10)
        public static let r16x9  = AspectRatio(16, 9)
        public static let r4x3   = AspectRatio(4, 3)
        public static let r3x2   = AspectRatio(3, 2)
        public static let r1x1   = AspectRatio(1, 1)

        public static func from(key: String) -> AspectRatio {
            switch key {
            case "16:9":  return .r16x9
            case "4:3":   return .r4x3
            case "3:2":   return .r3x2
            case "1:1":   return .r1x1
            default:      return .r16x10
            }
        }

        public static let allKeys = ["16:10", "16:9", "4:3", "3:2", "1:1"]
    }

    public static func initialContentSize(
        lineCount: Int,
        fontSize: Double,
        showHeader: Bool,
        windowSizeMode: String,
        fixedWidth: Int,
        fixedHeight: Int,
        lastWidth: Int = 700,
        lastHeight: Int = 560,
        aspectRatioKey: String = "16:10",
        aspectBaseWidth: Int = 700
    ) -> CGSize {
        switch windowSizeMode {
        case "fixed":
            return CGSize(
                width: CGFloat(clampW(fixedWidth)),
                height: CGFloat(clampH(fixedHeight))
            )

        case "remember":
            return CGSize(
                width: CGFloat(clampW(lastWidth)),
                height: CGFloat(clampH(lastHeight))
            )

        case "aspect":
            let w = CGFloat(clampW(aspectBaseWidth))
            let ratio = AspectRatio.from(key: aspectRatioKey)
            let h = ratio.heightForWidth(w)
            return CGSize(
                width: w,
                height: CGFloat(clampH(Int(h)))
            )

        case "contentFixed":
            let w = CGFloat(clampW(fixedWidth))
            let lineHeight = fontSize * 1.45
            let headerHeight: CGFloat = showHeader ? 48 : 0
            let padding: CGFloat = 32
            let contentHeight = CGFloat(lineCount) * lineHeight + headerHeight + padding
            let cappedHeight = min(contentHeight, CGFloat(clampH(fixedHeight)))
            return CGSize(
                width: w,
                height: max(cappedHeight, 220)
            )

        default:
            // "auto" — content-aware with sensible minimums
            let lineHeight = fontSize * 1.45
            let headerHeight: CGFloat = showHeader ? 48 : 0
            let padding: CGFloat = 32
            let contentHeight = CGFloat(lineCount) * lineHeight
            let estimatedHeight = contentHeight + headerHeight + padding

            return CGSize(
                width: 700,
                height: min(max(estimatedHeight, 420), 1000)
            )
        }
    }

    private static func clampW(_ v: Int) -> Int { max(420, min(1600, v)) }
    private static func clampH(_ v: Int) -> Int { max(220, min(1400, v)) }
}
