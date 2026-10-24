import SwiftUI
import UniformTypeIdentifiers

/// 本機追蹤: tracked tickers and read episodes live only on this device,
/// mirroring the website's browser-only watchlist (no account, no cloud copy).
@Observable
final class WatchlistStore {
    struct Snapshot: Codable, Equatable {
        var trackedTickers: [String] = []
        var readEpisodeIDs: [String] = []
    }

    private(set) var snapshot: Snapshot
    private let defaults: UserDefaults
    private let key = "weft.watchlist.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            snapshot = decoded
        } else {
            snapshot = Snapshot()
        }
    }

    var trackedTickers: [String] { snapshot.trackedTickers }

    func isTracked(_ ticker: String) -> Bool { snapshot.trackedTickers.contains(ticker) }
    func isRead(_ episodeID: String) -> Bool { snapshot.readEpisodeIDs.contains(episodeID) }

    func toggleTracked(_ ticker: String) {
        if let index = snapshot.trackedTickers.firstIndex(of: ticker) {
            snapshot.trackedTickers.remove(at: index)
        } else {
            snapshot.trackedTickers.append(ticker)
        }
        save()
    }

    func toggleRead(_ episodeID: String) {
        if let index = snapshot.readEpisodeIDs.firstIndex(of: episodeID) {
            snapshot.readEpisodeIDs.remove(at: index)
        } else {
            snapshot.readEpisodeIDs.append(episodeID)
        }
        save()
    }

    func replace(with imported: Snapshot) {
        snapshot = imported
        save()
    }

    func clear() {
        snapshot = Snapshot()
        defaults.removeObject(forKey: key)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: key)
        }
    }
}

/// JSON document used by 匯出 / 匯入 JSON (fileExporter / fileImporter).
struct WatchlistDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var snapshot: WatchlistStore.Snapshot

    init(snapshot: WatchlistStore.Snapshot) {
        self.snapshot = snapshot
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        snapshot = try JSONDecoder().decode(WatchlistStore.Snapshot.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return FileWrapper(regularFileWithContents: try encoder.encode(snapshot))
    }
}
