import SwiftUI

/// Figma: 04 個股 · NVDA (+ S3 個股 · Error via AsyncContent)
struct StockDetailView: View {
    let ticker: String
    @Environment(\.repository) private var repository

    var body: some View {
        AsyncContent(loadingTitle: "正在載入個股資料…", load: {
            async let stock = repository.stock(ticker: ticker)
            async let detail = repository.stockDetail(ticker: ticker)
            return try await (stock, detail)
        }) { (stock: Stock, detail: StockDetail?) in
            StockContent(stock: stock, detail: detail)
        }
        .navigationTitle(ticker)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct StockContent: View {
    let stock: Stock
    let detail: StockDetail?
    @Environment(WatchlistStore.self) private var watchlist
    @State private var infoTopic: InfoTopic?

    enum InfoTopic: String, Identifiable {
        case priceState = "價格狀態"
        case temperature = "敘事溫度"
        case narrativeXPrice = "敘事 × 價格"
        case mentionReturn = "首次提及前 40 日報酬"
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WeftSpacing.md) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: WeftSpacing.xs) {
                        Text(stock.name).font(.title.weight(.bold))
                        TickerTag(text: stock.market.rawValue, style: .line)
                    }
                    if !stock.aliases.isEmpty {
                        Text("別名：" + (stock.aliases + [stock.ticker]).joined(separator: "、"))
                            .font(.footnote)
                            .foregroundStyle(WeftColor.textSecondary)
                    }
                }

                Button(watchlist.isTracked(stock.ticker) ? "★ 已追蹤" : "☆ 追蹤這檔個股") {
                    watchlist.toggleTracked(stock.ticker)
                }
                .buttonStyle(.weftSecondary)
                .sensoryFeedback(.selection, trigger: watchlist.isTracked(stock.ticker))

                if let detail {
                    DetailSections(detail: detail, infoTopic: $infoTopic)
                } else {
                    StateView(kind: .empty, title: "這檔的提及紀錄暫時讀不到",
                              message: "下拉可以重新整理。")
                }

                Disclaimer()
            }
            .weftScreen()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: URL(string: "https://next.weftmarkets.com/stocks/\(stock.ticker)")!) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(item: $infoTopic) { topic in
            NavigationStack {
                ScrollView {
                    Text(explanation(for: topic))
                        .font(.callout)
                        .padding(WeftSpacing.md)
                }
                .navigationTitle(topic.rawValue)
                .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.medium])
        }
    }

    // Copy from the stock page's method notes on next.weftmarkets.com.
    private func explanation(for topic: InfoTopic) -> String {
        switch topic {
        case .priceState:
            "固定規則依序檢查結構轉弱、偏熱、回檔整理，再判斷趨勢中；資料不足時不分類。這是價格觀察，並非操作建議。這套價格規則僅在台灣股票研究過，美股仍屬未驗證的研究觀察。"
        case .temperature:
            "依收錄節目的提及活躍程度與近期變化呈現，不代表市場共識。"
        case .narrativeXPrice:
            "敘事溫度搭配該市場截止前最後一個已收盤交易日的價格狀態；缺少對應資料時不分類。這是固定規則下的觀察，並非操作建議。"
        case .mentionReturn:
            "只使用資料截止時間之前已可取得的提及。比較首次提及錨點與其前 40 個交易日的原始報酬（含股息還原），非超額報酬。缺少所需價格時不計算。"
        }
    }
}

private struct DetailSections: View {
    let detail: StockDetail
    @Binding var infoTopic: StockContent.InfoTopic?

    var body: some View {
        InfoBanner(message: detail.dataUpdated)

        SectionHeader("各節目上次怎麼說")
        VStack(spacing: 0) {
            ForEach(detail.mentions) { KOLMentionRow(mention: $0) }
        }
        Text("價格為還原收盤參考，非節目當下成交價；只呈現說了什麼與之後價格，不評分對錯。")
            .font(.caption.weight(.medium))
            .foregroundStyle(WeftColor.textSecondary)

        SectionHeader("近 12 週摘要")
        HStack(spacing: WeftSpacing.sm) {
            StatTile(label: "notes", value: "\(detail.notes12w)", unit: "則")
            StatTile(label: "集數", value: "\(detail.episodes12w)", unit: "集")
            StatTile(label: "節目", value: "\(detail.shows12w)", unit: "個")
        }
        // Hidden when show-weekly couldn't be read (no stand-in numbers).
        if let weekly = detail.weeklyMentions {
            SectionHeader("節目提及 × 股價")
            WeeklyMentionsChart(data: weekly, ticker: detail.stock.ticker)
            Text("提及率 = 這個節目當週提到 \(detail.stock.ticker) 的重點 ÷ 節目當週全部重點 × 100。兩條軸單位不同，線與柱的高低不能直接當成價格與討論的關係強弱。")
                .font(.caption.weight(.medium))
                .foregroundStyle(WeftColor.textSecondary)
        }

        SectionHeader("進階指標")
        VStack(spacing: 0) {
            indicator(.priceState, detail.priceState)
            indicator(.temperature, detail.narrativeTemperature)
            indicator(.narrativeXPrice, detail.narrativeXPrice)
            indicator(.mentionReturn, detail.preMentionReturn)
        }
        Text("這套價格規則僅在台灣股票研究過，美股仍屬未驗證的研究觀察。點 ⓘ 開啟規則說明。")
            .font(.caption.weight(.medium))
            .foregroundStyle(WeftColor.textSecondary)

        if let market = detail.market {
            MarketContextCard(context: market)
        }

        if let firstPage = detail.firstNotesPage {
            StockNotesSection(ticker: detail.stock.ticker, firstPage: firstPage, shows: detail.noteShows)
        }
    }

    private func indicator(_ topic: StockContent.InfoTopic, _ value: String) -> some View {
        Button { infoTopic = topic } label: {
            ListRowLabel(title: topic.rawValue, systemImage: "info.circle", value: value)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { StockDetailView(ticker: "NVDA") }
        .environment(WatchlistStore())
}
