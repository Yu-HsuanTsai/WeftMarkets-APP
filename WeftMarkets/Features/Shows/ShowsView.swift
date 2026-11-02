import SwiftUI

/// Figma: 02 節目 (+ S1 節目 · Loading)
struct ShowsView: View {
    @Environment(\.repository) private var repository
    @Environment(WatchlistStore.self) private var watchlist
    @State private var selectedShowID: String?
    @State private var shows: [Show] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WeftSpacing.md) {
                LargeTitleHeader(title: "節目", kicker: "SHOW DIRECTORY · 最新集數")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: WeftSpacing.xs) {
                        FilterChip(label: "全部", count: "最新", isSelected: selectedShowID == nil) { selectedShowID = nil }
                        ForEach(shows) { show in
                            FilterChip(label: show.name, count: "近 7 天 \(show.episodesLast7Days) 集",
                                       isSelected: selectedShowID == show.id) { selectedShowID = show.id }
                        }
                    }
                }
                .scrollClipDisabled()

                SectionHeader(title: "最新集數") {
                    if let selectedShowID {
                        NavigationLink("節目詳情", value: Route.show(selectedShowID))
                    }
                }

                AsyncContent(load: { try await repository.latestEpisodes(showID: selectedShowID) }) { episodes in
                    if episodes.isEmpty {
                        StateView(kind: .empty, title: "近 7 天沒有新集數", message: "可以先看其他節目的最新集數。")
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(episodes) { episode in
                                NavigationLink(value: Route.episode(episode.ref)) {
                                    EpisodeCard(episode: episode, showsThisWeekBadge: episode.isWithinLast7Days, isRead: watchlist.isRead(episode.ref))
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(watchlist.isRead(episode.ref) ? "標為未讀" : "標為已讀", systemImage: "checkmark") {
                                        watchlist.toggleRead(episode.ref)
                                    }
                                }
                            }
                        }
                    }
                } placeholder: {
                    VStack(spacing: 0) { ForEach(0..<3, id: \.self) { _ in SkeletonRow() } }
                    Text("正在載入最近集數…").font(.footnote).foregroundStyle(WeftColor.textSecondary)
                }
                .id(selectedShowID)

                Disclaimer()
            }
            .weftScreen()
        }
        .navigationTitle("節目")
        .task { shows = (try? await repository.shows()) ?? [] }
    }
}

/// 節目詳情: the show's recent episodes. (The 近 30 天提到的標的 table arrives with the API.)
struct ShowDetailView: View {
    let showID: String
    @Environment(\.repository) private var repository
    @Environment(WatchlistStore.self) private var watchlist
    @State private var showName: String?


    var body: some View {
        AsyncContent(loadingTitle: "正在載入最近集數…", load: { try await repository.latestEpisodes(showID: showID) }) { episodes in
            ScrollView {
                VStack(alignment: .leading, spacing: WeftSpacing.md) {
                    if let first = episodes.first {
                        Kicker(text: "\(first.platform.label) · \(first.showName)")
                    }
                    SectionHeader("最近集數")
                    if episodes.isEmpty {
                        StateView(kind: .empty, title: "目前沒有已整理的集數")
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(episodes) { episode in
                                NavigationLink(value: Route.episode(episode.ref)) {
                                    EpisodeCard(episode: episode, showsThisWeekBadge: episode.isWithinLast7Days, isRead: watchlist.isRead(episode.ref))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    ShowTickersSection(showID: showID)
                    Disclaimer()
                }
                .weftScreen()
            }
        }
        .navigationTitle(showName ?? "節目")
        .task { showName = try? await repository.shows().first { $0.id == showID }?.name }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { WeftTabRoot { ShowsView() }.weftDestinations() }
        .environment(WatchlistStore())
}
