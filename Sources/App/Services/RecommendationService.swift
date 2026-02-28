import Foundation
import SwiftData

struct RecommendedAuthor: Sendable {
    let personId: Int
    let person: Person
    let score: Double
    let representativeWork: Book?
    let isFallback: Bool
}

@MainActor
@Observable
final class RecommendationService {
    static let shared = RecommendationService()

    private init() {}

    /// おすすめ著者を算出する（レビュー・閲覧履歴ベース）
    func recommendAuthors(
        context: ModelContext,
        limit: Int = 10
    ) async -> [RecommendedAuthor] {
        let histories = fetchAllHistory(context: context)
        let reviews = fetchAllReviews(context: context)

        // コールドスタート: 履歴 + レビュー合計 3 件未満 → フォールバック
        if histories.count + reviews.count < 3 {
            return await fallbackAuthors(limit: limit)
        }

        let topClassification = mostViewedClassification(histories: histories)
        var authorScores: [Int: Double] = [:]
        var latestInteraction: [Int: Date] = [:]

        accumulateHistoryScores(
            histories,
            topClassification: topClassification,
            scores: &authorScores,
            latest: &latestInteraction
        )
        await accumulateReviewScores(reviews, scores: &authorScores, latest: &latestInteraction)
        await penalizeFullyViewedAuthors(histories: histories, scores: &authorScores)
        applyRecencyDecay(scores: &authorScores, latestInteraction: latestInteraction)

        return await buildResults(from: authorScores, limit: limit)
    }

    // MARK: - Scoring

    private func accumulateHistoryScores(
        _ histories: [ReadingHistory],
        topClassification: String,
        scores: inout [Int: Double],
        latest: inout [Int: Date]
    ) {
        for history in histories {
            let pid = history.authorPersonId
            let viewScore = Double(min(history.viewCount, 5))
            let bonus: Double = (history.classification == topClassification) ? 2.0 : 0
            scores[pid, default: 0] += viewScore + bonus
            updateLatest(&latest, personId: pid, date: history.lastViewedAt)
        }
    }

    private func accumulateReviewScores(
        _ reviews: [BookReview],
        scores: inout [Int: Double],
        latest: inout [Int: Date]
    ) async {
        for review in reviews {
            guard let book = try? await CatalogService.shared.book(id: review.bookId) else { continue }
            scores[book.personId, default: 0] += Double(review.rating) * 3.0
            updateLatest(&latest, personId: book.personId, date: review.updatedAt)
        }
    }

    private func penalizeFullyViewedAuthors(
        histories: [ReadingHistory],
        scores: inout [Int: Double]
    ) async {
        for personId in scores.keys {
            let allWorks = await (try? CatalogService.shared.booksByPerson(personId: personId)) ?? []
            let viewedCount = histories.count { $0.authorPersonId == personId }
            if !allWorks.isEmpty, viewedCount >= allWorks.count {
                scores[personId]! *= 0.3
            }
        }
    }

    private func applyRecencyDecay(scores: inout [Int: Double], latestInteraction: [Int: Date]) {
        let now = Date.now
        for (personId, lastDate) in latestInteraction {
            let days = now.timeIntervalSince(lastDate) / 86400
            let decay = max(0.5, 1.0 - days / 90.0)
            scores[personId]! *= decay
        }
    }

    private func updateLatest(_ latest: inout [Int: Date], personId: Int, date: Date) {
        if let current = latest[personId] {
            if date > current { latest[personId] = date }
        } else {
            latest[personId] = date
        }
    }

    // MARK: - Results

    private func buildResults(from scores: [Int: Double], limit: Int) async -> [RecommendedAuthor] {
        let sorted = scores.sorted { $0.value > $1.value }.prefix(limit)
        var results: [RecommendedAuthor] = []
        for (personId, score) in sorted {
            guard let person = try? await CatalogService.shared.person(id: personId) else { continue }
            let works = try? await CatalogService.shared.booksByPerson(personId: personId)
            results.append(RecommendedAuthor(
                personId: personId,
                person: person,
                score: score,
                representativeWork: works?.first,
                isFallback: false
            ))
        }
        return results
    }

    // MARK: - Data Access

    private func fetchAllHistory(context: ModelContext) -> [ReadingHistory] {
        let descriptor = FetchDescriptor<ReadingHistory>()
        return (try? context.fetch(descriptor)) ?? []
    }

    private func fetchAllReviews(context: ModelContext) -> [BookReview] {
        let descriptor = FetchDescriptor<BookReview>()
        return (try? context.fetch(descriptor)) ?? []
    }

    private func mostViewedClassification(histories: [ReadingHistory]) -> String {
        var counts: [String: Int] = [:]
        for history in histories where !history.classification.isEmpty {
            counts[history.classification, default: 0] += history.viewCount
        }
        return counts.max { $0.value < $1.value }?.key ?? ""
    }

    private func fallbackAuthors(limit: Int) async -> [RecommendedAuthor] {
        guard let topAuthors = try? await CatalogService.shared.topAuthorsByWorkCount(limit: limit) else {
            return []
        }
        var results: [RecommendedAuthor] = []
        for entry in topAuthors {
            let works = try? await CatalogService.shared.booksByPerson(personId: entry.person.id)
            results.append(RecommendedAuthor(
                personId: entry.person.id,
                person: entry.person,
                score: Double(entry.workCount),
                representativeWork: works?.first,
                isFallback: true
            ))
        }
        return results
    }
}
