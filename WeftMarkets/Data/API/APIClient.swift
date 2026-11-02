import Foundation

/// Talks to the Weft BFF (weft-bff). The app never calls the Narrative API directly:
/// the API key lives only on the BFF.
struct APIClient {
    /// nil when this build has no server address; every call then throws `.notConfigured`.
    let baseURL: URL?
    var session: URLSession = .shared

    // MARK: Server address

    /// Release builds point at the deployed BFF. Leave nil until it exists, so a release
    /// build shows "not configured" instead of silently using mock data.
    static let productionBaseURL: URL? = nil

    /// Debug: the BFF on this Mac (`npm start` in weft-bff). The simulator shares the
    /// Mac's network, so 127.0.0.1 works. For a real device use
    /// `-apiBaseURL http://<Mac 的區網 IP>:8787` as a launch argument.
    static var configuredBaseURL: URL? {
        #if DEBUG
        if let override = UserDefaults.standard.string(forKey: "apiBaseURL") { return URL(string: override) }
        return URL(string: "http://127.0.0.1:8787")
        #else
        return productionBaseURL
        #endif
    }

    // MARK: Requests

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    /// GET `path` (e.g. "v1/shows") and decode the JSON body.
    func get<T: Decodable>(_ path: String, query: [String: String?] = [:], timeout: TimeInterval = 20) async throws -> T {
        guard let baseURL else { throw RepositoryError.notConfigured }
        var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false)
        let items = query.compactMap { key, value in value.map { URLQueryItem(name: key, value: $0) } }
        if !items.isEmpty { components?.queryItems = items }
        guard let url = components?.url else { throw RepositoryError.notFound }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            throw RepositoryError.unavailable
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let code = (try? Self.decoder.decode(ErrorBody.self, from: data))?.error.code
            throw Self.repositoryError(status: status, code: code)
        }
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[APIClient] decode \(T.self) from \(path) failed:", error)
            #endif
            throw RepositoryError.unavailable
        }
    }

    /// Maps the BFF's `{ error: { code } }` to what the screens show.
    static func repositoryError(status: Int, code: String?) -> RepositoryError {
        switch code {
        case "rate_limited": return .rateLimited
        case "cursor_expired", "invalid_cursor": return .cursorExpired
        case "not_configured": return .unavailable
        case let code? where code.hasSuffix("_not_found") || code == "not_found": return .notFound
        default: return status == 404 ? .notFound : .unavailable
        }
    }

    struct ErrorBody: Decodable {
        struct Code: Decodable { let code: String }
        let error: Code
    }
}

/// One block of a multi-block screen: `{ data }` or `{ error: { code } }`.
/// A failed block is hidden on screen rather than failing the whole page.
struct APISection<T: Decodable>: Decodable {
    let data: T?
    let error: APIClient.ErrorBody.Code?
}
