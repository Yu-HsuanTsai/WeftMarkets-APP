import SwiftUI

enum RepositoryError: LocalizedError {
    case notFound
    case unavailable
    /// Too many requests right now (ours or the shared Weft API budget).
    case rateLimited
    /// The data source has no such data (e.g. the API has no theme ranking).
    case notProvided(String)
    /// The app has no server address for this build.
    case notConfigured
    /// A pagination cursor is no longer valid (the data was republished); start over.
    case cursorExpired

    var errorDescription: String? {
        switch self {
        case .notFound: "找不到這筆資料。"
        case .unavailable: "讀不到的時候會直說讀不到，不會拿示意資料頂替。請檢查網路後再試一次。"
        case .rateLimited: "現在讀取的人比較多，請稍後再試一次。"
        case .notProvided(let what): "Weft 目前沒有提供\(what)。"
        case .notConfigured: "這個版本還沒有設定伺服器位址。"
        case .cursorExpired: "資料剛更新，請從頭重新載入。"
        }
    }
}

/// Data access boundary. Views only talk to this protocol, so the mock can be
/// swapped for the real Weft API without touching the UI.
protocol WeftRepository {
    func weeklySummary() async throws -> WeeklySummary
    func shows() async throws -> [Show]
    func latestEpisodes(showID: String?) async throws -> [Episode]
    /// `id` is an `Episode.ref` ("<source_type>:<source_id>").
    func episode(id: String) async throws -> Episode
    func radar() async throws -> RadarSnapshot
    func themes() async throws -> ThemeSnapshot
    func stock(ticker: String) async throws -> Stock
    func stockDetail(ticker: String) async throws -> StockDetail?
    func notes(mentioning tickers: Set<String>) async throws -> [(episode: Episode, note: Note)]
    /// 節目提及 × 股價: one show's episodes mentioning `ticker` in the week starting
    /// `weekStart` (a Monday, yyyy-MM-dd).
    func weekMentions(ticker: String, showKey: String, weekStart: String) async throws -> [StockEpisodeMention]
    /// 近 12 週重點, one page. `showKey` nil = all shows; `cursor` nil = first page.
    func stockNotes(ticker: String, showKey: String?, cursor: String?) async throws -> StockNotesPage
    /// Transcript snippets for one note. `episodeRef` is an `Episode.ref`.
    func evidence(episodeRef: String, noteID: String) async throws -> NoteEvidence
    /// 近 30 天提到的標的 for a show (`showID` is the show's slug).
    func showTickers(showID: String) async throws -> [ShowTickerRow]
    /// 近 12 週提及趨勢 · 累計 Top 5.
    func mentionTrend() async throws -> MentionTrend
    /// 討論 × 價格.
    func heatPrice() async throws -> HeatPriceBoard
    func search(_ query: String) async throws -> SearchResults
}

struct MockWeftRepository: WeftRepository {
    /// Simulated latency so loading states are visible while developing.
    var latency: Duration = .milliseconds(350)
    var failing = false

    private func simulate() async throws {
        try await Task.sleep(for: latency)
        if failing { throw RepositoryError.unavailable }
    }

    func weeklySummary() async throws -> WeeklySummary {
        try await simulate()
        return MockData.weekly
    }

    func shows() async throws -> [Show] {
        try await simulate()
        return MockData.shows
    }

    func latestEpisodes(showID: String?) async throws -> [Episode] {
        try await simulate()
        guard let showID else { return MockData.episodes }
        return MockData.episodes.filter { $0.showID == showID }
    }

    func episode(id: String) async throws -> Episode {
        try await simulate()
        guard let episode = MockData.episodes.first(where: { $0.ref == id || $0.id == id }) else { throw RepositoryError.notFound }
        return episode
    }

    func radar() async throws -> RadarSnapshot {
        try await simulate()
        return MockData.radar
    }

    func themes() async throws -> ThemeSnapshot {
        try await simulate()
        return MockData.themes
    }

    func stock(ticker: String) async throws -> Stock {
        try await simulate()
        return MockData.stock(ticker)
    }

    func stockDetail(ticker: String) async throws -> StockDetail? {
        try await simulate()
        return MockData.stockDetails[ticker]
    }

    func notes(mentioning tickers: Set<String>) async throws -> [(episode: Episode, note: Note)] {
        try await simulate()
        return MockData.episodes.flatMap { episode in
            episode.notes
                .filter { !Set($0.tickers).isDisjoint(with: tickers) }
                .map { (episode: episode, note: $0) }
        }
    }

    /// The mock snapshot has no weekly mentions (the chart is hidden), so nothing to list.
    func weekMentions(ticker: String, showKey: String, weekStart: String) async throws -> [StockEpisodeMention] {
        try await simulate()
        throw RepositoryError.notProvided("示意資料的單週提及")
    }

    // The mock snapshot has none of these; screens show "not provided" rather than
    // stand-in data.
    func stockNotes(ticker: String, showKey: String?, cursor: String?) async throws -> StockNotesPage {
        try await simulate()
        throw RepositoryError.notProvided("示意資料的近 12 週重點")
    }

    func evidence(episodeRef: String, noteID: String) async throws -> NoteEvidence {
        try await simulate()
        throw RepositoryError.notProvided("示意資料的逐字稿片段")
    }

    func showTickers(showID: String) async throws -> [ShowTickerRow] {
        try await simulate()
        throw RepositoryError.notProvided("示意資料的近 30 天標的")
    }

    func mentionTrend() async throws -> MentionTrend {
        try await simulate()
        throw RepositoryError.notProvided("示意資料的提及趨勢")
    }

    func heatPrice() async throws -> HeatPriceBoard {
        try await simulate()
        throw RepositoryError.notProvided("示意資料的討論 × 價格")
    }

    func search(_ query: String) async throws -> SearchResults {
        try await simulate()
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return SearchResults(stocks: [], notes: []) }

        let matched = MockData.stocks.values.filter { stock in
            ([stock.ticker, stock.name] + stock.aliases).contains { $0.lowercased().contains(q) }
        }
        let tickers = Set(matched.map(\.ticker))
        let radar = Dictionary(uniqueKeysWithValues: MockData.radar.top.map { ($0.stock.ticker, $0) })
        let stocks = matched
            .sorted { $0.ticker < $1.ticker }
            .map { radar[$0.ticker] ?? StockRanking(rank: 0, stock: $0, noteCount: nil, episodeCount: 0, showCount: nil) }

        let notes = MockData.episodes.flatMap { episode in
            episode.notes
                .filter { note in
                    !Set(note.tickers).isDisjoint(with: tickers)
                        || note.title.lowercased().contains(q)
                        || note.event.lowercased().contains(q)
                }
                .map { (episode: episode, note: $0) }
        }
        return SearchResults(stocks: stocks, notes: notes)
    }
}

private struct RepositoryKey: EnvironmentKey {
    static let defaultValue: any WeftRepository = MockWeftRepository()
}

extension EnvironmentValues {
    var repository: any WeftRepository {
        get { self[RepositoryKey.self] }
        set { self[RepositoryKey.self] = newValue }
    }
}

/// Loading / Empty / Error / Loaded, matching the State View variants in Figma.
enum LoadState<Value> {
    case loading
    case loaded(Value)
    case failed(Error)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }
}
