import SwiftUI

/// Root: iOS 26 tab bar — 本週 / 節目 / 雷達 / 追蹤, icon only.
/// Search lives in each tab's top bar (WeftTabRoot) instead of a bottom-right tab.
struct ContentView: View {
    enum AppTab: Hashable { case home, shows, radar, watchlist }

    @State private var selection: AppTab = Self.initialTab
    @State private var homePath: [Route] = Self.initialPath

    /// DEBUG: `-debugRoute stock:NVDA` / `episode:<id>` pushes a page onto the 本週 stack.
    private static var initialPath: [Route] {
        #if DEBUG
        guard let raw = UserDefaults.standard.string(forKey: "debugRoute") else { return [] }
        let parts = raw.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return [] }
        switch parts[0] {
        case "stock": return [.stock(parts[1])]
        case "episode": return [.episode(parts[1])]
        case "show": return [.show(parts[1])]
        default: return []
        }
        #else
        return []
        #endif
    }

    /// DEBUG: `-initialTab radar` opens a specific tab; `-initialTab search` opens 本週 with search active.
    private static var debugTab: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "initialTab")
        #else
        nil
        #endif
    }

    private static var initialTab: AppTab {
        switch debugTab {
        case "shows": .shows
        case "radar": .radar
        case "watchlist": .watchlist
        default: .home
        }
    }

    /// DEBUG: `-searchQuery 博通` pre-fills the search field (UI checks).
    private static var initialQuery: String {
        #if DEBUG
        UserDefaults.standard.string(forKey: "searchQuery") ?? ""
        #else
        ""
        #endif
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab(value: AppTab.home) {
                NavigationStack(path: $homePath) {
                    WeftTabRoot(initiallySearching: Self.debugTab == "search", initialQuery: Self.initialQuery) {
                        HomeView()
                    }
                    .weftDestinations()
                }
            } label: { tabLabel("本週", systemImage: "newspaper") }
            Tab(value: AppTab.shows) {
                NavigationStack { WeftTabRoot { ShowsView() }.weftDestinations() }
            } label: { tabLabel("節目", systemImage: "mic") }
            Tab(value: AppTab.radar) {
                NavigationStack { WeftTabRoot { RadarView() }.weftDestinations() }
            } label: { tabLabel("雷達", systemImage: "chart.bar") }
            Tab(value: AppTab.watchlist) {
                NavigationStack { WeftTabRoot { WatchlistView() }.weftDestinations() }
            } label: { tabLabel("追蹤", systemImage: "star") }
        }
        .tint(WeftColor.accent)
    }

    /// Icon only on screen; the title is still read by VoiceOver.
    private func tabLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage).labelStyle(.iconOnly)
    }
}

extension View {
    /// Push destinations shared by every tab (單集 / 個股 / 節目詳情).
    func weftDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .episode(let id): EpisodeDetailView(episodeID: id)
            case .stock(let ticker): StockDetailView(ticker: ticker)
            case .show(let id): ShowDetailView(showID: id)
            }
        }
    }

    /// Standard screen padding + background used by every scrolling page.
    func weftScreen() -> some View {
        padding(.horizontal, WeftSpacing.md)
            .padding(.bottom, WeftSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView()
        .environment(WatchlistStore())
}
