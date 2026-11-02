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

    /// Stable episode identity across the app and the web: "<source_type>:<source_id>"
    /// (also the format of read ids in the web's ResearchStateV1).
    var ref: String { Self.ref(platform: platform, sourceID: id) }

    static func ref(platform: Platform, sourceID: String) -> String { "\(platform.rawValue):\(sourceID)" }

    /// Splits a ref back into its parts; nil for anything else.
    static func parseRef(_ ref: String) -> (platform: Platform, sourceID: String)? {
        let parts = ref.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2, let platform = Platform(rawValue: parts[0]), !parts[1].isEmpty else { return nil }
        return (platform, parts[1])
    }

    /// Published within the last 7 Taipei days (today included), like the site's 本週 badge.
    var isWithinLast7Days: Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Taipei")!
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let start = calendar.date(byAdding: .day, value: -6, to: .now) else { return false }
        return date >= formatter.string(from: start)
    }

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
    /// Market background for the stock's market; nil when it couldn't be read.
    var market: MarketContext? = nil
    /// 節目提及 × 股價（近 12 週）; nil when it couldn't be read.
    var weeklyMentions: WeeklyMentions? = nil
    /// 近 12 週重點: the first page (all shows), and the shows to filter by.
    var firstNotesPage: StockNotesPage? = nil
    var noteShows: [NoteShowFilter] = []
}

struct NoteShowFilter: Identifiable, Hashable {
    var id: String { key }
    let key: String
    let name: String
    let notes: Int
}

/// 節目提及 × 股價: per show, the weekly mention rate against weekly closes
/// (`tickers/{t}/show-weekly`). Arrays are aligned with `weeks`.
struct WeeklyMentions: Hashable {
    struct Week: Hashable {
        let start: String      // Monday, yyyy-MM-dd (Taipei)
        let label: String      // "08/10", as on weftmarkets.com
        let partial: Bool      // the week hasn't ended yet
    }

    /// One listing's closes. Dual-listed stocks (e.g. 台股 + 美股 ADR) get one chart each.
    struct PriceSeries: Hashable, Identifiable {
        var id: String { symbol }
        let symbol: String
        let heading: String?   // only for dual listings, e.g. "美股 ADR · TSM · USD"
        let currency: String?
        let closes: [Double?]
        let tradeDates: [String?]
    }

    struct ShowWeek: Hashable {
        let mentionNotes: Int
        let mentionEpisodes: Int
        let showNotes: Int?    // nil: the show's output that week couldn't be read
        let showEpisodes: Int?
        let rate: Double?      // per 100 notes; nil when the show had no notes that week
    }

    struct Show: Hashable, Identifiable {
        var id: String { key }
        let key: String
        let name: String
        let weeks: [ShowWeek?]
        var totalMentions: Int { weeks.reduce(0) { $0 + ($1?.mentionNotes ?? 0) } }
    }

    let weeks: [Week]
    let prices: [PriceSeries]
    let shows: [Show]

    /// The site opens on the show with the most mentions over the 12 weeks.
    var defaultShowKey: String? {
        shows.reduce(nil as Show?) { best, show in
            show.totalMentions > (best?.totalMentions ?? -1) ? show : best
        }?.key
    }
}

/// One episode mentioning a stock (`tickers/{t}/notes`, `show-weekly/notes`): the notes
/// that mention it and the close on the publish date.
struct StockEpisodeMention: Identifiable, Hashable {
    var id: String { episode.ref }
    let episode: Episode
    let notes: [Note]
    /// e.g. "參考收盤價：213.66 USD · 10/29 當日收盤"; one line per listing.
    let referencePrices: [String]
}

/// A page of 近 12 週重點 on the stock page.
struct StockNotesPage: Hashable {
    let items: [StockEpisodeMention]
    let nextCursor: String?
    let notes: Int?
    let episodes: Int?
}

/// Transcript snippets behind a note (`notes/{id}/evidence`).
struct NoteEvidence: Hashable {
    struct Segment: Hashable, Identifiable {
        let id: Int
        let time: String          // "00:12:46"
        let text: String
        let hits: [Range<Int>]    // UTF-16 offsets of matched words in `text`
    }
    let segments: [Segment]
    /// Why there are no segments: "no_timestamp" / "no_transcript".
    let reason: String?
}

/// 近 30 天提到的標的 on a show page (`publishers/{key}/tickers`).
struct ShowTickerRow: Identifiable, Hashable {
    var id: String { stock.ticker }
    let stock: Stock
    let lastMentionDate: String   // Taipei yyyy-MM-dd
    let subject: String
    let minuteLabel: String?      // "24–25 分"
    let changePct: Double?
    let priceLine: String         // "當時 10-27 342.33 → 最新 10-30 326.08 USD"
    let daysSinceMention: Int?    // 距收錄日
    /// Episode of the last mention, as an `Episode.ref`.
    let episodeRef: String?
}

/// 近 12 週提及趨勢 · 累計 Top 5 (`gold/ticker-weekly`). `values` are aligned with
/// `weeks`; a week with no row counts as 0, as on weftmarkets.com.
struct MentionTrend: Hashable {
    struct Series: Identifiable, Hashable {
        var id: String { ticker }
        let ticker: String
        let label: String      // 台股 show their name (台積電), others the ticker
        let values: [Int]
    }
    let weeks: [String]        // "08/10"
    let series: [Series]
    /// The last week hasn't ended yet.
    let lastWeekPartial: Bool
}

/// 討論 × 價格 (`radar/heat-price`): US semiconductors sorted into four fixed-rule cells
/// for the last complete week.
struct HeatPriceBoard: Hashable {
    struct Row: Identifiable, Hashable {
        var id: String { ticker }
        let ticker: String
        let mentions: String   // "3（12）" = this week (previous week)
        let strength: String   // 63-day relative-strength percentile, "0.84"
        let rankChange: String // 20-day rank change, "+6"
    }
    struct Cell: Identifiable, Hashable {
        let id: String         // consensus_forming / talk_without_price / ...
        let title: String
        let subtitle: String
        let rows: [Row]
    }
    let period: String         // "10-19 – 10-25"
    let priceAsOf: String?
    let cells: [Cell]
    /// 本週無明顯組合 (quadrant "none").
    let unclassified: [String]
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
    let latestEpisode: Episode?     // nil when the week has no episodes or it couldn't be read
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
    case episode(String)        // Episode.ref
    case stock(String)
    case show(String)
}
