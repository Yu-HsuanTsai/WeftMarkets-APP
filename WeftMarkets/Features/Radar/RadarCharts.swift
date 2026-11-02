import Charts
import SwiftUI

// MARK: - 近 12 週提及趨勢 · 累計 Top 5

/// Styled like weftmarkets.com: the first series in accent blue, the rest in ink with
/// distinct dash patterns so they stay readable without color. Tap a legend row to
/// focus one stock; drag across the chart to read a week.
struct MentionTrendChart: View {
    let trend: MentionTrend
    @State private var focused: String?
    @State private var selectedWeek: String?
    @State private var showsTable = false

    private static let dashes: [[CGFloat]] = [[], [6, 4], [2, 4], [10, 3, 2, 3], [1, 3]]

    private func color(_ index: Int) -> Color { index == 0 ? WeftColor.accent : WeftColor.textPrimary }
    private func dash(_ index: Int) -> [CGFloat] { Self.dashes[index % Self.dashes.count] }

    var body: some View {
        VStack(alignment: .leading, spacing: WeftSpacing.sm) {
            Text("提及次數 / 週 · 缺週顯示 0，請搭配涵蓋範圍解讀\(trend.lastWeekPartial ? " · 最後一週還沒走完" : "")")
                .font(.caption.weight(.medium))
                .foregroundStyle(WeftColor.textSecondary)

            chart
            readout
            legend

            DisclosureGroup("查看完整數據表", isExpanded: $showsTable) { table }
                .font(.footnote)
                .tint(WeftColor.textSecondary)
        }
    }

    private var chart: some View {
        Chart {
            ForEach(Array(trend.series.enumerated()), id: \.element.id) { index, series in
                ForEach(Array(trend.weeks.enumerated()), id: \.offset) { i, week in
                    LineMark(x: .value("週", week), y: .value("提及", series.values[i]),
                             series: .value("個股", series.label))
                        .foregroundStyle(color(index))
                        .lineStyle(StrokeStyle(lineWidth: index == 0 ? 2.5 : 1.5, dash: dash(index)))
                        .opacity(focused == nil || focused == series.id ? 1 : 0.15)
                }
            }
            if let selectedWeek {
                RuleMark(x: .value("週", selectedWeek)).foregroundStyle(WeftColor.ruleFaint)
            }
        }
        .chartXScale(domain: trend.weeks)
        .chartXAxis {
            let shown = Set(axisLabels)
            AxisMarks { value in
                if let label = value.as(String.self), shown.contains(label) {
                    AxisValueLabel().font(.caption2.monospacedDigit())
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(WeftColor.ruleFaint)
                AxisValueLabel()
            }
        }
        .chartLegend(.hidden)
        .chartXSelection(value: $selectedWeek)
        .frame(height: 220)
        .accessibilityLabel("近 \(trend.weeks.count) 週提及次數，累計前 \(trend.series.count) 名")
    }

    /// Every other week plus the last, like the site; a label right before the last is
    /// dropped so the two don't collide.
    private var axisLabels: [String] {
        var picked = Array(stride(from: 0, to: trend.weeks.count, by: 2))
        if let last = trend.weeks.indices.last, picked.last != last {
            if let previous = picked.last, last - previous < 2 { picked.removeLast() }
            picked.append(last)
        }
        return picked.map { trend.weeks[$0] }
    }

    @ViewBuilder
    private var readout: some View {
        if let week = selectedWeek, let i = trend.weeks.firstIndex(of: week) {
            let partial = trend.lastWeekPartial && i == trend.weeks.count - 1
            Text("\(week) 當週\(partial ? "（尚未結束）" : "")：" +
                 trend.series.map { "\($0.label) \($0.values[i])" }.joined(separator: " · "))
                .font(.weftMono)
                .foregroundStyle(WeftColor.textSecondary)
        } else {
            Text("在圖上左右滑動看每週數字，點下方個股只看那一條")
                .font(.weftMono)
                .foregroundStyle(WeftColor.textSecondary)
        }
    }

    private var legend: some View {
        VStack(spacing: 0) {
            ForEach(Array(trend.series.enumerated()), id: \.element.id) { index, series in
                Button {
                    focused = focused == series.id ? nil : series.id
                } label: {
                    HStack(spacing: WeftSpacing.sm) {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 6))
                            path.addLine(to: CGPoint(x: 28, y: 6))
                        }
                        .stroke(color(index), style: StrokeStyle(lineWidth: index == 0 ? 2.5 : 1.5, dash: dash(index)))
                        .frame(width: 28, height: 12)
                        Text(series.label).font(.subheadline.weight(.medium))
                        Spacer()
                        Text("最新一週 \(series.values.last ?? 0) 則")
                            .font(.weftMono)
                            .foregroundStyle(WeftColor.textSecondary)
                    }
                    .padding(.vertical, 8)
                    .opacity(focused == nil || focused == series.id ? 1 : 0.4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(focused == series.id ? .isSelected : [])
                .weftBottomHairline()
            }
        }
    }

    private var table: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(alignment: .trailing, horizontalSpacing: WeftSpacing.sm, verticalSpacing: 6) {
                GridRow {
                    Text("標的").gridColumnAlignment(.leading)
                    ForEach(trend.weeks, id: \.self) { Text($0) }
                }
                .foregroundStyle(WeftColor.textSecondary)
                Divider()
                ForEach(trend.series) { series in
                    GridRow {
                        Text(series.label)
                        ForEach(Array(series.values.enumerated()), id: \.offset) { Text("\($0.element)") }
                    }
                }
            }
            .font(.caption.monospacedDigit())
            .padding(.vertical, WeftSpacing.xs)
        }
    }
}

// MARK: - 討論 × 價格

/// The four cells stack vertically on a phone (side by side they'd be too narrow for
/// their tables). Wording is the site's.
struct HeatPriceBoardView: View {
    let board: HeatPriceBoard
    @State private var showsRules = false

    private static let rules = [
        "熱度升溫：本週提及至少 3 次且至少是上一個收錄週的 2 倍，或本週有 3 個以上節目提到且比上一週多。",
        "熱度退燒：上一週提及至少 3 次、本週不到一半，或連續 3 週以上的討論剛在上一週結束。",
        "相對強弱轉強：在美股半導體 20 檔中，20 日排名進步 3 名以上。",
        "價格仍強：63 日相對強弱百分位 0.67 以上（1.00 為最強）。",
        "共識形成中：熱度升溫，且相對強弱轉強或仍強。",
        "大家在講但價格沒反應：熱度升溫，但相對強弱沒有轉強也不強。",
        "討論慢半拍：熱度沒有升溫，但相對強弱轉強。",
        "討論已經安靜：熱度退燒，但價格仍強。",
        "收錄節目少於 2 個的週、或缺價格資料的個股，不分類。",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: WeftSpacing.sm) {
            Text([board.period, board.priceAsOf.map { "價格資料至 \($0)" }].compactMap { $0 }.joined(separator: "・"))
                .font(.weftMono.weight(.semibold))
                .foregroundStyle(WeftColor.textSecondary)
            Text("把美股半導體個股依「節目有沒有變得更常提」和「股價在同類裡強不強」分成四格。相對強弱是近 63 個交易日在半導體 20 檔裡的百分位，1.00 最強；排名變化是近 20 日名次進步（+）或退步（−）幾名。")
                .font(.footnote)

            ForEach(board.cells) { CellView(cell: $0) }

            if !board.unclassified.isEmpty {
                Text("本週無明顯組合：" + board.unclassified.joined(separator: "、"))
                    .font(.footnote)
                    .foregroundStyle(WeftColor.textSecondary)
            }
            Text("只涵蓋美股半導體 20 檔中、近 12 週被節目提到的個股。分類是固定規則套用在提及數與相對強弱上，不代表因果，也不是投資建議。")
                .font(.caption.weight(.medium))
                .foregroundStyle(WeftColor.textSecondary)

            DisclosureGroup("分類規則", isExpanded: $showsRules) {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Self.rules, id: \.self) { Text("・\($0)") }
                }
                .font(.footnote)
                .padding(.top, WeftSpacing.xs)
            }
            .font(.footnote.weight(.bold))
            .tint(WeftColor.textSecondary)
        }
    }

    private struct CellView: View {
        let cell: HeatPriceBoard.Cell

        var body: some View {
            VStack(alignment: .leading, spacing: WeftSpacing.xs) {
                Text(cell.title).font(.headline)
                Text(cell.subtitle).font(.caption.weight(.medium)).foregroundStyle(WeftColor.textSecondary)
                if cell.rows.isEmpty {
                    Text("本週沒有符合的個股").font(.footnote).foregroundStyle(WeftColor.textTertiary)
                } else {
                    Grid(alignment: .trailing, horizontalSpacing: WeftSpacing.sm, verticalSpacing: 6) {
                        GridRow {
                            Text("個股").gridColumnAlignment(.leading)
                            Text("提及（上週）")
                            Text("相對強弱")
                            Text("排名變化")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WeftColor.textSecondary)
                        ForEach(cell.rows) { row in
                            GridRow {
                                NavigationLink(value: Route.stock(row.ticker)) {
                                    Text(row.ticker).font(.subheadline.weight(.heavy)).underline()
                                }
                                .foregroundStyle(WeftColor.accent)
                                .buttonStyle(.plain)
                                Text(row.mentions)
                                Text(row.strength)
                                Text(row.rankChange)
                            }
                            .font(.subheadline.monospacedDigit())
                        }
                    }
                }
            }
            .padding(WeftSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .weftBorder(WeftColor.ruleFaint)
        }
    }
}
