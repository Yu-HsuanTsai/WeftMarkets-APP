import SwiftUI

// Design tokens mirrored from the Figma file "WeftMarkets iOS App"
// (variable collections: Primitives / Color / Spacing), which in turn
// mirror the weftmarkets.com CSS custom properties.

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

enum WeftColor {
    // Primitives
    private static let ink = Color(hex: 0x0A0A0A)
    private static let paper = Color(hex: 0xFFFFFF)
    private static let gray700 = Color(hex: 0x6B6B6B)
    private static let gray500 = Color(hex: 0x9A9A9A)
    private static let gray300 = Color(hex: 0xD4D4D4)
    private static let gray100 = Color(hex: 0xEDEDED)
    private static let blue500 = Color(hex: 0x1F3FFF)
    private static let blue700 = Color(hex: 0x1530CC)
    private static let yellow100 = Color(hex: 0xFFF6A8)
    private static let machineL2 = Color(hex: 0x161616)
    private static let machineText = Color(hex: 0xE8E8E8)

    // Semantic (color/bg/*, color/text/*, color/border/*)
    static let bgPrimary = paper
    static let bgSecondary = gray100
    static let bgInverse = machineL2
    static let accent = blue500
    static let accentPressed = blue700
    static let highlightSoft = yellow100
    static let skeleton = gray100

    static let textPrimary = ink
    static let textSecondary = gray700
    static let textTertiary = gray500
    static let textOnAccent = paper
    static let textInverse = machineText

    static let rule = ink
    static let ruleFaint = gray300
}

enum WeftSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 40
    static let xxl: CGFloat = 64
}

enum WeftStroke {
    static let thin: CGFloat = 1
    static let thick: CGFloat = 4
}

// Text styles map to the Figma "iOS/*" and "Brand/*" text styles.
// System fonts are used so Dynamic Type keeps working; on zh-Hant devices
// the system resolves CJK glyphs to PingFang TC.
extension Font {
    static let weftKicker = Font.system(.caption2, design: .monospaced).weight(.medium)
    static let weftMono = Font.system(.caption, design: .monospaced)
    static let weftTag = Font.system(size: 11, weight: .heavy)
    static let weftNumeric = Font.system(.body).weight(.semibold).monospacedDigit()
    static let weftNumericLarge = Font.system(.largeTitle).weight(.bold).monospacedDigit()
    static let weftButton = Font.system(.subheadline).weight(.bold)
}

extension View {
    /// Newspaper-style top rule used by section headers (4pt) and stat tiles (1pt).
    func weftTopRule(_ width: CGFloat = WeftStroke.thick, color: Color = WeftColor.rule) -> some View {
        overlay(alignment: .top) {
            Rectangle().fill(color).frame(height: width)
        }
    }

    /// Hairline separator under list rows.
    func weftBottomHairline() -> some View {
        overlay(alignment: .bottom) {
            Rectangle().fill(WeftColor.ruleFaint).frame(height: WeftStroke.thin)
        }
    }

    /// Square 1pt ink frame used by cards and secondary buttons.
    func weftBorder(_ color: Color = WeftColor.rule) -> some View {
        overlay(Rectangle().stroke(color, lineWidth: WeftStroke.thin))
    }
}
