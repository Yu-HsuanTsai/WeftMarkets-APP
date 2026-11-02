import SwiftUI

/// 近 12 週重點 on the stock page (`tickers/{t}/notes`): newest first, filterable by
/// show, next page loaded when the end of the list scrolls into view.
struct StockNotesSection: View {
    let ticker: String
    /// Already in the stock page response (all shows), so the first screen costs no call.
    let firstPage: StockNotesPage
    let shows: [NoteShowFilter]

    @Environment(\.repository) private var repository
    @State private var showKey: String?
    @State private var page: StockNotesPage?
    @State private var phase = Phase.idle

    private enum Phase: Equatable { case idle, loadingFirst, loadingMore, failed }

    private var current: StockNotesPage { page ?? firstPage }

    var body: some View {
        VStack(alignment: .leading, spacing: WeftSpacing.sm) {
            SectionHeader("近 12 週重點")
            if let notes = current.notes, let episodes = current.episodes {
                Text("\(notes) 則 · \(episodes) 集，由新到舊")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WeftColor.textSecondary)
            }
            if shows.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: WeftSpacing.xs) {
                        FilterChip(label: "全部", count: firstPage.notes.map { "\($0) 則" },
                                   isSelected: showKey == nil) { select(nil) }
                        ForEach(shows) { show in
                            FilterChip(label: show.name, count: "\(show.notes) 則",
                                       isSelected: showKey == show.key) { select(show.key) }
                        }
                    }
                }
            }

            if phase == .loadingFirst {
                SkeletonRow()
            } else if current.items.isEmpty {
                if phase == .failed {
                    retryRow("讀不到這個節目的重點。")
                } else {
                    StateView(kind: .empty, title: "近 12 週沒有相關重點")
                }
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(current.items) { StockMentionGroup(item: $0) }
                }
                footer
            }
        }
    }

    @ViewBuilder
    private var footer: some View {
        if current.nextCursor != nil {
            switch phase {
            case .failed:
                retryRow("下一頁載入失敗。")
            case .loadingMore:
                ProgressView().frame(maxWidth: .infinity).padding(.vertical, WeftSpacing.md)
            default:
                // Loads when it scrolls into view; also tappable as a fallback.
                Button("載入更多") { Task { await loadMore() } }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(WeftColor.accent)
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, WeftSpacing.md)
                    .onScrollVisibilityChange(threshold: 0.2) { visible in
                        if visible { Task { await loadMore() } }
                    }
            }
        } else {
            Text("已經到底了")
                .font(.caption.weight(.medium))
                .foregroundStyle(WeftColor.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, WeftSpacing.md)
        }
    }

    private func retryRow(_ message: String) -> some View {
        HStack {
            Text(message).font(.footnote).foregroundStyle(WeftColor.textSecondary)
            Spacer()
            Button("重試") {
                Task { current.items.isEmpty ? await loadFirst(for: showKey) : await loadMore() }
            }
            .font(.footnote.weight(.medium))
            .foregroundStyle(WeftColor.accent)
            .buttonStyle(.plain)
        }
        .padding(.vertical, WeftSpacing.md)
    }

    // MARK: Loading

    private func select(_ key: String?) {
        guard key != showKey else { return }
        showKey = key
        Task { await loadFirst(for: key) }
    }

    /// "全部" reuses the page that came with the stock page.
    private func loadFirst(for key: String?) async {
        guard let key else {
            page = nil
            phase = .idle
            return
        }
        page = StockNotesPage(items: [], nextCursor: nil, notes: nil, episodes: nil)
        phase = .loadingFirst
        do {
            let first = try await repository.stockNotes(ticker: ticker, showKey: key, cursor: nil)
            guard showKey == key else { return }
            page = first
            phase = .idle
        } catch {
            guard showKey == key else { return }
            phase = .failed
        }
    }

    private func loadMore() async {
        guard let cursor = current.nextCursor, phase == .idle || phase == .failed else { return }
        let key = showKey
        phase = .loadingMore
        do {
            let next = try await repository.stockNotes(ticker: ticker, showKey: key, cursor: cursor)
            guard showKey == key else { return }
            page = StockNotesPage(items: Self.merge(current.items, next.items), nextCursor: next.nextCursor,
                                  notes: next.notes ?? current.notes, episodes: next.episodes ?? current.episodes)
            phase = .idle
        } catch RepositoryError.cursorExpired {
            // The data was republished; conventions.md says to start over from page one.
            guard showKey == key else { return }
            do {
                page = try await repository.stockNotes(ticker: ticker, showKey: key, cursor: nil)
                phase = .idle
            } catch {
                phase = .failed
            }
        } catch {
            guard showKey == key else { return }
            phase = .failed
        }
    }

    /// An episode can straddle two pages; its notes are joined instead of listed twice
    /// (as on weftmarkets.com).
    static func merge(_ items: [StockEpisodeMention], _ next: [StockEpisodeMention]) -> [StockEpisodeMention] {
        guard let last = items.last, let first = next.first, last.id == first.id else { return items + next }
        let known = Set(last.notes.map(\.id))
        let joined = StockEpisodeMention(episode: last.episode,
                                         notes: last.notes + first.notes.filter { !known.contains($0.id) },
                                         referencePrices: last.referencePrices)
        return items.dropLast() + [joined] + next.dropFirst()
    }
}

/// One episode's notes about a stock, each opening the episode, then its reference close.
struct StockMentionGroup: View {
    let item: StockEpisodeMention
    @Environment(WatchlistStore.self) private var watchlist

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(item.notes) { note in
                NavigationLink(value: Route.episode(item.episode.ref)) {
                    EpisodeCard(episode: item.episode, showsThisWeekBadge: false,
                                isRead: watchlist.isRead(item.episode.ref), note: note)
                }
                .buttonStyle(.plain)
            }
            ForEach(item.referencePrices, id: \.self) {
                Text($0)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WeftColor.textSecondary)
                    .padding(.top, WeftSpacing.xs)
            }
        }
        .padding(.bottom, WeftSpacing.xs)
    }
}
