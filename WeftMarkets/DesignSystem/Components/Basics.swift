import SwiftUI

// Brand wordmark used in the 本週 masthead.
struct WeftWordmark: View {
    var size: CGFloat = 26

    var body: some View {
        Text("Weft")
            .font(.system(size: size, weight: .black, design: .serif))
            .tracking(-0.5 * size / 26)
            .foregroundStyle(WeftColor.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}

// Figma: Brand/Ticker Tag (Solid / Line)
struct TickerTag: View {
    enum Style { case solid, line }
    let text: String
    var style: Style = .solid

    var body: some View {
        Text(text)
            .font(.weftTag)
            .tracking(0.6)
            .foregroundStyle(style == .solid ? WeftColor.textOnAccent : WeftColor.textPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(style == .solid ? WeftColor.textPrimary : .clear)
            .overlay {
                if style == .line { Rectangle().stroke(WeftColor.rule, lineWidth: WeftStroke.thin) }
            }
    }
}

struct TickerTagRow: View {
    let tickers: [String]
    var limit = 3

    var body: some View {
        HStack(spacing: 6) {
            ForEach(tickers.prefix(limit), id: \.self) { TickerTag(text: $0) }
            if tickers.count > limit {
                Text("+\(tickers.count - limit)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WeftColor.textSecondary)
            }
        }
    }
}

// Figma: Brand/Filter Chip (Selected)
struct FilterChip: View {
    let label: String
    var count: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.subheadline.weight(.medium))
                if let count {
                    Text(count)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(isSelected ? WeftColor.textInverse : WeftColor.textSecondary)
                }
            }
            .foregroundStyle(isSelected ? WeftColor.textOnAccent : WeftColor.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? WeftColor.textPrimary : WeftColor.bgPrimary)
            .weftBorder()
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// Figma: Brand/Section Header — 4pt newspaper rule on top
struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(title).font(.title3.weight(.bold))
            Spacer()
            trailing
                .font(.subheadline.weight(.medium))
                .foregroundStyle(WeftColor.accent)
        }
        .padding(.top, 10)
        .weftTopRule()
        .accessibilityAddTraits(.isHeader)
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.title = title
        self.trailing = EmptyView()
    }
}

// Figma: Brand/Stat Tile
struct StatTile: View {
    let label: String
    let value: String
    var unit: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(WeftColor.textSecondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.weftNumericLarge)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                if !unit.isEmpty {
                    Text(unit).font(.footnote).foregroundStyle(WeftColor.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .weftTopRule(WeftStroke.thin)
        .accessibilityElement(children: .combine)
    }
}

// Figma: Brand/Banner (Info / Warning)
struct InfoBanner: View {
    enum Kind { case info, warning }
    let message: String
    var kind: Kind = .info

    var body: some View {
        HStack(alignment: .top, spacing: WeftSpacing.xs) {
            Image(systemName: kind == .info ? "info.circle" : "exclamationmark.triangle")
                .foregroundStyle(kind == .info ? WeftColor.textSecondary : WeftColor.textPrimary)
            Text(message)
                .font(.footnote)
                .foregroundStyle(kind == .info ? WeftColor.textSecondary : WeftColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(WeftSpacing.sm)
        .background(kind == .info ? WeftColor.bgSecondary : WeftColor.highlightSoft)
        .overlay(alignment: .leading) {
            if kind == .warning { Rectangle().fill(WeftColor.rule).frame(width: WeftStroke.thick) }
        }
    }
}

// Figma: Brand/Button (Primary / Secondary / Text)
struct WeftButtonStyle: ButtonStyle {
    enum Kind { case primary, secondary, text }
    var kind: Kind = .primary

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(.weftButton)
            .underline(kind == .text)
            .foregroundStyle(foreground)
            .frame(maxWidth: kind == .text ? nil : .infinity, minHeight: kind == .text ? 44 : 50)
            .padding(.horizontal, kind == .text ? 2 : WeftSpacing.lg)
            .background(background(pressed: pressed))
            .overlay {
                if kind != .text {
                    Rectangle().stroke(kind == .primary ? WeftColor.accent : WeftColor.rule, lineWidth: WeftStroke.thin)
                }
            }
            .contentShape(Rectangle())
    }

    private var foreground: Color {
        switch kind {
        case .primary: WeftColor.textOnAccent
        case .secondary: WeftColor.textPrimary
        case .text: WeftColor.accent
        }
    }

    private func background(pressed: Bool) -> Color {
        switch kind {
        case .primary: pressed ? WeftColor.accentPressed : WeftColor.accent
        case .secondary: pressed ? WeftColor.bgSecondary : WeftColor.bgPrimary
        case .text: .clear
        }
    }
}

extension ButtonStyle where Self == WeftButtonStyle {
    static var weftPrimary: WeftButtonStyle { WeftButtonStyle(kind: .primary) }
    static var weftSecondary: WeftButtonStyle { WeftButtonStyle(kind: .secondary) }
    static var weftText: WeftButtonStyle { WeftButtonStyle(kind: .text) }
}

// Figma: Brand/Disclaimer
struct Disclaimer: View {
    var text = "每日 11:30（台北）更新。內容整理自 4 個財經節目，每則重點都附原始時間點。討論熱度不是投資建議。"

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(WeftColor.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, WeftSpacing.sm)
            .weftTopRule(WeftStroke.thin, color: WeftColor.ruleFaint)
    }
}

/// Chart area. Real series come from the API (Swift Charts); until then the
/// area is labelled instead of showing made-up numbers — same rule as Figma.
struct ChartPlaceholder: View {
    let title: String
    let note: String
    var minHeight: CGFloat = 150

    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.subheadline.weight(.medium))
            Text(note)
                .font(.caption.weight(.medium))
                .foregroundStyle(WeftColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(WeftSpacing.md)
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .overlay(Rectangle().stroke(WeftColor.ruleFaint, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
    }
}

/// Mono kicker above titles, e.g. "PODCAST · GOOAYE 股癌 · 2026-10-10".
struct Kicker: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.weftKicker)
            .tracking(0.9)
            .foregroundStyle(WeftColor.textSecondary)
    }
}
