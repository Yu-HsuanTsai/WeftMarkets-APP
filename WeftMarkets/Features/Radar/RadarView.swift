import SwiftUI

/// Figma: 05 雷達 · 個股 / 06 雷達 · 敘事主題
struct RadarView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case stocks = "個股"
        case themes = "敘事主題"
        var id: Self { self }
    }

    @State private var mode: Mode = .stocks

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WeftSpacing.md) {
                LargeTitleHeader(title: "雷達", kicker: mode == .stocks ? "STOCK RADAR · ROLLING 7 DAYS" : "RADAR · 敘事主題")
                Picker("雷達", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                switch mode {
                case .stocks: StockRadarSection()
                case .themes: ThemeRadarSection()
                }
            }
            .weftScreen()
        }
        .navigationTitle("雷達")
    }
}

private struct StockRadarSection: View {
    @Environment(\.repository) private var repository
    @State private var showsAll = false

    var body: some View {
        AsyncContent(loadingTitle: "正在載入注意力資料…", load: { try await repository.radar() }) { radar in
            VStack(alignment: .leading, spacing: WeftSpacing.md) {
                InfoBanner(message: "期間 \(radar.period) · Top \(radar.totalRanked) · 涵蓋 4 個財經節目")

                NavigationLink(value: Route.stock(radar.leader.stock.ticker)) {
                    LeadCard(ranking: radar.leader)
                }
                .buttonStyle(.plain)

                SectionHeader("近 7 天 Top \(radar.totalRanked)")
                VStack(spacing: 0) {
                    ForEach(radar.top) { ranking in
                        NavigationLink(value: Route.stock(ranking.stock.ticker)) {
                            StockRow(ranking: ranking,
                                     metric: "\(ranking.noteCount ?? 0) 則",
                                     detail: ranking.showCount.map { "\(ranking.episodeCount) 集 · \($0) 節目" } ?? "\(ranking.episodeCount) 集")
                        }
                        .buttonStyle(.plain)
                    }
                }
                if radar.top.count < radar.totalRanked {
                    Button("顯示全部 \(radar.totalRanked) 檔") { showsAll = true }
                        .buttonStyle(.weftSecondary)
                        .alert("範例資料只收錄前 \(radar.top.count) 名", isPresented: $showsAll) {
                            Button("好") {}
                        } message: {
                            Text("完整 Top \(radar.totalRanked) 將於串接 API 後顯示。")
                        }
                }
                Text("依不重複 notes 數排序 · 同分依集數、節目數、最近提及。數字反映收錄內容的討論熱度，不是投資建議或買進排名。")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WeftColor.textSecondary)

                // Each chart loads on its own so the ranking above never waits for them.
                SectionHeader("討論 × 價格")
                Text("上一個完整週 · 整週收盤價齊了才算，所以不是近 7 天")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WeftColor.textSecondary)
                AsyncContent(load: { try await repository.heatPrice() }) { HeatPriceBoardView(board: $0) } placeholder: {
                    SkeletonRow()
                }

                SectionHeader("近 12 週提及趨勢 · 累計 Top 5")
                AsyncContent(load: { try await repository.mentionTrend() }) { trend in
                    if trend.series.isEmpty {
                        StateView(kind: .empty, title: "這段期間沒有提及資料")
                    } else {
                        MentionTrendChart(trend: trend)
                    }
                } placeholder: {
                    SkeletonRow()
                }
                Disclaimer()
            }
        }
    }
}

private struct LeadCard: View {
    let ranking: StockRanking

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("頭條 · #1 近 7 天討論最多")
                .font(.weftKicker)
                .foregroundStyle(WeftColor.textInverse)
            Text("\(ranking.stock.name) · \(ranking.stock.ticker)")
                .font(.title2.weight(.bold))
                .foregroundStyle(WeftColor.textOnAccent)
            HStack(spacing: 20) {
                stat("\(ranking.noteCount ?? 0)", "則重點")
                stat("\(ranking.episodeCount)", "集")
                if let shows = ranking.showCount { stat("\(shows)", "個節目") }
            }
            Text("數字是被整理成重點的次數，不是買賣訊號。")
                .font(.caption.weight(.medium))
                .foregroundStyle(WeftColor.textInverse)
        }
        .padding(WeftSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WeftColor.bgInverse)
    }

    private func stat(_ value: String, _ unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value).font(.weftNumericLarge).foregroundStyle(WeftColor.textOnAccent)
            Text(unit).font(.footnote).foregroundStyle(WeftColor.textInverse)
        }
    }
}

private struct ThemeRadarSection: View {
    enum Range: Int, CaseIterable, Identifiable {
        case w4 = 4, w8 = 8, w12 = 12, w26 = 26
        var id: Int { rawValue }
    }

    @Environment(\.repository) private var repository
    @State private var range: Range = .w8

    var body: some View {
        Picker("期間", selection: $range) {
            ForEach(Range.allCases) { Text("\($0.rawValue) 週").tag($0) }
        }
        .pickerStyle(.segmented)

        AsyncContent(loadingTitle: "正在載入主題資料…", load: { try await repository.themes() }) { snapshot in
            VStack(alignment: .leading, spacing: WeftSpacing.md) {
                InfoBanner(message: "最新一週：\(snapshot.weekStart) 起（ISO 週）· 資料為最近一次更新 2026-10-10")
                if !snapshot.coverageSufficient {
                    InfoBanner(message: "資料涵蓋不完整（已分析 \(snapshot.analyzedEpisodes) / \(snapshot.publishedEpisodes) 集）。保留已觀察到的數量，暫不判讀變化。",
                               kind: .warning)
                }
                SectionHeader("本週主題排行")
                VStack(spacing: 0) {
                    ForEach(snapshot.themes) { ThemeRow(theme: $0) }
                }
                Text("聲量佔比 = 該主題佔本週所有主題提及的比例。")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WeftColor.textSecondary)
                SectionHeader("近 \(range.rawValue) 週主題熱度 · Top 5")
                ChartPlaceholder(title: "每週提及次數",
                                 note: "Swift Charts：ai / 半導體 / 美股 / 台股 / 記憶體。資料由 API 提供。",
                                 minHeight: 130)
                Disclaimer(text: "數字反映的是內容圈的討論熱度，非投資建議。「—」表示對照期沒有被提及，比值會誤導所以不顯示。")
            }
        }
    }
}

#Preview {
    NavigationStack { WeftTabRoot { RadarView() }.weftDestinations() }
        .environment(WatchlistStore())
}
