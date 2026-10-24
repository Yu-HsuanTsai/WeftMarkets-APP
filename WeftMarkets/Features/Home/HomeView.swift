import SwiftUI

/// Figma: 01 本週
struct HomeView: View {
    @Environment(\.repository) private var repository

    var body: some View {
        AsyncContent(loadingTitle: "正在載入本週重點…", load: { try await repository.weeklySummary() }) { summary in
            ScrollView {
                VStack(alignment: .leading, spacing: WeftSpacing.md) {
                    LargeTitleHeader(title: "本週", kicker: "WEEKLY EDITION · \(summary.week) · \(summary.dateLabel)")

                    InfoBanner(message: "涵蓋 \(summary.showsTotal) 個財經節目 · 每日 11:30（台北）更新")

                    VStack(alignment: .leading, spacing: 6) {
                        Text("所有財經節目，一週重點滑著看完。").font(.title.weight(.bold))
                        Text("把節目裡的事實、觀點與風險，一則一則讀完；想查證時，直接跳回原始片段。")
                            .font(.callout)
                            .foregroundStyle(WeftColor.textSecondary)
                    }

                    Grid(horizontalSpacing: WeftSpacing.md, verticalSpacing: 0) {
                        GridRow {
                            StatTile(label: "本週進版", value: "\(summary.episodes)", unit: "集")
                            StatTile(label: "整理出重點", value: "\(summary.notes)", unit: "則")
                        }
                        GridRow {
                            StatTile(label: "被萃取個股", value: "\(summary.tickers)", unit: "檔")
                            StatTile(label: "有新集數的節目", value: "\(summary.showsWithNewEpisodes) / \(summary.showsTotal)", unit: "個")
                        }
                    }

                    SectionHeader(title: "最新一集") {
                        NavigationLink("全部集數", value: Route.show(summary.latestEpisode.showID))
                    }
                    if let note = summary.latestEpisode.notes.first {
                        NavigationLink(value: Route.episode(summary.latestEpisode.id)) {
                            NoteCard(episode: summary.latestEpisode, note: note,
                                     kicker: "\(summary.latestEpisode.showName) · \(summary.latestEpisode.title) · 重點 1 / \(summary.latestEpisode.noteCount)")
                        }
                        .buttonStyle(.plain)
                    }

                    SectionHeader("最多集數提到的個股")
                    VStack(spacing: 0) {
                        ForEach(summary.topByEpisodes) { ranking in
                            NavigationLink(value: Route.stock(ranking.stock.ticker)) {
                                StockRow(ranking: ranking, metric: "\(ranking.episodeCount) 集", detail: "提到它的集數")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text("排行只數「提到它的集數」，不數字詞出現次數。")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(WeftColor.textSecondary)

                    SectionHeader("市場背景")
                    ForEach(summary.markets) { MarketContextCard(context: $0) }

                    Disclaimer()
                }
                .weftScreen()
            }
        }
        .navigationTitle("本週")
    }
}

#Preview {
    NavigationStack { WeftTabRoot { HomeView() }.weftDestinations() }
        .environment(WatchlistStore())
}
