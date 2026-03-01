@testable import App
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("RecommendationService スコアリング")
struct RecommendationServiceTests {
    private let service = RecommendationService.shared

    // MARK: - mostViewedClassification

    @Test("最頻分類: viewCount 合計が最大の分類を返す")
    func mostViewedClassificationReturnsTop() {
        let histories = [
            makeHistory(bookId: 1, classification: "短編", viewCount: 3),
            makeHistory(bookId: 2, classification: "長編", viewCount: 1),
            makeHistory(bookId: 3, classification: "短編", viewCount: 2),
        ]
        let result = service.mostViewedClassification(histories: histories)
        #expect(result == "短編") // 3 + 2 = 5 > 1
    }

    @Test("最頻分類: 履歴なしで空文字")
    func mostViewedClassificationEmptyForNoHistory() {
        let result = service.mostViewedClassification(histories: [])
        #expect(result.isEmpty)
    }

    @Test("最頻分類: 空文字の分類は無視される")
    func mostViewedClassificationIgnoresEmptyClassification() {
        let histories = [
            makeHistory(bookId: 1, classification: "", viewCount: 10),
            makeHistory(bookId: 2, classification: "短編", viewCount: 1),
        ]
        let result = service.mostViewedClassification(histories: histories)
        #expect(result == "短編")
    }

    // MARK: - accumulateHistoryScores

    @Test("履歴スコア: viewCount + 分類ボーナスが加算される")
    func historyScoresAccumulateCorrectly() {
        let histories = [
            makeHistory(bookId: 1, authorPersonId: 100, classification: "短編", viewCount: 3),
            makeHistory(bookId: 2, authorPersonId: 100, classification: "長編", viewCount: 2),
            makeHistory(bookId: 3, authorPersonId: 200, classification: "短編", viewCount: 1),
        ]
        var scores: [Int: Double] = [:]
        var latest: [Int: Date] = [:]

        service.accumulateHistoryScores(
            histories,
            topClassification: "短編",
            scores: &scores,
            latest: &latest
        )

        // Person 100: viewScore(3) + bonus(2) + viewScore(2) + bonus(0) = 7
        #expect(scores[100] == 7)
        // Person 200: viewScore(1) + bonus(2) = 3
        #expect(scores[200] == 3)
    }

    @Test("履歴スコア: viewCount は5で頭打ち")
    func historyScoresCapsViewCountAt5() {
        let histories = [
            makeHistory(bookId: 1, authorPersonId: 100, classification: "短編", viewCount: 10),
        ]
        var scores: [Int: Double] = [:]
        var latest: [Int: Date] = [:]

        service.accumulateHistoryScores(
            histories,
            topClassification: "長編",
            scores: &scores,
            latest: &latest
        )

        // min(10, 5) = 5, no classification bonus
        #expect(scores[100] == 5)
    }

    @Test("履歴スコア: 同一著者の複数作品で累積される")
    func historyScoresAccumulateAcrossWorks() {
        let histories = [
            makeHistory(bookId: 1, authorPersonId: 100, classification: "短編", viewCount: 2),
            makeHistory(bookId: 2, authorPersonId: 100, classification: "短編", viewCount: 3),
        ]
        var scores: [Int: Double] = [:]
        var latest: [Int: Date] = [:]

        service.accumulateHistoryScores(
            histories,
            topClassification: "短編",
            scores: &scores,
            latest: &latest
        )

        // (2 + 2) + (3 + 2) = 9
        #expect(scores[100] == 9)
    }

    @Test("履歴スコア: latestInteraction が最新日付で更新される")
    func historyScoresTrackLatestInteraction() {
        let earlier = Date(timeIntervalSince1970: 1000)
        let later = Date(timeIntervalSince1970: 2000)
        let h1 = makeHistory(bookId: 1, authorPersonId: 100, classification: "", viewCount: 1)
        h1.lastViewedAt = earlier
        let h2 = makeHistory(bookId: 2, authorPersonId: 100, classification: "", viewCount: 1)
        h2.lastViewedAt = later

        var scores: [Int: Double] = [:]
        var latest: [Int: Date] = [:]

        service.accumulateHistoryScores(
            [h1, h2],
            topClassification: "",
            scores: &scores,
            latest: &latest
        )

        #expect(latest[100] == later)
    }

    // MARK: - applyRecencyDecay

    @Test("経過減衰: 直近はほぼ減衰なし、45日で50%")
    func recencyDecayAppliesCorrectly() throws {
        let now = Date.now
        var scores: [Int: Double] = [100: 10.0, 200: 10.0]
        let latestInteraction: [Int: Date] = [
            100: now,
            200: now.addingTimeInterval(-45 * 86400),
        ]

        service.applyRecencyDecay(scores: &scores, latestInteraction: latestInteraction)

        #expect(try #require(scores[100]) > 9.9) // ~10.0
        #expect(scores[200] == 5.0) // 10.0 * 0.5
    }

    @Test("経過減衰: 90日超でも50%が下限")
    func recencyDecayFlooredAt50Percent() {
        let now = Date.now
        var scores = [100: 10.0]
        let latestInteraction: [Int: Date] = [
            100: now.addingTimeInterval(-365 * 86400),
        ]

        service.applyRecencyDecay(scores: &scores, latestInteraction: latestInteraction)

        #expect(scores[100] == 5.0) // max(0.5, 1.0 - 365/90) = 0.5
    }

    @Test("経過減衰: 30日で約66%維持")
    func recencyDecayAt30Days() throws {
        let now = Date.now
        var scores = [100: 9.0]
        let latestInteraction: [Int: Date] = [
            100: now.addingTimeInterval(-30 * 86400),
        ]

        service.applyRecencyDecay(scores: &scores, latestInteraction: latestInteraction)

        // max(0.5, 1.0 - 30/90) = max(0.5, 0.667) = 0.667
        let expected = 9.0 * (1.0 - 30.0 / 90.0)
        #expect(try abs(#require(scores[100]) - expected) < 0.01)
    }

    // MARK: - Cold Start (統合)

    @Test("コールドスタート: 履歴+レビュー 3件未満でフォールバック")
    func coldStartReturnsFallback() async throws {
        let container = try makeContainer()
        let context = container.mainContext

        // 2件だけ挿入（< 3 → cold start）
        context.insert(ReadingHistory(
            bookId: 1,
            authorPersonId: 1,
            title: "本A",
            authorName: "著者A",
            classification: "短編"
        ))
        try context.save()

        let result = await service.recommendAuthors(context: context)
        // フォールバック結果は isFallback == true
        for author in result {
            #expect(author.isFallback == true)
        }
    }

    @Test("コールドスタート: 履歴0件・レビュー0件でフォールバック")
    func coldStartEmptyDataReturnsFallback() async throws {
        let container = try makeContainer()
        let result = await service.recommendAuthors(context: container.mainContext)
        for author in result {
            #expect(author.isFallback == true)
        }
    }

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Bookmark.self,
            BookReview.self,
            ReadingHistory.self,
            FavoriteBook.self,
            GeneratedSummary.self,
            configurations: config
        )
    }

    private func makeHistory(
        bookId: Int,
        authorPersonId: Int = 1,
        classification: String = "",
        viewCount: Int = 1
    ) -> ReadingHistory {
        let history = ReadingHistory(
            bookId: bookId,
            authorPersonId: authorPersonId,
            title: "本\(bookId)",
            authorName: "著者",
            classification: classification
        )
        history.viewCount = viewCount
        return history
    }
}
