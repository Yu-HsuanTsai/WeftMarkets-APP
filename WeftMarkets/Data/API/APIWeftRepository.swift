import Foundation

/// `WeftRepository` backed by weft-bff. Maps API responses into the app's models;
/// blocks the API couldn't read are left out rather than filled with placeholders.
struct APIWeftRepository: WeftRepository {
    let client: APIClient

    // MARK: 本週

    func weeklySummary() async throws -> WeeklySummary {
        let home: DTO.Home = try await client.get("v1/home")
        guard let week = home.week.data else { throw error(for: home.week) }

        let items = week.items.sorted { $0.publishedAt > $1.publishedAt }
        // The home card shows the newest episode's first note, which only the detail has.
        var latest: Episode?
        if let newest = items.first, let platform = Platform(rawValue: newest.sourceType) {
            latest = try? await episode(id: Episode.ref(platform: platform, sourceID: newest.sourceId))
        }

        let date = week.date ?? week.throughDate ?? ""
        let top = home.topTickers.data?.items.prefix(5).map(Self.ranking) ?? []
        return WeeklySummary(
            dateLabel: Self.dateWithWeekday(date),
            week: Self.isoWeekLabel(date),
            period: [week.weekStart, week.weekEnd].compactMap { $0 }.joined(separator: " – "),
            episodes: items.count,
            notes: items.reduce(0) { $0 + $1.noteCount },
            tickers: Set(items.flatMap { $0.tickers ?? [] }).count,
            showsWithNewEpisodes: Set(items.map(\.publisher.key)).count,
            showsTotal: home.status.data?.publishersSupported ?? Self.showCatalog.count,
            topByEpisodes: Array(top),
            latestEpisode: latest,
            markets: [home.marketTw.data, home.marketUs.data].compactMap { $0.map(Self.marketContext) }
        )
    }

    // MARK: 節目

    func shows() async throws -> [Show] {
        let response: DTO.Shows = try await client.get("v1/shows")
        let weekAgo = Self.taipeiDate(daysAgo: 6)
        return response.shows.map { entry in
            let recent = entry.latest.data?.items.filter { Self.publishDate($0.publishDate, $0.publishedAt) >= weekAgo }
            return Show(id: entry.publisher.slug, name: entry.publisher.name,
                        platform: Platform(rawValue: entry.publisher.source),
                        episodesLast7Days: recent?.count ?? 0)
        }
    }

    func latestEpisodes(showID: String?) async throws -> [Episode] {
        if let showID {
            let feed: DTO.Feed = try await client.get("v1/shows/\(showID)/episodes")
            return feed.items.map { Self.episode($0, showID: showID) }
        }
        // 全部: the four shows' latest feeds merged, newest first.
        let response: DTO.Shows = try await client.get("v1/shows")
        let episodes = response.shows.flatMap { entry in
            (entry.latest.data?.items ?? []).map { (entry.publisher.slug, $0) }
        }
        guard !episodes.isEmpty || response.shows.contains(where: { $0.latest.data != nil }) else {
            throw RepositoryError.unavailable
        }
        return episodes
            .sorted { $0.1.publishedAt > $1.1.publishedAt }
            .map { Self.episode($0.1, showID: $0.0) }
    }

    func episode(id: String) async throws -> Episode {
        guard let ref = Episode.parseRef(id) else { throw RepositoryError.notFound }
        let sourceID = ref.sourceID.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(["/"])) ?? ref.sourceID
        let detail: DTO.EpisodeDetail = try await client.get("v1/episodes/\(ref.platform.rawValue)/\(sourceID)")
        let notes = detail.notes.map(Self.note)
        let tickers = Self.orderedUnique(notes.flatMap(\.tickers))
        return Episode(
            id: detail.sourceId,
            showID: Self.slug(forPublisherKey: detail.publisher.key),
            showName: detail.publisher.name,
            platform: ref.platform,
            date: Self.publishDate(detail.publishDate, detail.publishedAt),
            title: detail.title,
            summary: notes.first?.event ?? "",
            noteCount: detail.noteCount,
            tickerCount: tickers.count,
            estimatedTokens: Self.estimatedTokens(noteCount: detail.noteCount),
            tickers: tickers,
            notes: notes
        )
    }

    // MARK: 雷達

    func radar() async throws -> RadarSnapshot {
        let response: DTO.Radar = try await client.get("v1/radar")
        guard let top = response.topTickers.data else { throw error(for: response.topTickers) }
        let rankings = top.items.map(Self.ranking)
        guard let leader = rankings.first else { throw RepositoryError.unavailable }
        let period = [top.window?.from, top.window?.to].compactMap { $0 }.joined(separator: " – ")
        return RadarSnapshot(period: period, leader: leader, top: rankings, totalRanked: rankings.count)
    }

    func themes() async throws -> ThemeSnapshot {
        // No endpoint in the Narrative API docs provides a theme ranking.
        throw RepositoryError.notProvided("敘事主題排行")
    }

    // MARK: 個股

    func stock(ticker: String) async throws -> Stock {
        try await stockPage(ticker).stock
    }

    func stockDetail(ticker: String) async throws -> StockDetail? {
        try await stockPage(ticker).detail
    }

    /// Both stock calls read the same BFF route; the BFF caches it, so the second is cheap.
    private func stockPage(_ ticker: String) async throws -> (stock: Stock, detail: StockDetail?) {
        let symbol = ticker.uppercased()
        // Cold reads of a ticker can take ~20s upstream; the BFF waits up to 20s per block.
        let page: DTO.Stock = try await client.get("v1/stocks/\(symbol)", timeout: 30)
        let notes = page.notes.data
        let market: Market = (notes?.ticker.market ?? (symbol.hasSuffix(".TW") ? "TW" : "US")) == "TW" ? .tw : .us
        let aliases = (notes?.identity?.aliases ?? []).filter { $0 != symbol }
        let stock = Stock(ticker: symbol, name: notes?.identity?.displayName ?? symbol, market: market,
                          aliases: Self.orderedUnique(aliases))

        guard let notes else {
            if case .notFound = error(for: page.notes) { throw RepositoryError.notFound }
            return (stock, nil)
        }

        let price = page.priceContext.data
        let temperature = price?.narrative?.data?.narrativeTemperature ?? page.narrativeState.data?.narrativeTemperature
        let priceState = price?.priceState?.data?.priceState
        let heat = price?.heatPrice?.data
        let mentions = (notes.publishers ?? []).compactMap { publisher -> KOLMention? in
            guard let last = publisher.lastMention else { return nil }
            return KOLMention(
                showName: publisher.publisherName,
                date: Self.taipeiDate(fromAPITimestamp: last.publishedAt),
                topic: last.lastNote?.subject ?? last.title ?? "",
                priceThen: Self.priceLabel(last.referencePrice, withCurrency: false),
                priceNow: Self.priceLabel(last.latestClose, withCurrency: true),
                change: last.changeSincePct.map { String(format: "%+.2f%%", $0) } ?? "—"
            )
        }

        let detail = StockDetail(
            stock: stock,
            dataUpdated: notes.throughDate.map { "資料更新至 \($0)" } ?? "資料更新時間不明",
            mentions: mentions,
            notes12w: notes.totals?.notes ?? 0,
            episodes12w: notes.totals?.episodes ?? 0,
            shows12w: notes.totals?.publishers ?? 0,
            priceState: Self.priceStateLabel(priceState),
            narrativeTemperature: Self.temperatureLabel(temperature),
            narrativeXPrice: "\(Self.temperatureLabel(heat?.narrativeTemperature ?? temperature)) × \(Self.priceStateLabel(heat?.priceState ?? priceState))",
            preMentionReturn: price?.mentionReturns?.data?.retBeforeFirstMention.map { String(format: "%+.2f%%", $0 * 100) } ?? "—",
            market: page.market.data.map(Self.marketContext),
            weeklyMentions: page.showWeekly.data.flatMap { Self.weeklyMentions($0, symbol: symbol, notes: notes) },
            firstNotesPage: Self.notesPage(notes),
            noteShows: (notes.publishers ?? []).compactMap { publisher in
                guard let key = publisher.publisherKey, let count = publisher.notes, count > 0 else { return nil }
                return NoteShowFilter(key: key, name: publisher.publisherName, notes: count)
            }
        )
        return (stock, detail)
    }

    // MARK: 追蹤

    func notes(mentioning tickers: Set<String>) async throws -> [(episode: Episode, note: Note)] {
        guard !tickers.isEmpty else { return [] }
        let feed: DTO.NotesFeed = try await client.get("v1/notes", timeout: 45)
        // Normalise old symbols the user saved to current ones (ticker_aliases).
        let aliases = feed.tickerAliases ?? [:]
        let wanted = Set(tickers.map { aliases[$0] ?? $0 })
        return feed.episodes.flatMap { item -> [(episode: Episode, note: Note)] in
            let platform = Platform(rawValue: item.sourceType) ?? .youtube
            let notes = item.notes.map(Self.note)
            // Match on each note's own tickers, not the episode's (screens.md).
            let matching = notes.filter { !wanted.isDisjoint(with: $0.tickers) }
            guard !matching.isEmpty else { return [] }
            let episode = Episode(
                id: item.sourceId,
                showID: Self.slug(forPublisherKey: item.publisher.key),
                showName: item.publisher.name,
                platform: platform,
                date: Self.publishDate(item.publishDate, item.publishedAt),
                title: item.title,
                summary: "",
                noteCount: notes.count,
                tickerCount: Self.orderedUnique(notes.flatMap(\.tickers)).count,
                estimatedTokens: Self.estimatedTokens(noteCount: notes.count),
                tickers: Self.orderedUnique(notes.flatMap(\.tickers)),
                notes: notes
            )
            return matching.map { (episode: episode, note: $0) }
        }
    }

    func weekMentions(ticker: String, showKey: String, weekStart: String) async throws -> [StockEpisodeMention] {
        let response: DTO.ShowWeekNotes = try await client.get(
            "v1/stocks/\(ticker.uppercased())/show-weekly/notes",
            query: ["publisher_key": showKey, "week_start": weekStart], timeout: 30)
        return response.items.map { Self.mention($0, fallbackShowKey: showKey) }
    }

    func stockNotes(ticker: String, showKey: String?, cursor: String?) async throws -> StockNotesPage {
        let response: DTO.TickerNotes = try await client.get(
            "v1/stocks/\(ticker.uppercased())/notes",
            query: ["publisher_key": showKey, "cursor": cursor], timeout: 30)
        return Self.notesPage(response)
    }

    func evidence(episodeRef: String, noteID: String) async throws -> NoteEvidence {
        guard let ref = Episode.parseRef(episodeRef) else { throw RepositoryError.notFound }
        let response: DTO.Evidence = try await client.get(
            "v1/episodes/\(ref.platform.rawValue)/\(ref.sourceID)/notes/\(noteID)/evidence")
        return NoteEvidence(
            segments: response.segments.map { segment in
                .init(id: segment.segmentIndex, time: segment.t ?? "", text: segment.text,
                      hits: (segment.hits ?? []).filter { $0.start < $0.end }.map { $0.start..<$0.end })
            },
            reason: response.reason)
    }

    func showTickers(showID: String) async throws -> [ShowTickerRow] {
        let response: DTO.ShowDetail = try await client.get("v1/shows/\(showID)")
        guard let data = response.tickers.data else { throw error(for: response.tickers) }
        return data.rows
            .map { Self.showTickerRow($0, throughDate: data.throughDate) }
            // 依上次提及由新到舊 (weftmarkets.com); stable for equal dates.
            .enumerated()
            .sorted { ($0.element.lastMentionDate, -$0.offset) > ($1.element.lastMentionDate, -$1.offset) }
            .map(\.element)
    }

    static func notesPage(_ dto: DTO.TickerNotes) -> StockNotesPage {
        StockNotesPage(items: (dto.items ?? []).map { mention($0, fallbackShowKey: nil) },
                       nextCursor: dto.nextCursor,
                       notes: dto.totals?.notes,
                       episodes: dto.totals?.episodes)
    }

    static func mention(_ item: DTO.TickerNoteItem, fallbackShowKey: String?) -> StockEpisodeMention {
        let notes = item.notes.map { note($0) }
        let showKey = item.publisherKey ?? fallbackShowKey ?? ""
        let episode = Episode(
            id: item.sourceId,
            showID: slug(forPublisherKey: showKey),
            showName: item.publisherName ?? showCatalog.first { $0.key == showKey }?.name ?? "",
            platform: Platform(rawValue: item.sourceType) ?? .youtube,
            date: publishDate(nil, item.publishedAt),
            title: item.episodeTitle ?? "（無標題）",
            summary: "",
            noteCount: notes.count,
            tickerCount: 0,
            estimatedTokens: estimatedTokens(noteCount: notes.count),
            tickers: [],
            notes: notes
        )
        // Dual listings carry one price per listing, as on weftmarkets.com.
        let prices: [String] = if let listings = item.referencePrices, !listings.isEmpty {
            listings.map { "\($0.symbol.replacingOccurrences(of: ".TW", with: "")) · \(referencePriceLabel($0.referencePrice))" }
        } else {
            [referencePriceLabel(item.referencePrice)]
        }
        return StockEpisodeMention(episode: episode, notes: notes, referencePrices: prices)
    }

    static func showTickerRow(_ row: DTO.PublisherTickers.Row, throughDate: String?) -> ShowTickerRow {
        let last = row.lastMention
        let mentionDate = (last?.publishedAt ?? row.lastMentionedAt).map { taipeiDate(fromAPITimestamp: $0) } ?? ""
        let minute: String? = if let stamp = last?.lastNote?.noteTimestamp {
            "\(stamp.replacingOccurrences(of: "-", with: "–")) 分"
        } else {
            last?.lastNote?.startMin.map { "\($0) 分" }
        }
        func price(_ p: DTO.TickerNotes.Price?) -> String {
            guard let close = p?.adjustedClose else { return "—" }
            let day = p?.tradeDate.map { String($0.suffix(5)) }.map { "\($0) " } ?? ""
            return day + close.formatted(.number.precision(.fractionLength(2)))
        }
        let currency = last?.latestClose?.currency ?? last?.referencePrice?.currency
        let ref: String? = if let type = last?.sourceType, let id = last?.sourceId,
                              let platform = Platform(rawValue: type) {
            Episode.ref(platform: platform, sourceID: id)
        } else {
            nil
        }
        return ShowTickerRow(
            stock: Stock(ticker: row.ticker, name: row.identity?.displayName ?? row.ticker,
                         market: row.market == "TW" ? .tw : .us,
                         aliases: (row.identity?.aliases ?? []).filter { $0 != row.ticker }),
            lastMentionDate: mentionDate,
            subject: last?.lastNote?.subject ?? last?.title ?? "",
            minuteLabel: minute,
            changePct: last?.changeSincePct,
            priceLine: "當時 \(price(last?.referencePrice)) → 最新 \(price(last?.latestClose))\(currency.map { " \($0)" } ?? "")",
            daysSinceMention: daysBetween(mentionDate, throughDate),
            episodeRef: ref
        )
    }

    /// Calendar days from `from` to `to` (both yyyy-MM-dd); nil if either is missing.
    static func daysBetween(_ from: String, _ to: String?) -> Int? {
        guard let to, let start = ymd.date(from: from), let end = ymd.date(from: to) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = taipei
        return calendar.dateComponents([.day], from: start, to: end).day
    }

    /// Wording from weftmarkets.com: "參考收盤價：213.66 USD · 10/29 當日收盤".
    static func referencePriceLabel(_ price: DTO.TickerNoteItem.Price?) -> String {
        guard let price, price.basis != "unavailable", let close = price.adjustedClose else {
            return "參考收盤價：無可用資料（未涵蓋此標的／日期，或暫時讀不到價格）"
        }
        var label = "參考收盤價：\(close.formatted(.number.precision(.fractionLength(2))))"
        if let currency = price.currency { label += " \(currency)" }
        let basis = switch price.basis {
        case "publication_day_close": "當日收盤"
        case "previous_trading_day_close": "前一個交易日收盤"
        default: ""
        }
        let day = price.tradeDate.map(weekLabel) ?? ""
        let suffix = [day, basis].filter { !$0.isEmpty }.joined(separator: " ")
        return suffix.isEmpty ? label : "\(label) · \(suffix)"
    }

    // MARK: 雷達圖表

    func mentionTrend() async throws -> MentionTrend {
        let response: DTO.TickerWeekly = try await client.get("v1/radar/trend", timeout: 30)
        return Self.mentionTrend(response)
    }

    func heatPrice() async throws -> HeatPriceBoard {
        let response: DTO.HeatPrice = try await client.get("v1/radar/heat-price", timeout: 30)
        return Self.heatPriceBoard(response)
    }

    /// Top 5 by mentions summed over the window (screens.md); ties keep API order.
    static func mentionTrend(_ dto: DTO.TickerWeekly) -> MentionTrend {
        var totals: [String: Int] = [:]
        var order: [String] = []
        var byWeek: [String: [String: Int]] = [:]
        var labels: [String: String] = [:]
        for row in dto.rows {
            if totals[row.ticker] == nil { order.append(row.ticker) }
            totals[row.ticker, default: 0] += row.mentionCount
            byWeek[row.ticker, default: [:]][row.weekStart, default: 0] += row.mentionCount
            labels[row.ticker] = row.market == "TW" ? (row.name ?? row.ticker) : row.ticker
        }
        let top = order.enumerated()
            .sorted { (totals[$0.element]!, -$0.offset) > (totals[$1.element]!, -$1.offset) }
            .prefix(5)
            .map(\.element)
        return MentionTrend(
            weeks: dto.weeks.map { weekLabel($0) },
            series: top.map { ticker in
                .init(ticker: ticker, label: labels[ticker] ?? ticker,
                      values: dto.weeks.map { byWeek[ticker]?[$0] ?? 0 })
            },
            lastWeekPartial: dto.metadata?.window?.isComplete == false
        )
    }

    /// Cell names and wording from weftmarkets.com.
    private static let heatCells: [(id: String, title: String, subtitle: String)] = [
        ("consensus_forming", "共識形成中", "熱度升溫・相對強弱轉強"),
        ("talk_without_price", "大家在講但價格沒反應", "熱度升溫・相對強弱落後"),
        ("discussion_lagging", "討論慢半拍", "價格先動・討論還沒跟上"),
        ("quiet_after_move", "討論已經安靜", "熱度退燒・價格仍強"),
    ]

    static func heatPriceBoard(_ dto: DTO.HeatPrice) -> HeatPriceBoard {
        let period = [dto.weekStart, dto.weekEnd].compactMap { $0.map { String($0.suffix(5)) } }.joined(separator: " – ")
        let cells = heatCells.map { cell in
            HeatPriceBoard.Cell(
                id: cell.id, title: cell.title, subtitle: cell.subtitle,
                rows: dto.items.filter { $0.quadrant == cell.id }.map { item in
                    HeatPriceBoard.Row(
                        ticker: item.ticker,
                        mentions: "\(item.mentions.map(String.init) ?? "—")（\(item.prevMentions.map(String.init) ?? "—")）",
                        strength: item.percentile63d.map { String(format: "%.2f", $0) } ?? "—",
                        rankChange: item.rankChange20d.map { $0 > 0 ? "+\($0)" : "\($0)" } ?? "—")
                })
        }
        let known = Set(heatCells.map(\.id))
        return HeatPriceBoard(
            period: period,
            priceAsOf: dto.items.compactMap(\.priceAsOf).max(),
            cells: cells,
            unclassified: dto.items.filter { !known.contains($0.quadrant) }.map(\.ticker))
    }

    // MARK: 搜尋

    func search(_ query: String) async throws -> SearchResults {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return SearchResults(stocks: [], notes: []) }
        let response: DTO.Search = try await client.get("v1/search", query: ["q": q])
        let stocks = response.results
            .filter { $0.kind == "security" }
            .map { result in
                StockRanking(rank: 0,
                             stock: Stock(ticker: result.id, name: result.displayName ?? result.id,
                                          market: result.market == "TW" ? .tw : .us,
                                          aliases: (result.aliases ?? []).filter { $0 != result.id }),
                             noteCount: nil, episodeCount: 0, showCount: nil)
            }
        // The search API returns securities and shows only; there is no note search.
        return SearchResults(stocks: stocks, notes: [])
    }

    // MARK: - Mapping

    private func error<T>(for section: APISection<T>) -> RepositoryError {
        APIClient.repositoryError(status: 0, code: section.error?.code)
    }

    private static let showCatalog: [(slug: String, key: String, name: String)] = [
        ("you-ting-hao", "UC0lbAQVpenvfA2QqzsRtL_g", "游庭皓的財經皓角"),
        ("jenny", "UCdwPn2TO60Ec8QDIFRx50lQ", "財女珍妮"),
        ("gooaye", "1zWxx5pKk0XBEzMupVC7UZ", "Gooaye 股癌"),
        ("leek-graduate", "66ENh5UtNA3pPNOT0IZjO1", "韭菜畢業班"),
    ]

    static func slug(forPublisherKey key: String) -> String {
        showCatalog.first { $0.key == key }?.slug ?? key
    }

    /// show-weekly gives publisher keys only; names come from the same page's notes
    /// block, then the fixed show list. Show weeks are matched to price weeks by date.
    static func weeklyMentions(_ dto: DTO.ShowWeekly, symbol: String, notes: DTO.TickerNotes) -> WeeklyMentions? {
        guard !dto.weeks.isEmpty, !dto.shows.isEmpty else { return nil }
        let weeks = dto.weeks.map { week in
            WeeklyMentions.Week(start: week.weekStart, label: weekLabel(week.weekStart), partial: week.partial ?? false)
        }
        let starts = weeks.map(\.start)
        func aligned<T>(_ items: [T], start: (T) -> String) -> [T?] {
            let byStart = Dictionary(items.map { (start($0), $0) }, uniquingKeysWith: { first, _ in first })
            return starts.map { byStart[$0] }
        }

        let prices: [WeeklyMentions.PriceSeries]
        if let listings = dto.listings, !listings.isEmpty {
            prices = listings.map { listing in
                let points = aligned(listing.weeks) { $0.weekStart }
                let heading = [listing.market == "TW" ? "台股" : "美股 ADR", listing.symbol.replacingOccurrences(of: ".TW", with: ""), listing.currency]
                    .compactMap { $0 }.joined(separator: " · ")
                return .init(symbol: listing.symbol, heading: heading, currency: listing.currency,
                             closes: points.map { $0?.close }, tradeDates: points.map { $0?.tradeDate })
            }
        } else {
            let currency = notes.publishers?.lazy.compactMap { $0.lastMention?.latestClose?.currency ?? $0.lastMention?.referencePrice?.currency }.first
            prices = [.init(symbol: symbol, heading: nil, currency: currency,
                            closes: dto.weeks.map(\.close), tradeDates: dto.weeks.map(\.tradeDate))]
        }

        let names = Dictionary((notes.publishers ?? []).compactMap { p in p.publisherKey.map { ($0, p.publisherName) } },
                               uniquingKeysWith: { first, _ in first })
        let shows = dto.shows.map { show in
            WeeklyMentions.Show(
                key: show.publisherKey,
                name: names[show.publisherKey] ?? showCatalog.first { $0.key == show.publisherKey }?.name ?? show.publisherKey,
                weeks: aligned(show.weeks) { $0.weekStart }.map { week in
                    week.map { .init(mentionNotes: $0.mentionNotes, mentionEpisodes: $0.mentionEpisodes,
                                     showNotes: $0.showNotes, showEpisodes: $0.showEpisodes, rate: $0.mentionRate) }
                }
            )
        }
        return WeeklyMentions(weeks: weeks, prices: prices, shows: shows)
    }

    /// "2026-08-10" → "08/10".
    nonisolated static func weekLabel(_ ymd: String) -> String {
        let parts = ymd.split(separator: "-")
        return parts.count == 3 ? "\(parts[1])/\(parts[2])" : ymd
    }

    static func episode(_ dto: DTO.EpisodeSummary, showID: String) -> Episode {
        Episode(
            id: dto.sourceId,
            showID: showID,
            showName: dto.publisher.name,
            platform: Platform(rawValue: dto.sourceType) ?? .youtube,
            date: publishDate(dto.publishDate, dto.publishedAt),
            title: dto.title,
            summary: dto.shortSummary ?? "",
            noteCount: dto.noteCount,
            tickerCount: dto.tickers?.count ?? 0,
            estimatedTokens: estimatedTokens(noteCount: dto.noteCount),
            tickers: dto.tickers ?? [],
            notes: []
        )
    }

    static func note(_ dto: DTO.EpisodeNote) -> Note {
        Note(id: dto.noteId,
             index: dto.noteIndex ?? 0,
             title: dto.subject ?? "",
             startMinute: dto.startMin ?? 0,
             endMinute: dto.endMin ?? dto.startMin ?? 0,
             event: dto.fact ?? "",
             view: dto.hostView ?? "",
             risk: dto.risk,
             tickers: dto.tickers ?? [])
    }

    static func ranking(_ item: DTO.TopTickers.Item) -> StockRanking {
        StockRanking(rank: item.rank,
                     stock: Stock(ticker: item.ticker, name: item.displayName ?? item.ticker,
                                  market: item.market == "TW" ? .tw : .us, aliases: []),
                     noteCount: item.noteCount,
                     episodeCount: item.episodeCount ?? 0,
                     showCount: item.publisherCount)
    }

    /// Same estimate the site uses for the episode page: notes × 77.78.
    static func estimatedTokens(noteCount: Int) -> Int { Int((Double(noteCount) * 77.78).rounded()) }

    static func marketContext(_ dto: DTO.MarketContext) -> MarketContext {
        let name = dto.marketId == "TW" ? "台股" : "美股"
        guard dto.status == "ready" || dto.status == "stale", let context = dto.context else {
            // Wording as on the web's stock page when no context is published.
            let reasons = (dto.reasonCodes ?? []).joined(separator: "、")
            var details: [String] = []
            if let session = dto.expectedPriceSession ?? dto.priceSession { details.append("參考價格日 \(session)") }
            if !reasons.isEmpty { details.append("背景原因：\(reasons)") }
            return MarketContext(market: name, status: .insufficient,
                                 line1: "收錄股票廣度：尚無對應的已發布背景",
                                 line2: details.joined(separator: " · "))
        }
        // The API's trend / regime values are codes without published Chinese labels, shown as-is.
        let benchmarks = (context.benchmark ?? [:])
            .sorted { $0.key < $1.key }
            .map { "\($0.key) \($0.value.trendState ?? "—")" }
            .joined(separator: " · ")
        var line2 = "收錄股票廣度：\(context.regime?.label ?? "—")"
        if let session = dto.priceSession { line2 += " · 價格日 \(session)" }
        if dto.status == "stale" { line2 += " · 資料延遲" }
        return MarketContext(market: name, status: .ready,
                             line1: benchmarks.isEmpty ? "Benchmark：—" : "Benchmark：\(benchmarks)",
                             line2: line2)
    }

    // Labels confirmed against weftmarkets.com and its method notes (結構轉弱、偏熱、回檔整理、趨勢中).
    static func priceStateLabel(_ code: String?) -> String {
        switch code {
        case "BROKEN": "結構轉弱"
        case "EXTENDED": "偏熱"
        case "COOLED": "回檔整理"
        case "TRENDING": "趨勢中"
        case nil, "UNKNOWN": "不分類"
        case let other?: other
        }
    }

    // Only WARM → 溫熱 is confirmed on the site; other codes are shown as-is until their labels are known.
    static func temperatureLabel(_ code: String?) -> String {
        switch code {
        case "WARM": "溫熱"
        case nil, "UNKNOWN": "不分類"
        case let other?: other
        }
    }

    static func priceLabel(_ price: DTO.TickerNotes.Price?, withCurrency: Bool) -> String {
        guard let close = price?.adjustedClose else { return "—" }
        var label = close.formatted(.number.precision(.fractionLength(0...2)))
        if withCurrency, let currency = price?.currency { label += " \(currency)" }
        if let day = price?.tradeDate, day.count == 10 { label += "（\(day.suffix(5))）" }
        return label
    }

    // MARK: Dates (always Asia/Taipei — conventions.md)

    private static let taipei = TimeZone(identifier: "Asia/Taipei")!

    private static let ymd: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = taipei
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// API timestamps look like "2026-10-30 01:02:20.000" and are UTC.
    private static let apiTimestamp: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    static func taipeiDate(fromAPITimestamp raw: String) -> String {
        guard let date = apiTimestamp.date(from: String(raw.prefix(19))) else { return String(raw.prefix(10)) }
        return ymd.string(from: date)
    }

    /// An episode's publish day: `publish_date` if present, else `published_at` in Taipei.
    static func publishDate(_ publishDate: String?, _ publishedAt: String) -> String {
        publishDate ?? taipeiDate(fromAPITimestamp: publishedAt)
    }

    static func taipeiDate(daysAgo: Int, now: Date = .now) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = taipei
        return ymd.string(from: calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now)
    }

    static func dateWithWeekday(_ day: String) -> String {
        guard let date = ymd.date(from: day) else { return day }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = taipei
        let weekday = ["週日", "週一", "週二", "週三", "週四", "週五", "週六"][calendar.component(.weekday, from: date) - 1]
        return "\(day) \(weekday)"
    }

    static func isoWeekLabel(_ day: String) -> String {
        guard let date = ymd.date(from: day) else { return "" }
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = taipei
        return "W\(calendar.component(.weekOfYear, from: date))"
    }

    static func orderedUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}
