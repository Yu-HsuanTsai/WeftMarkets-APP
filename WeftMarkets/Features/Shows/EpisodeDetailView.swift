import SwiftUI

/// Figma: 03 單集 (+ S5 單集 · Loading)
struct EpisodeDetailView: View {
    let episodeID: String
    @Environment(\.repository) private var repository

    var body: some View {
        AsyncContent(loadingTitle: "正在載入這集的重點…", load: { try await repository.episode(id: episodeID) }) { episode in
            EpisodeContent(episode: episode)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct EpisodeContent: View {
    let episode: Episode
    @Environment(WatchlistStore.self) private var watchlist
    @Environment(\.openURL) private var openURL
    @State private var page: Note.ID?

    private var currentIndex: Int {
        episode.notes.firstIndex { $0.id == page } ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WeftSpacing.md) {
                VStack(alignment: .leading, spacing: 6) {
                    Kicker(text: "\(episode.platform.label) · \(episode.showName) · \(episode.date)")
                    Text(episode.title).font(.title.weight(.bold))
                }

                HStack(spacing: WeftSpacing.sm) {
                    StatTile(label: "重點", value: "\(episode.noteCount)", unit: "則")
                    StatTile(label: "提到的個股", value: "\(episode.tickerCount)", unit: "檔")
                    StatTile(label: "tokens（估算）", value: episode.estimatedTokens.formatted())
                }

                HStack(spacing: WeftSpacing.sm) {
                    Button("開啟原始節目 ↗") {
                        if let url = episode.sourceURL { openURL(url) }
                    }
                    .buttonStyle(.weftPrimary)
                    Button(watchlist.isRead(episode.id) ? "已讀 ✓" : "標為已讀") {
                        watchlist.toggleRead(episode.id)
                    }
                    .buttonStyle(.weftSecondary)
                }

                // Pager label + progress (Figma: Brand/Pager)
                VStack(alignment: .leading, spacing: 6) {
                    Text("第 \(currentIndex + 1) 則，已載入 \(episode.notes.count) / \(episode.noteCount) 則 · 左右滑動翻頁")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WeftColor.textSecondary)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(WeftColor.bgSecondary)
                            Rectangle().fill(WeftColor.textPrimary)
                                .frame(width: proxy.size.width * CGFloat(currentIndex + 1) / CGFloat(max(episode.notes.count, 1)))
                        }
                    }
                    .frame(height: 4)
                }

                // 重點卡: horizontal paging
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: WeftSpacing.sm) {
                        ForEach(episode.notes) { note in
                            NoteCard(episode: episode, note: note)
                                .containerRelativeFrame(.horizontal)
                                .id(note.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $page)
                .scrollIndicators(.hidden)
                .scrollClipDisabled()

                if !episode.tickers.isEmpty {
                    VStack(alignment: .leading, spacing: WeftSpacing.xs) {
                        Text("提到的個股").font(.caption.weight(.medium)).foregroundStyle(WeftColor.textSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(episode.tickers, id: \.self) { ticker in
                                    NavigationLink(value: Route.stock(ticker)) { TickerTag(text: ticker) }
                                        .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                Disclaimer(text: "重點數與個股數為實際資料；tokens 為估算（重點數 × 77.78）。AI 摘要可能出錯，引用前請回到原片確認。非投資建議。")
            }
            .weftScreen()
        }
        .navigationTitle(episode.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let url = episode.sourceURL {
                    ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
                }
            }
        }
    }
}

#Preview {
    NavigationStack { EpisodeDetailView(episodeID: MockData.episodes[0].id).weftDestinations() }
        .environment(WatchlistStore())
}
