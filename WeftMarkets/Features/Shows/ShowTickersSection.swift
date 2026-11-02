import SwiftUI

/// 近 30 天提到的標的 on a show page (`publishers/{key}/tickers`), following
/// weftmarkets.com: 全部 / 台股 / 美股, newest last mention first, 15 rows until expanded.
struct ShowTickersSection: View {
    let showID: String
    @Environment(\.repository) private var repository
    @State private var market: Market?
    @State private var showsAll = false

    private static let collapsedCount = 15

    var body: some View {
        VStack(alignment: .leading, spacing: WeftSpacing.sm) {
            SectionHeader("近 30 天提到的標的")
            Text("價格為還原收盤參考，非節目當下成交價；只呈現說了什麼與之後價格，不評分對錯。非投資建議。")
                .font(.caption.weight(.medium))
                .foregroundStyle(WeftColor.textSecondary)

            AsyncContent(load: { try await repository.showTickers(showID: showID) }) { rows in
                if rows.isEmpty {
                    StateView(kind: .empty, title: "近 30 天沒有提到的標的")
                } else {
                    content(rows)
                }
            } placeholder: {
                SkeletonRow()
            }
        }
    }

    @ViewBuilder
    private func content(_ rows: [ShowTickerRow]) -> some View {
        let filtered = rows.filter { market == nil || $0.stock.market == market }
        let visible = showsAll ? filtered : Array(filtered.prefix(Self.collapsedCount))

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: WeftSpacing.xs) {
                chip("全部", nil, rows.count)
                chip("台股", .tw, rows.filter { $0.stock.market == .tw }.count)
                chip("美股", .us, rows.filter { $0.stock.market == .us }.count)
            }
        }
        Text("顯示 \(visible.count) / \(filtered.count) 檔 · 依上次提及由新到舊")
            .font(.weftMono)
            .foregroundStyle(WeftColor.textSecondary)

        LazyVStack(spacing: 0) {
            ForEach(visible) { row in
                NavigationLink(value: Route.stock(row.stock.ticker)) { ShowTickerRowView(row: row) }
                    .buttonStyle(.plain)
            }
        }
        if filtered.count > visible.count {
            Button("顯示全部 \(filtered.count) 檔") { showsAll = true }
                .buttonStyle(.weftSecondary)
        }
    }

    private func chip(_ label: String, _ value: Market?, _ count: Int) -> some View {
        FilterChip(label: label, count: "\(count) 檔", isSelected: market == value) {
            market = value
            showsAll = false
        }
    }
}

private struct ShowTickerRowView: View {
    let row: ShowTickerRow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: WeftSpacing.xs) {
                Text(row.stock.ticker).font(.headline)
                Text(row.stock.name)
                    .font(.footnote)
                    .foregroundStyle(WeftColor.textSecondary)
                    .lineLimit(1)
                TickerTag(text: row.stock.market == .tw ? "台股" : "美股", style: .line)
                Spacer()
                Text(row.changePct.map { String(format: "%+.2f%%", $0) } ?? "—")
                    .font(.weftNumeric)
            }
            Text(row.subject).font(.callout).lineLimit(2)
            HStack {
                Text(["上次提及 \(row.lastMentionDate)", row.minuteLabel].compactMap { $0 }.joined(separator: " · "))
                Spacer()
                if let days = row.daysSinceMention { Text("距收錄日 \(days) 天") }
            }
            .font(.weftMono)
            .foregroundStyle(WeftColor.textSecondary)
            Text(row.priceLine)
                .font(.footnote)
                .foregroundStyle(WeftColor.textSecondary)
        }
        .padding(.vertical, WeftSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .weftBottomHairline()
        .contentShape(Rectangle())
    }
}
