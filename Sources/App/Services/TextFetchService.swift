import Foundation

actor TextFetchService {
    static let shared = TextFetchService()

    private let session: URLSession
    private var cache: [Int: String] = [:]

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
    }

    func fetchText(for book: Book) async throws -> String {
        if let cached = cache[book.id] {
            return cached
        }

        guard let url = book.htmlFileURL ?? book.textFileURL else {
            throw TextFetchError.noTextURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            throw TextFetchError.fetchFailed
        }

        let encoding = detectEncoding(from: data, response: httpResponse)
        guard let text = String(data: data, encoding: encoding) else {
            throw TextFetchError.decodingFailed
        }

        cache[book.id] = text
        return text
    }

    func clearCache(for bookId: Int) {
        cache.removeValue(forKey: bookId)
    }

    func clearAllCache() {
        cache.removeAll()
    }

    private func detectEncoding(from data: Data, response: HTTPURLResponse) -> String.Encoding {
        if let contentType = response.value(forHTTPHeaderField: "Content-Type"),
           contentType.contains("Shift_JIS") || contentType.contains("shift_jis")
        {
            return .shiftJIS
        }

        let head = String(data: data.prefix(1024), encoding: .utf8) ?? ""
        if head.contains("Shift_JIS") || head.contains("shift_jis") {
            return .shiftJIS
        }

        if String(data: data, encoding: .utf8) != nil {
            return .utf8
        }

        return .shiftJIS
    }
}

enum TextFetchError: LocalizedError {
    case noTextURL
    case fetchFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .noTextURL:
            "テキストURLが見つかりません"
        case .fetchFailed:
            "テキストの取得に失敗しました"
        case .decodingFailed:
            "テキストのデコードに失敗しました"
        }
    }
}
