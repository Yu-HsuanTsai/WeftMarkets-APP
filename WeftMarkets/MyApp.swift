import SwiftUI

@main struct MyApp: App {
    @State private var watchlist = WatchlistStore()
    @State private var isLaunching = true
    // Swap for the real API client once it is available.
    private let repository: any WeftRepository = MockWeftRepository()

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                if isLaunching {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .environment(watchlist)
            .environment(\.repository, repository)
            .task { await finishLaunch() }
        }
    }

    /// Keeps the splash up until the first weekly summary has loaded (at least 0.8s,
    /// so it doesn't flash). Errors still dismiss it; 本週 shows its own error state.
    private func finishLaunch() async {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "holdSplash") { return }
        #endif
        let start = ContinuousClock.now
        _ = try? await repository.weeklySummary()
        try? await Task.sleep(until: start + .milliseconds(800))
        withAnimation(.easeOut(duration: 0.3)) { isLaunching = false }
    }
}
