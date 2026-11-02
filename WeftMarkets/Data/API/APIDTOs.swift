import Foundation

// Response shapes from weft-bff, which passes Narrative API bodies through.
// Only fields the app uses are declared; JSON keys are snake_case and decoded
// with `.convertFromSnakeCase`. Fields the docs mark optional, or that were
// missing in real responses, are optional here.

enum DTO {
    // MARK: Episodes

    struct Publisher: Decodable {
        let key: String
        let name: String
    }

    struct EpisodeSummary: Decodable {
        let sourceType: String
        let sourceId: String
        let publisher: Publisher
        let publishedAt: String
        let publishDate: String?
        let title: String
        let shortSummary: String?
        let noteCount: Int
        let tickers: [String]?
    }

    struct Feed: Decodable {
        let items: [EpisodeSummary]
        let nextCursor: String?
        let date: String?
        let weekStart: String?
        let weekEnd: String?
        let throughDate: String?
    }

    struct EpisodeNote: Decodable {
        let noteId: String
        let noteIndex: Int?
        let startMin: Int?
        let endMin: Int?
        let subject: String?
        let fact: String?
        let hostView: String?
        let risk: String?
        let tickers: [String]?
    }

    struct EpisodeDetail: Decodable {
        let sourceType: String
        let sourceId: String
        let publisher: Publisher
        let publishedAt: String
        let publishDate: String?
        let title: String
        let noteCount: Int
        let notes: [EpisodeNote]
    }

    // MARK: Screens

    struct Home: Decodable {
        let week: APISection<Feed>
        let status: APISection<Status>
        let topTickers: APISection<TopTickers>
        let marketTw: APISection<MarketContext>
        let marketUs: APISection<MarketContext>
    }

    struct Status: Decodable {
        let publishersSupported: Int?
        let throughDate: String?
    }

    struct Radar: Decodable {
        let topTickers: APISection<TopTickers>
    }

    struct TopTickers: Decodable {
        struct Item: Decodable {
            let rank: Int
            let ticker: String
            let market: String?
            let displayName: String?
            let noteCount: Int?
            let episodeCount: Int?
            let publisherCount: Int?
        }
        struct Window: Decodable {
            let from: String?
            let to: String?
        }
        let items: [Item]
        let window: Window?
    }

    struct Shows: Decodable {
        struct Entry: Decodable {
            let publisher: CatalogPublisher
            let latest: APISection<Feed>
        }
        let shows: [Entry]
    }

    /// The BFF's hard-coded show list (conventions.md).
    struct CatalogPublisher: Decodable {
        let key: String
        let name: String
        let source: String
        let slug: String
    }

    struct ShowPage: Decodable {
        let publisher: CatalogPublisher
        let latest: APISection<Feed>
    }

    // MARK: Market context (TrackedMarketContextResponse)

    struct MarketContext: Decodable {
        struct Context: Decodable {
            struct Benchmark: Decodable {
                let trendState: String?
                let regimeLabel: String?
            }
            struct Regime: Decodable {
                let label: String?
            }
            let benchmark: [String: Benchmark]?
            let regime: Regime?
        }
        let status: String
        let marketId: String
        let priceSession: String?
        let expectedPriceSession: String?
        let context: Context?
        let reasonCodes: [String]?
    }

    // MARK: Stock page

    struct Stock: Decodable {
        let narrativeState: APISection<NarrativeState>
        let priceContext: APISection<PriceContext>
        let market: APISection<MarketContext>
        let showWeekly: APISection<ShowWeekly>
        let notes: APISection<TickerNotes>
    }

    /// `tickers/{t}/show-weekly` (schema pending; shaped after the real response).
    struct ShowWeekly: Decodable {
        struct Week: Decodable {
            let weekStart: String
            let tradeDate: String?
            let close: Double?
            let partial: Bool?
        }
        struct Listing: Decodable {
            let symbol: String
            let market: String?
            let currency: String?
            let weeks: [Week]
        }
        struct ShowWeek: Decodable {
            let weekStart: String
            let showNotes: Int?
            let showEpisodes: Int?
            let mentionNotes: Int
            let mentionEpisodes: Int
            let mentionRate: Double?
        }
        struct Show: Decodable {
            let publisherKey: String
            let weeks: [ShowWeek]
        }
        let weeks: [Week]
        let shows: [Show]
        let listings: [Listing]?
    }

    struct NarrativeState: Decodable {
        let narrativeTemperature: String?
    }

    struct PriceContext: Decodable {
        struct Block<T: Decodable>: Decodable {
            let status: String?
            let data: T?
        }
        struct PriceState: Decodable {
            let priceState: String?
        }
        struct Narrative: Decodable {
            let narrativeTemperature: String?
        }
        struct MentionReturns: Decodable {
            let retBeforeFirstMention: Double?
        }
        struct HeatPrice: Decodable {
            let narrativeTemperature: String?
            let priceState: String?
        }
        let priceState: Block<PriceState>?
        let narrative: Block<Narrative>?
        let mentionReturns: Block<MentionReturns>?
        let heatPrice: Block<HeatPrice>?
    }

    struct TickerNotes: Decodable {
        struct Symbol: Decodable {
            let symbol: String
            let market: String?
        }
        struct Identity: Decodable {
            let displayName: String?
            let aliases: [String]?
        }
        struct Totals: Decodable {
            let notes: Int?
            let episodes: Int?
            let publishers: Int?
        }
        struct Price: Decodable {
            let tradeDate: String?
            let adjustedClose: Double?
            let currency: String?
        }
        struct LastMention: Decodable {
            struct LastNote: Decodable {
                let subject: String?
            }
            let publishedAt: String
            let title: String?
            let lastNote: LastNote?
            let referencePrice: Price?
            let latestClose: Price?
            let changeSincePct: Double?
        }
        struct PublisherMention: Decodable {
            let publisherKey: String?
            let publisherName: String
            let notes: Int?
            let episodes: Int?
            let lastMention: LastMention?
        }
        let ticker: Symbol
        let identity: Identity?
        let totals: Totals?
        let publishers: [PublisherMention]?
        let throughDate: String?
        let items: [TickerNoteItem]?
        let nextCursor: String?
    }

    /// One episode in `tickers/{t}/notes` and `tickers/{t}/show-weekly/notes`
    /// (schema pending; shaped after the real responses).
    struct TickerNoteItem: Decodable {
        struct Price: Decodable {
            let tradeDate: String?
            let adjustedClose: Double?
            let currency: String?
            let basis: String?
        }
        struct ListingPrice: Decodable {
            let symbol: String
            let currency: String?
            let referencePrice: Price?
        }
        let sourceType: String
        let sourceId: String
        let publisherKey: String?
        let publisherName: String?
        let episodeTitle: String?
        let publishedAt: String
        let notes: [EpisodeNote]
        let referencePrice: Price?
        let referencePrices: [ListingPrice]?
    }

    struct ShowWeekNotes: Decodable {
        let items: [TickerNoteItem]
    }

    /// `notes/{id}/evidence`.
    struct Evidence: Decodable {
        struct Segment: Decodable {
            struct Hit: Decodable {
                let start: Int
                let end: Int
            }
            let segmentIndex: Int
            let t: String?
            let text: String
            let hits: [Hit]?
        }
        let segments: [Segment]
        let reason: String?
    }

    /// `/v1/shows/{slug}`: the show's latest episodes and `publishers/{key}/tickers`.
    struct ShowDetail: Decodable {
        let tickers: APISection<PublisherTickers>
    }

    struct PublisherTickers: Decodable {
        struct Row: Decodable {
            struct LastMention: Decodable {
                struct LastNote: Decodable {
                    let subject: String?
                    let startMin: Int?
                    let noteTimestamp: String?
                }
                let publishedAt: String?
                let sourceType: String?
                let sourceId: String?
                let title: String?
                let lastNote: LastNote?
                let referencePrice: TickerNotes.Price?
                let latestClose: TickerNotes.Price?
                let changeSincePct: Double?
            }
            let ticker: String
            let market: String?
            let identity: TickerNotes.Identity?
            let notes: Int?
            let episodes: Int?
            let lastMentionedAt: String?
            let lastMention: LastMention?
        }
        let rows: [Row]
        let throughDate: String?
    }

    /// `gold/ticker-weekly` (schema pending; shaped after the real response).
    struct TickerWeekly: Decodable {
        struct Row: Decodable {
            let weekStart: String
            let ticker: String
            let market: String?
            let name: String?
            let mentionCount: Int
        }
        struct Metadata: Decodable {
            struct Window: Decodable { let isComplete: Bool? }
            let window: Window?
        }
        let rows: [Row]
        let weeks: [String]
        let metadata: Metadata?
    }

    /// `radar/heat-price` (schema pending; shaped after the real response).
    struct HeatPrice: Decodable {
        struct Item: Decodable {
            let ticker: String
            let quadrant: String
            let mentions: Int?
            let prevMentions: Int?
            let priceAsOf: String?
            let percentile63d: Double?
            let rankChange20d: Int?
        }
        let weekStart: String?
        let weekEnd: String?
        let items: [Item]
    }

    // MARK: Watchlist (BFF-merged feed/notes)

    struct NotesFeed: Decodable {
        struct Episode: Decodable {
            let sourceType: String
            let sourceId: String
            let publisher: Publisher
            let publishedAt: String
            let publishDate: String?
            let title: String
            let notes: [EpisodeNote]
        }
        let episodes: [Episode]
        let tickerAliases: [String: String]?
    }

    // MARK: Search

    struct Search: Decodable {
        struct Result: Decodable {
            let kind: String
            let id: String
            let displayName: String?
            let market: String?
            let aliases: [String]?
        }
        let results: [Result]
    }
}
