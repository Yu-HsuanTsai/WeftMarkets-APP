import Foundation

enum Platform: String, Codable, Hashable {
    case spotify, youtube

    var label: String {
        switch self {
        case .spotify: "Podcast"
        case .youtube: "YouTube"
        }
    }
}

enum Market: String, Codable, Hashable {
    case us = "US"
    case tw = "TW"
}

struct Show: Identifiable, Hashable {
    let id: String              // web slug, e.g. "gooaye"
    let name: String
    let platform: Platform?     // nil when the source site does not state it
    let episodesLast7Days: Int
}

/// One extracted note (重點): 事件 / 觀點 / 風險, anchored to a time range in the source.
struct Note: Identifiable, Hashable {
    let id: String
    let index: Int
    let title: String
    let startMinute: Int
    let endMinute: Int
    let event: String
    let view: String
    let risk: String?
    let tickers: [String]

    var timeLabel: String { "\(startMinute)–\(endMinute) 分" }
}

struct Episode: Identifiable, Hashable {
    let id: String              // platform source id
    let showID: String
    let showName: String
    let platform: Platform
    let date: String            // yyyy-MM-dd (Asia/Taipei)
    let title: String
    let summary: String
    let noteCount: Int
    let tickerCount: Int
    let estimatedTokens: Int
    let tickers: [String]
    let notes: [Note]           // may hold only the first few notes in mock data

    var sourceURL: URL? { sourceURL(atMinute: nil) }

    func sourceURL(atMinute minute: Int?) -> URL? {
        let seconds = (minute ?? 0) * 60
        switch platform {
        case .spotify:
            return URL(string: "https://open.spotify.com/episode/\(id)" + (minute == nil ? "" : "?t=\(seconds)"))
        case .youtube:
            return URL(string: "https://www.youtube.com/watch?v=\(id)" + (minute == nil ? "" : "&t=\(seconds)"))
        }
    }
}

struct Stock: Identifiable, Hashable {
    var id: String { ticker }
    let ticker: String
    let name: String
    let market: Market
    let aliases: [String]
}

/// A row in a ranking (雷達 Top 15, 最多集數提到的個股).
struct StockRanking: Identifiable, Hashable {
    var id: String { stock.ticker }
    let rank: Int
    let stock: Stock
    let noteCount: Int?
    let episodeCount: Int
    let showCount: Int?
}

/// 各節目上次怎麼說 — last mention per show with reference closes.
struct KOLMention: Identifiable, Hashable {
    var id: String { showName + date }
    let showName: String
    let date: String
    let topic: String
    let priceThen: String
    let priceNow: String
    let change: String
}

struct StockDetail: Hashable {
    let stock: Stock
    let dataUpdated: String
    let mentions: [KOLMention]
    let notes12w: Int
    let episodes12w: Int
    let shows12w: Int
    let priceState: String
    let narrativeTemperature: String
    let narrativeXPrice: String
    let preMentionReturn: String
}

struct NarrativeTheme: Identifiable, Hashable {
    var id: String { name }
    let rank: Int
    let name: String
    let mentionCount: Int?
    let shareOfVoice: Double
    let representativeTickers: [String]
    let wowNote: String?
}

struct MarketContext: Identifiable, Hashable {
    enum Status: Hashable { case ready, insufficient }
    var id: String { market }
    let market: String
    let status: Status
    let line1: String
    let line2: String
}

struct WeeklySummary: Hashable {
    let dateLabel: String
    let week: String
    let period: String
    let episodes: Int
    let notes: Int
    let tickers: Int
    let showsWithNewEpisodes: Int
    let showsTotal: Int
    let topByEpisodes: [StockRanking]
    let latestEpisode: Episode
    let markets: [MarketContext]
}

struct RadarSnapshot: Hashable {
    let period: String
    let leader: StockRanking
    let top: [StockRanking]
    let totalRanked: Int
}

struct ThemeSnapshot: Hashable {
    let weekStart: String
    let analyzedEpisodes: Int
    let publishedEpisodes: Int
    let coverageSufficient: Bool
    let themes: [NarrativeTheme]
}

struct SearchResults: Hashable {
    let stocks: [StockRanking]
    let notes: [(episode: Episode, note: Note)]

    static func == (lhs: SearchResults, rhs: SearchResults) -> Bool {
        lhs.stocks == rhs.stocks && lhs.notes.map(\.note.id) == rhs.notes.map(\.note.id)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(stocks)
        hasher.combine(notes.map(\.note.id))
    }

    var isEmpty: Bool { stocks.isEmpty && notes.isEmpty }
}

/// Navigation targets shared by every tab's NavigationStack.
enum Route: Hashable {
    case episode(String)
    case stock(String)
    case show(String)
}
