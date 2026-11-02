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

                    // Blocks whose data couldn't be read are hidden, not faked.
                    if let latest = summary.latestEpisode, let note = latest.notes.first {
                        SectionHeader(title: "最新一集") {
                            NavigationLink("全部集數", value: Route.show(latest.showID))
                        }
                        NavigationLink(value: Route.episode(latest.ref)) {
                            NoteCard(episode: latest, note: note,
                                     kicker: "\(latest.showName) · \(latest.title) · 重點 1 / \(latest.noteCount)")
                        }
                        .buttonStyle(.plain)
                    }

                    if !summary.topByEpisodes.isEmpty {
                        SectionHeader("近 7 天熱門個股")
                        VStack(spacing: 0) {
                            ForEach(summary.topByEpisodes) { ranking in
                                NavigationLink(value: Route.stock(ranking.stock.ticker)) {
                                    StockRow(ranking: ranking,
                                             metric: ranking.noteCount.map { "\($0) 則" } ?? "\(ranking.episodeCount) 集",
                                             detail: ranking.noteCount == nil ? "提到它的集數" : "\(ranking.episodeCount) 集")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text("依近 7 天被整理成重點的則數排名，反映討論熱度，不是投資建議。")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(WeftColor.textSecondary)
                    }

                    if !summary.markets.isEmpty {
                        SectionHeader("市場背景")
                        ForEach(summary.markets) { MarketContextCard(context: $0) }
                    }

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
