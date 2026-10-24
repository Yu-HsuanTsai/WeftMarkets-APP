import SwiftUI

// Figma: Content/Stock Row
struct StockRow: View {
    let ranking: StockRanking
    var showsRank = true
    var metric: String
    var detail: String

    var body: some View {
        HStack(spacing: WeftSpacing.sm) {
            if showsRank {
                Text(String(format: "%02d", ranking.rank))
                    .font(.weftNumeric)
                    .foregroundStyle(WeftColor.textTertiary)
                    .frame(width: 24, alignment: .leading)
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(ranking.stock.ticker).font(.headline)
                    TickerTag(text: ranking.stock.market.rawValue, style: .line)
                }
                Text(ranking.stock.name)
                    .font(.footnote)
                    .foregroundStyle(WeftColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: WeftSpacing.xs)
            VStack(alignment: .trailing, spacing: 0) {
                Text(metric).font(.weftNumeric)
                Text(detail).font(.caption2.weight(.medium)).foregroundStyle(WeftColor.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(WeftColor.textSecondary)
        }
        .padding(.vertical, WeftSpacing.sm)
        .weftBottomHairline()
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// Figma: Content/Theme Row
struct ThemeRow: View {
    let theme: NarrativeTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: WeftSpacing.sm) {
                Text("\(theme.rank)").font(.weftNumeric).foregroundStyle(WeftColor.textTertiary)
                Text(theme.name).font(.headline)
                Spacer()
                Text(mentionsLabel).font(.weftNumeric)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle().fill(WeftColor.bgSecondary)
                    Rectangle().fill(WeftColor.accent).frame(width: proxy.size.width * theme.shareOfVoice)
                }
            }
            .frame(height: 6)
            .accessibilityHidden(true)
            Text(meta)
                .font(.caption.weight(.medium))
                .foregroundStyle(WeftColor.textSecondary)
                .lineLimit(2)
        }
        .padding(.vertical, WeftSpacing.sm)
        .weftBottomHairline()
    }

    private var share: String { theme.shareOfVoice.formatted(.percent.precision(.fractionLength(0))) }

    private var mentionsLabel: String {
        if let count = theme.mentionCount { return "\(count) 次 · \(share)" }
        return "聲量 \(share)"
    }

    private var meta: String {
        let tickers = "代表標的 " + theme.representativeTickers.joined(separator: "、")
        if let wow = theme.wowNote { return "\(wow) · \(tickers)" }
        return tickers
    }
}

// Figma: Content/KOL Mention Row
struct KOLMentionRow: View {
    let mention: KOLMention
    var onPlay: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(mention.showName).font(.subheadline.weight(.medium))
                Spacer()
                Text(mention.date).font(.weftMono).foregroundStyle(WeftColor.textSecondary)
            }
            Text(mention.topic).font(.callout).lineLimit(2)
            HStack {
                Text("當時 \(mention.priceThen) → 最新 \(mention.priceNow)")
                    .font(.footnote)
                    .foregroundStyle(WeftColor.textSecondary)
                Spacer()
                Text(mention.change).font(.weftNumeric)
            }
            if let onPlay {
                Button(action: onPlay) {
                    Label("回到原始片段", systemImage: "play.fill").font(.footnote)
                }
                .foregroundStyle(WeftColor.accent)
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, WeftSpacing.md)
        .weftBottomHairline()
    }
}

// Figma: Content/List Row
struct ListRowLabel: View {
    let title: String
    let systemImage: String
    var value: String?
    var showsChevron = true

    var body: some View {
        HStack(spacing: WeftSpacing.sm) {
            Image(systemName: systemImage)
                .frame(width: 24)
                .foregroundStyle(WeftColor.textPrimary)
            Text(title).font(.body)
            Spacer()
            if let value { Text(value).foregroundStyle(WeftColor.textSecondary) }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(WeftColor.textSecondary)
            }
        }
        .frame(minHeight: 52)
        .weftBottomHairline()
        .contentShape(Rectangle())
    }
}
