import SwiftUI

/// Figma: 08 搜尋 (+ S4 搜尋 · 無結果) — results shown under the top bar while searching.
struct SearchView: View {
    @Environment(\.repository) private var repository
    @Binding var query: String
    @State private var results: LoadState<SearchResults>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WeftSpacing.md) {
                Text("支援代號別名：TSMC = 台積電 = 2330")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WeftColor.textSecondary)

                switch results {
                case nil:
                    StateView(kind: .empty, title: "搜尋個股或節目重點", message: "例如：博通、AVGO、台積電")
                case .loading:
                    SkeletonRow()
                case .failed(let error):
                    StateView(kind: .error, title: "讀不到資料", message: error.localizedDescription,
                              actionTitle: "重試") { Task { await search(query) } }
                case .loaded(let found) where found.isEmpty:
                    StateView(kind: .empty, title: "找不到「\(query)」",
                              message: "只收錄 4 個財經節目提到的個股與節目。可用代號或別名搜尋，例如 TSMC = 台積電 = 2330。",
                              actionTitle: "清除搜尋") { query = "" }
                case .loaded(let found):
                    if !found.stocks.isEmpty {
                        SectionHeader("個股")
                        VStack(spacing: 0) {
                            ForEach(found.stocks) { ranking in
                                NavigationLink(value: Route.stock(ranking.stock.ticker)) {
                                    StockRow(ranking: ranking, showsRank: false,
                                             metric: ranking.noteCount.map { "近 7 天 \($0) 則" } ?? "—",
                                             detail: ranking.episodeCount > 0 ? "\(ranking.episodeCount) 集" : "")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    if !found.notes.isEmpty {
                        SectionHeader("相關重點")
                        VStack(spacing: 0) {
                            ForEach(found.notes, id: \.note.id) { item in
                                NavigationLink(value: Route.episode(item.episode.ref)) {
                                    EpisodeCard(episode: item.episode, showsThisWeekBadge: false, note: item.note)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.top, WeftSpacing.xs)
            .weftScreen()
        }
        .scrollDismissesKeyboard(.interactively)
        .task(id: query) {
            // Debounce typing; .task(id:) cancels the previous search.
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await search(query)
        }
    }

    private func search(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = nil
            return
        }
        results = .loading
        do {
            let found = try await repository.search(text)
            if !Task.isCancelled { results = .loaded(found) }
        } catch is CancellationError {
        } catch {
            results = .failed(error)
        }
    }
}

#Preview {
    NavigationStack { WeftTabRoot(initiallySearching: true, initialQuery: "博通") { EmptyView() }.weftDestinations() }
        .environment(WatchlistStore())
}
