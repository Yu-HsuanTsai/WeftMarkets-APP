import SwiftUI
import UniformTypeIdentifiers

/// Figma: 07 追蹤 (+ S2 追蹤 · Empty)
struct WatchlistView: View {
    @Environment(\.repository) private var repository
    @Environment(WatchlistStore.self) private var watchlist
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var confirmsClear = false
    @State private var importError: String?
    /// Radar Top 15 by ticker, used for names and 7-day counts of tracked stocks when available.
    @State private var rankings: [String: StockRanking] = [:]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WeftSpacing.md) {
                LargeTitleHeader(title: "追蹤", kicker: "LOCAL WATCHLIST · 本機追蹤")
                InfoBanner(message: "不用登入。追蹤與已讀只存在這台裝置，沒有雲端副本。")

                if watchlist.trackedTickers.isEmpty {
                    StateView(kind: .empty, title: "還沒有追蹤的個股",
                              message: "在個股頁點「追蹤」，這裡會列出它近七天的相關重點。")
                } else {
                    SectionHeader("追蹤的個股")
                    VStack(spacing: 0) {
                        ForEach(watchlist.trackedTickers, id: \.self) { ticker in
                            let ranking = rankings[ticker]
                                ?? StockRanking(rank: 0, stock: Stock(ticker: ticker, name: "", market: ticker.hasSuffix(".TW") ? .tw : .us, aliases: []),
                                                noteCount: nil, episodeCount: 0, showCount: nil)
                            NavigationLink(value: Route.stock(ticker)) {
                                StockRow(ranking: ranking, showsRank: false,
                                         metric: ranking.noteCount.map { "近 7 天 \($0) 則" } ?? "—",
                                         detail: ranking.episodeCount > 0 ? "\(ranking.episodeCount) 集" : "")
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("取消追蹤", systemImage: "star.slash", role: .destructive) { watchlist.toggleTracked(ticker) }
                            }
                        }
                    }

                    SectionHeader("最近七天相關重點")
                    AsyncContent(load: { try await repository.notes(mentioning: Set(watchlist.trackedTickers)) }) { items in
                        if items.isEmpty {
                            StateView(kind: .empty, title: "最近七天沒有相關重點")
                        } else {
                            VStack(spacing: 0) {
                                ForEach(items, id: \.note.id) { item in
                                    NavigationLink(value: Route.episode(item.episode.ref)) {
                                        EpisodeCard(episode: item.episode, showsThisWeekBadge: false,
                                                    isRead: watchlist.isRead(item.episode.ref), note: item.note)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    } placeholder: {
                        SkeletonRow()
                    }
                    .id(watchlist.trackedTickers)
                }

                SectionHeader("這台裝置的研究狀態")
                VStack(spacing: 0) {
                    Button { isExporting = true } label: {
                        ListRowLabel(title: "匯出 JSON", systemImage: "square.and.arrow.down")
                    }
                    Button { isImporting = true } label: {
                        ListRowLabel(title: "匯入 JSON", systemImage: "square.and.arrow.up")
                    }
                    Button { confirmsClear = true } label: {
                        ListRowLabel(title: "清除本機狀態", systemImage: "trash", showsChevron: false)
                    }
                }
                .buttonStyle(.plain)
                Text("清除前可先匯出；另一台裝置不會自動取得這份狀態。")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(WeftColor.textSecondary)
            }
            .weftScreen()
        }
        .navigationTitle("追蹤")
        .task {
            guard let radar = try? await repository.radar() else { return }
            rankings = Dictionary(radar.top.map { ($0.stock.ticker, $0) }, uniquingKeysWith: { first, _ in first })
        }
        .fileExporter(isPresented: $isExporting,
                      document: WatchlistDocument(snapshot: watchlist.snapshot),
                      contentType: .json,
                      defaultFilename: "weft-watchlist") { _ in }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let accessing = url.startAccessingSecurityScopedResource()
                defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                let snapshot = try JSONDecoder().decode(WatchlistStore.Snapshot.self, from: Data(contentsOf: url))
                watchlist.replace(with: snapshot)
            } catch {
                importError = "這個檔案不是 Weft 匯出的追蹤資料。"
            }
        }
        .confirmationDialog("清除這台裝置的追蹤與已讀？", isPresented: $confirmsClear, titleVisibility: .visible) {
            Button("清除本機狀態", role: .destructive) { watchlist.clear() }
        } message: {
            Text("無法復原。清除前可先匯出 JSON。")
        }
        .alert("匯入失敗", isPresented: .constant(importError != nil)) {
            Button("好") { importError = nil }
        } message: {
            Text(importError ?? "")
        }
    }
}

#Preview {
    NavigationStack { WeftTabRoot { WatchlistView() }.weftDestinations() }
        .environment(WatchlistStore())
}
