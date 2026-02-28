import Foundation

actor TextFetchService {
    static let shared = TextFetchService()

    private let session: URLSession
    private var memoryCache: [Int: String] = [:]
    private let cacheDirectory: URL

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)

        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("AozoraTexts", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func fetchText(for book: Book) async throws -> String {
        if let cached = memoryCache[book.id] {
            return cached
        }

        if let diskCached = loadFromDisk(bookId: book.id) {
            memoryCache[book.id] = diskCached
            return diskCached
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

        memoryCache[book.id] = text
        saveToDisk(bookId: book.id, text: text)
        return text
    }

    func isCached(bookId: Int) -> Bool {
        memoryCache[bookId] != nil || FileManager.default.fileExists(atPath: cacheFile(for: bookId).path)
    }

    func deleteCachedText(bookId: Int) {
        memoryCache.removeValue(forKey: bookId)
        let file = cacheFile(for: bookId)
        try? FileManager.default.removeItem(at: file)
    }

    func clearAllCache() {
        memoryCache.removeAll()
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func cachedBookIds() -> Set<Int> {
        var ids = Set(memoryCache.keys)
        if let files = try? FileManager.default.contentsOfDirectory(atPath: cacheDirectory.path) {
            for file in files where file.hasSuffix(".txt") {
                if let id = Int(file.replacingOccurrences(of: ".txt", with: "")) {
                    ids.insert(id)
                }
            }
        }
        return ids
    }

    private func cacheFile(for bookId: Int) -> URL {
        cacheDirectory.appendingPathComponent("\(bookId).txt")
    }

    private func saveToDisk(bookId: Int, text: String) {
        let file = cacheFile(for: bookId)
        try? text.write(to: file, atomically: true, encoding: .utf8)
    }

    private func loadFromDisk(bookId: Int) -> String? {
        let file = cacheFile(for: bookId)
        return try? String(contentsOf: file, encoding: .utf8)
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
    case offline

    var errorDescription: String? {
        switch self {
        case .noTextURL:
            "テキストURLが見つかりません"
        case .fetchFailed:
            "テキストの取得に失敗しました"
        case .decodingFailed:
            "テキストのデコードに失敗しました"
        case .offline:
            "オフラインです。この作品はまだダウンロードされていません"
        }
    }
}
