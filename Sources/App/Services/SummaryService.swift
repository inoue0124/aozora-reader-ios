import Foundation
import SwiftData

@Observable
@MainActor
final class SummaryService {
    static let shared = SummaryService()

    static let safetyFallback = "この作品のあらすじは現在準備中です。作品を読んでお楽しみください。"

    private var bundledSummaries: [Int: String]?
    private let qualityGuard = SummaryQualityGuard()

    private init() {}

    func summary(for bookId: Int, context: ModelContext) async -> String? {
        // 1. Fixed JSON (highest priority)
        if let bundled = try? loadBundledSummaries(), let text = bundled[bookId] {
            return applyGuard(text)
        }

        // 2. SwiftData cache
        if let cached = fetchCachedSummary(bookId: bookId, context: context) {
            return applyGuard(cached.summary)
        }

        // 3. Fallback: generate from text beginning
        if let fallback = await generateFallbackSummary(for: bookId) {
            let guarded = applyGuard(fallback)
            saveSummary(bookId: bookId, summary: guarded, context: context)
            return guarded
        }

        return nil
    }

    private func applyGuard(_ text: String) -> String {
        switch qualityGuard.validate(text) {
        case let .valid(cleaned):
            cleaned
        case .rejected:
            Self.safetyFallback
        }
    }

    private func loadBundledSummaries() throws -> [Int: String] {
        if let cached = bundledSummaries {
            return cached
        }

        guard let url = Bundle.main.url(forResource: "summaries", withExtension: "json") else {
            throw SummaryError.fileNotFound
        }

        let data = try Data(contentsOf: url)
        let entries = try JSONDecoder().decode([SummaryEntry].self, from: data)

        var map: [Int: String] = [:]
        for entry in entries {
            map[entry.bookId] = entry.summary
        }
        bundledSummaries = map
        return map
    }

    private func fetchCachedSummary(bookId: Int, context: ModelContext) -> GeneratedSummary? {
        let descriptor = FetchDescriptor<GeneratedSummary>(
            predicate: #Predicate { $0.bookId == bookId }
        )
        return try? context.fetch(descriptor).first
    }

    private func generateFallbackSummary(for bookId: Int) async -> String? {
        guard let book = try? await CatalogService.shared.book(id: bookId) else {
            return nil
        }

        guard let text = try? await TextFetchService.shared.fetchText(for: book) else {
            return nil
        }

        let parser = AozoraTextParser()
        let parsed = parser.parse(html: text)
        let plainText = String(parsed.characters)

        let trimmed = plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let maxLength = 200
        if trimmed.count <= maxLength {
            return trimmed
        }

        let endIndex = trimmed.index(trimmed.startIndex, offsetBy: maxLength)
        return String(trimmed[..<endIndex]) + "……"
    }

    private func saveSummary(bookId: Int, summary: String, context: ModelContext) {
        let existing = fetchCachedSummary(bookId: bookId, context: context)
        if let existing {
            existing.summary = summary
        } else {
            context.insert(GeneratedSummary(bookId: bookId, summary: summary))
        }
        try? context.save()
    }
}

private struct SummaryEntry: Codable, Sendable {
    let bookId: Int
    let summary: String
}

enum SummaryError: LocalizedError {
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            "あらすじデータが見つかりません"
        }
    }
}
