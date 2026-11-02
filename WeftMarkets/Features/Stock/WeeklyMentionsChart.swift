import Charts
import SwiftUI

/// 節目提及 × 股價（近 12 週）, following weftmarkets.com: pick a show, bars are its
/// weekly mention rate (left axis), the line is the weekly close (right axis).
/// Drag across the chart to read a week; the last week touched lists that show's
/// episodes mentioning the stock (`show-weekly/notes`).
struct WeeklyMentionsChart: View {
    let data: WeeklyMentions
    let ticker: String
    @State private var showKey: String?
    /// Follows the finger while scrubbing; nil once it lifts.
    @State private var scrubLabel: String?
    /// The last week touched. Stays after the finger lifts and opens that week's list.
    @State private var pickedLabel: String?

    private var readoutLabel: String? { scrubLabel ?? pickedLabel }

    private var show: WeeklyMentions.Show? {
        let key = showKey ?? data.defaultShowKey
        return data.shows.first { $0.key == key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: WeftSpacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: WeftSpacing.xs) {
                    ForEach(data.shows) { item in
                        FilterChip(label: item.name, count: "近 12 週 \(item.totalMentions) 則",
                                   isSelected: item.key == show?.key) {
                            showKey = item.key
                            pickedLabel = nil
                        }
                    }
                }
            }

            if let show {
                ForEach(data.prices) { series in
                    VStack(alignment: .leading, spacing: WeftSpacing.xs) {
                        if let heading = series.heading {
                            Text(heading).font(.subheadline.weight(.semibold))
                        }
                        legend(series)
                        RateCloseChart(weeks: data.weeks, show: show, series: series,
                                       selection: $scrubLabel, highlighted: readoutLabel)
                        readout(show: show, series: series)
                    }
                }

                if let label = pickedLabel, let i = data.weeks.firstIndex(where: { $0.label == label }) {
                    WeekMentionsList(ticker: ticker, show: show, week: data.weeks[i],
                                     mentionCount: show.weeks[i]?.mentionNotes)
                }
            }
        }
        .onChange(of: scrubLabel) { _, label in
            if let label { pickedLabel = label }
        }
    }

    private func legend(_ series: WeeklyMentions.PriceSeries) -> some View {
        HStack(spacing: WeftSpacing.md) {
            Label {
                Text("收盤價\(series.currency.map { "（\($0)）" } ?? "") · 右軸")
            } icon: {
                Capsule().fill(WeftColor.textPrimary).frame(width: 12, height: 2)
            }
            Label {
                Text("提及率 · 每 100 則重點 · 左軸")
            } icon: {
                Rectangle().fill(WeftColor.accent).frame(width: 8, height: 8)
            }
        }
        .labelStyle(LegendLabelStyle())
        .font(.caption.weight(.medium))
        .foregroundStyle(WeftColor.textSecondary)
    }

    @ViewBuilder
    private func readout(show: WeeklyMentions.Show, series: WeeklyMentions.PriceSeries) -> some View {
        Group {
            if let label = readoutLabel, let i = data.weeks.firstIndex(where: { $0.label == label }) {
                let week = data.weeks[i]
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(week.label) 當週\(week.partial ? "（尚未結束）" : "")")
                        .font(.weftMono)
                        .foregroundStyle(WeftColor.textSecondary)
                    Text(closeLine(series, at: i, week: week))
                    Text(rateLine(show.weeks[i]))
                    ForEach(detailLines(show.weeks[i]), id: \.self) {
                        Text($0).font(.weftMono).foregroundStyle(WeftColor.textSecondary)
                    }
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("在圖上左右滑動看每週數字，放開後列出那週的提及")
                    .font(.weftMono)
                    .foregroundStyle(WeftColor.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, WeftSpacing.sm)
        .padding(.vertical, 10)
        .weftBorder(WeftColor.ruleFaint)
    }

    private func closeLine(_ series: WeeklyMentions.PriceSeries, at i: Int, week: WeeklyMentions.Week) -> String {
        let code = series.symbol.replacingOccurrences(of: ".TW", with: "")
        guard let close = series.closes[i] else { return "\(code) 收盤：無資料" }
        let date = series.tradeDates[i].map(APIWeftRepository.weekLabel) ?? week.label
        return "\(code) 收盤 \(series.currency.map { "\($0) " } ?? "")\(close.formatted(.number.precision(.fractionLength(2))))（\(date)）"
    }

    private func rateLine(_ week: WeeklyMentions.ShowWeek?) -> String {
        guard let week else { return "提及率：這週的資料暫時讀不到" }
        guard let rate = week.rate else { return "提及率：這週沒有節目內容" }
        return "提及率 \(rate.formatted(.number.precision(.fractionLength(0...2)))) / 每 100 則重點"
    }

    private func detailLines(_ week: WeeklyMentions.ShowWeek?) -> [String] {
        guard let week else { return [] }
        let output = if let notes = week.showNotes, let episodes = week.showEpisodes {
            "節目當週 \(episodes) 集 · \(notes) 則重點"
        } else {
            "節目當週產量暫時讀不到"
        }
        return ["提及 \(week.mentionNotes) 則 · \(week.mentionEpisodes) 集提到", output]
    }
}

/// 「10/26 當週 · 財女珍妮 · 6 則提及」 and the episodes behind that bar.
private struct WeekMentionsList: View {
    let ticker: String
    let show: WeeklyMentions.Show
    let week: WeeklyMentions.Week
    let mentionCount: Int?
    @Environment(\.repository) private var repository

    private var noMentions: some View {
        Text("這個節目這週沒有提到 \(ticker.replacingOccurrences(of: ".TW", with: ""))。")
            .font(.footnote)
            .foregroundStyle(WeftColor.textSecondary)
            .padding(.vertical, WeftSpacing.sm)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(week.label) 當週 · \(show.name)\(mentionCount.map { " · \($0) 則提及" } ?? "")")
                .font(.headline)
                .padding(.top, WeftSpacing.xs)
            // show-weekly already says 0 mentions; no need to ask again.
            if mentionCount == 0 {
                noMentions
            } else {
                AsyncContent(load: load) { items in
                    if items.isEmpty {
                        noMentions
                    } else {
                        ForEach(items) { StockMentionGroup(item: $0) }
                    }
                } placeholder: {
                    SkeletonRow()
                }
                .id("\(show.key)|\(week.start)")
            }
        }
    }

    /// Waits briefly first: scrubbing across bars changes the week several times a
    /// second, and only the week the finger stops on should hit the API.
    private func load() async throws -> [StockEpisodeMention] {
        try await Task.sleep(for: .milliseconds(300))
        return try await repository.weekMentions(ticker: ticker, showKey: show.key, weekStart: week.start)
    }
}

private struct LegendLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) { configuration.icon; configuration.title }
    }
}

/// Swift Charts has one y scale, so closes are mapped onto the rate scale and the
/// trailing axis labels convert back to prices.
private struct RateCloseChart: View {
    let weeks: [WeeklyMentions.Week]
    let show: WeeklyMentions.Show
    let series: WeeklyMentions.PriceSeries
    @Binding var selection: String?
    let highlighted: String?

    private var rateTop: Double {
        Self.niceMax(max(show.weeks.compactMap { $0?.rate }.max() ?? 0, 1))
    }

    /// Same padding as weftmarkets.com: 10% of the range, at least 2% of the high.
    private var priceDomain: (low: Double, high: Double) {
        let closes = series.closes.compactMap { $0 }
        guard let low = closes.min(), let high = closes.max() else { return (0, 1) }
        let pad = max((high - low) * 0.1, high * 0.02, 0.01)
        return (max(0, low - pad), high + pad)
    }

    private func scaled(_ close: Double) -> Double {
        let (low, high) = priceDomain
        return (close - low) / (high - low) * rateTop
    }

    private func price(atScaled value: Double) -> Double {
        let (low, high) = priceDomain
        return low + value / rateTop * (high - low)
    }

    /// Breaks the line where a week has no close instead of bridging the gap.
    private var lineSegments: [Int] {
        var segment = 0
        return series.closes.map { close in
            if close == nil { segment += 1 }
            return segment
        }
    }

    /// Every third week plus the last, so 12 labels don't collide at phone width.
    private var axisLabels: [String] {
        let labels = weeks.map(\.label)
        var picked = Array(stride(from: 0, to: labels.count, by: 3))
        if let last = labels.indices.last, picked.last != last {
            if let previous = picked.last, last - previous < 2 { picked.removeLast() }
            picked.append(last)
        }
        return picked.map { labels[$0] }
    }

    var body: some View {
        let segments = lineSegments
        let axisTicks = [0, rateTop / 2, rateTop]
        Chart {
            ForEach(Array(weeks.enumerated()), id: \.offset) { i, week in
                if let rate = show.weeks[i]?.rate {
                    BarMark(x: .value("週", week.label), y: .value("提及率", rate), width: .ratio(0.6))
                        .foregroundStyle(WeftColor.accent.opacity(barOpacity(week)))
                }
                if let close = series.closes[i] {
                    LineMark(x: .value("週", week.label), y: .value("收盤價", scaled(close)),
                             series: .value("段", segments[i]))
                        .foregroundStyle(WeftColor.textPrimary)
                        .lineStyle(StrokeStyle(lineWidth: 1.5))
                    PointMark(x: .value("週", week.label), y: .value("收盤價", scaled(close)))
                        .foregroundStyle(WeftColor.textPrimary)
                        .symbolSize(highlighted == week.label ? 40 : 12)
                }
            }
            if let highlighted {
                RuleMark(x: .value("週", highlighted))
                    .foregroundStyle(WeftColor.ruleFaint)
            }
        }
        .chartXScale(domain: weeks.map(\.label))
        .chartYScale(domain: 0...rateTop)
        .chartXAxis {
            // Categorical axes ignore `values:`, so unwanted labels are skipped here.
            let shown = Set(axisLabels)
            AxisMarks { value in
                if let label = value.as(String.self), shown.contains(label) {
                    AxisValueLabel().font(.caption2.monospacedDigit())
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: axisTicks) { value in
                AxisGridLine().foregroundStyle(WeftColor.ruleFaint)
                AxisValueLabel {
                    if let rate = value.as(Double.self) {
                        Text(rate.formatted(.number.precision(.fractionLength(0...1))))
                    }
                }
            }
            AxisMarks(position: .trailing, values: axisTicks) { value in
                AxisValueLabel {
                    if let scaled = value.as(Double.self) {
                        Text(price(atScaled: scaled).formatted(.number.precision(.fractionLength(0...1))))
                    }
                }
            }
        }
        .chartXSelection(value: $selection)
        .frame(height: 200)
        .accessibilityLabel("\(series.symbol) 近 \(weeks.count) 週收盤價與\(show.name)的提及率")
    }

    private func barOpacity(_ week: WeeklyMentions.Week) -> Double {
        let base = week.partial ? 0.6 : 1
        guard let highlighted else { return base }
        return highlighted == week.label ? base : base * 0.3
    }

    /// Rounds the axis top up to 4, or 1/2/5 × 10ⁿ (as on weftmarkets.com).
    static func niceMax(_ value: Double) -> Double {
        if value <= 4 { return 4 }
        let magnitude = pow(10, floor(log10(value)))
        for step in [1.0, 2, 5, 10] where value <= step * magnitude { return step * magnitude }
        return 10 * magnitude
    }
}
