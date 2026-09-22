import XCTest
import AppKit

/// The Status page logo ports `site/components/logo-animated.tsx`; these pin its pointer maths to the
/// site's and make sure the layer art the view names is actually in the asset catalog.
final class AnimatedLogoViewTests: XCTestCase {
    private let center = CGPoint(x: 500, y: 300)

    func testNoPointerMeansNoLean() {
        XCTAssertEqual(LogoParallax.lean(pointer: nil, center: center, range: 420), .zero)
        XCTAssertEqual(LogoParallax.lean(pointer: center, center: center, range: 420), .zero)
    }

    func testLeanIsOffsetOverRangeWithScreenStyleYAxis() {
        let lean = LogoParallax.lean(pointer: CGPoint(x: 710, y: 195), center: center, range: 420)
        XCTAssertEqual(lean.width, 0.5, accuracy: 1e-9)
        XCTAssertEqual(lean.height, -0.25, accuracy: 1e-9, "Above the logo leans up, as in the browser")
    }

    func testLeanIsClampedPerAxis() {
        let lean = LogoParallax.lean(pointer: CGPoint(x: -2_000, y: 5_000), center: center, range: 420)
        XCTAssertEqual(lean, CGSize(width: -1, height: 1))
    }

    func testZeroRangeIsIgnored() {
        XCTAssertEqual(LogoParallax.lean(pointer: .zero, center: center, range: 0), .zero)
    }

    func testLayerArtIsInTheAssetCatalog() throws {
        let bundle = Bundle(for: PointerLocation.self)
        for name in ["LogoMotive", "LogoFocal"] {
            let image = try XCTUnwrap(bundle.image(forResource: name), name)
            XCTAssertGreaterThan(image.size.width, 0, name)
        }
    }
}
