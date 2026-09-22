import SwiftUI

/// Where the pointer is over the Status page, in the `.global` coordinate space; nil when it is
/// elsewhere. Kept out of the page's own state so a mouse move re-renders only the logo that reads it.
@MainActor @Observable
final class PointerLocation {
    var point: CGPoint?
}

/// Pointer maths shared with the website's hero logo (`site/components/logo-animated.tsx`).
enum LogoParallax {
    /// The site's `POINTER_RANGE_PX`: how far from the logo the pointer must be for a full lean.
    static let range: CGFloat = 420

    /// Pointer offset from the logo's centre as a fraction of `range`, clamped to -1...1 per axis.
    static func lean(pointer: CGPoint?, center: CGPoint, range: CGFloat) -> CGSize {
        guard let pointer, range > 0 else { return .zero }
        func clamp(_ value: CGFloat) -> CGFloat { min(1, max(-1, value)) }
        return CGSize(width: clamp((pointer.x - center.x) / range),
                      height: clamp((pointer.y - center.y) / range))
    }
}

/// The website's hero logo, rebuilt for the Status page.
///
/// The blob, the ring and the pupil drift toward the pointer by 6, 12 and 22 points, so the mark seems
/// to look at it; every constant — springs, distances, the 90 s turn of the blob, the pupil's 3.2 s
/// breath and the staggered entrance — is the site's. The tile and ring follow the app icon's light and
/// dark variants. Reduce Motion leaves a still logo, as on the site, and the idle motion pauses while
/// the app is inactive.
struct AnimatedLogoView: View {
    /// Tile edge in points. Distances are the site's values at its 104 px hero size, scaled from there.
    var size: CGFloat = 96
    var pointer: PointerLocation

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.controlActiveState) private var controlActiveState

    @State private var center: CGPoint = .zero
    @State private var lean: CGSize = .zero
    @State private var appeared = false
    @State private var idleStart = Date()
    @State private var pausedAt: Date?

    private var unit: CGFloat { size / 104 }
    private var idlePaused: Bool { reduceMotion || controlActiveState == .inactive }
    private var entering: Bool { !appeared && !reduceMotion }

    /// The bundle that compiled `LogoLayers.xcassets`: the app, or the test bundle that builds this file.
    private static var assets: Bundle { Bundle(for: PointerLocation.self) }
    private static let brandBlue = Color(red: 23 / 255, green: 98 / 255, blue: 1)
    private static let ink = Color(red: 11 / 255, green: 18 / 255, blue: 32 / 255)
    private static let soft = Animation.interpolatingSpring(mass: 0.8, stiffness: 280, damping: 26)
    private static let pop = Animation.interpolatingSpring(mass: 0.7, stiffness: 420, damping: 20)
    private static let follow = Animation.interpolatingSpring(mass: 0.5, stiffness: 140, damping: 22)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: idlePaused)) { context in
            layers(idle: reduceMotion ? 0 : max(0, context.date.timeIntervalSince(idleStart)))
        }
        .frame(width: size, height: size)
        .onGeometryChange(for: CGPoint.self) { proxy in
            let frame = proxy.frame(in: .global)
            return CGPoint(x: frame.midX, y: frame.midY)
        } action: { newCenter in
            center = newCenter
            track(pointer.point)
        }
        .onChange(of: pointer.point) { _, point in track(point) }
        .onChange(of: idlePaused) { _, paused in
            // Resume the turn where it stopped instead of jumping by the time spent inactive.
            if paused {
                pausedAt = Date()
            } else if let pausedAt {
                idleStart += Date().timeIntervalSince(pausedAt)
                self.pausedAt = nil
            }
        }
        .onAppear {
            idleStart = Date()
            pausedAt = idlePaused ? idleStart : nil
            appeared = true
        }
        .accessibilityHidden(true)
    }

    private func track(_ point: CGPoint?) {
        guard !reduceMotion else { return }
        let target = LogoParallax.lean(pointer: point, center: center, range: LogoParallax.range * unit)
        guard target != lean else { return }
        withAnimation(Self.follow) { lean = target }
    }

    private func drift(_ distance: CGFloat) -> CGSize {
        CGSize(width: lean.width * distance * unit, height: lean.height * distance * unit)
    }

    private func layers(idle t: TimeInterval) -> some View {
        let spin = Angle.degrees((t / 90).truncatingRemainder(dividingBy: 1) * 360)
        let breath = t < 0.9 ? 1 : 1 + 0.0175 * (1 - cos(2 * .pi * (t - 0.9) / 3.2))
        let tile = RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
        let dark = colorScheme == .dark

        return ZStack {
            Image("LogoMotive", bundle: Self.assets)
                .resizable()
                .interpolation(.high)
                .frame(width: size * 0.8, height: size * 0.8)
                .shadow(color: Self.brandBlue.opacity(0.22), radius: 8 * unit, y: 10 * unit)
                .rotationEffect(spin)
                .rotationEffect(.degrees(entering ? -6 : 0))
                .scaleEffect(entering ? 0.86 : 1.25)
                .opacity(appeared ? 1 : 0)
                .animation(Self.soft.delay(0.04), value: appeared)
                .offset(drift(6))

            Circle()
                .fill(LinearGradient(colors: dark ? [Color(hex: "232C3D"), Color(hex: "181E2D")]
                                                  : [Color(hex: "FCFDFE"), Color(hex: "DFE6EA")],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.52, height: size * 0.52)
                .shadow(color: (dark ? .black : Self.ink).opacity(dark ? 0.35 : 0.12), radius: 3 * unit, y: 3 * unit)
                .rotationEffect(.degrees(entering ? -22 : 0))
                .scaleEffect(entering ? 0.92 : 1)
                .opacity(appeared ? 1 : 0)
                .animation(Self.soft.delay(0.22), value: appeared)
                .offset(drift(12))

            Image("LogoFocal", bundle: Self.assets)
                .resizable()
                .interpolation(.high)
                .frame(width: size * 0.28, height: size * 0.28)
                .shadow(color: Self.brandBlue.opacity(0.28), radius: 7 * unit, y: 8 * unit)
                .scaleEffect(entering ? 0.78 : 1)
                .offset(y: entering ? -10 * unit : 0)
                .opacity(appeared ? 1 : 0)
                .animation(Self.pop.delay(0.38), value: appeared)
                .scaleEffect(breath)
                .offset(drift(22))
        }
        .frame(width: size, height: size)
        .background {
            tile.fill(RadialGradient(
                stops: dark
                    ? [.init(color: Color(hex: "222A36"), location: 0), .init(color: Color(hex: "161C25"), location: 0.6),
                       .init(color: Color(hex: "0F141B"), location: 1)]
                    : [.init(color: .white, location: 0), .init(color: Color(hex: "F4F6F9"), location: 0.6),
                       .init(color: Color(hex: "E9EDF3"), location: 1)],
                center: UnitPoint(x: 0.3, y: 0.2), startRadius: 0, endRadius: size * 1.2))
        }
        .overlay {
            // The site's glass sheen: a soft highlight from the top, a faint blue glow from below.
            ZStack {
                RadialGradient(colors: [.white.opacity(dark ? 0.08 : 0.45), .clear],
                               center: .top, startRadius: 0, endRadius: size * 0.55)
                RadialGradient(colors: [Self.brandBlue.opacity(0.08), .clear],
                               center: UnitPoint(x: 0.5, y: 1.1), startRadius: 0, endRadius: size * 0.45)
            }
            .blendMode(.screen)
            .allowsHitTesting(false)
        }
        .clipShape(tile)
        .overlay {
            tile.strokeBorder(LinearGradient(colors: [.white.opacity(dark ? 0.14 : 0.9), .clear, Self.ink.opacity(0.04)],
                                             startPoint: .top, endPoint: .bottom),
                              lineWidth: 1)
        }
        .shadow(color: (dark ? .black : Self.ink).opacity(dark ? 0.45 : 0.18), radius: 10 * unit, y: 14 * unit)
        .shadow(color: Self.brandBlue.opacity(dark ? 0.22 : 0.18), radius: 5 * unit, y: 5 * unit)
    }
}
