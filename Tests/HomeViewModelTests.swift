@testable import App
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("HomeViewModel 棚構築ロジック")
struct HomeViewModelTests {
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

    // MARK: - Continue Reading

    @Test("読書中の棚: ブックマークを lastReadAt 降順で返す")
    func continueReadingSortedByLastReadDesc() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let b1 = Bookmark(bookId: 1, title: "古い本", authorName: "著者A", scrollOffset: 0)
        b1.lastReadAt = Date(timeIntervalSince1970: 1000)
        let b2 = Bookmark(bookId: 2, title: "新しい本", authorName: "著者B", scrollOffset: 0)
        b2.lastReadAt = Date(timeIntervalSince1970: 2000)
        context.insert(b1)
        context.insert(b2)
        try context.save()

        let vm = HomeViewModel()
        let result = vm.loadContinueReading(context: context)

        #expect(result.count == 2)
        #expect(result[0].bookId == 2)
        #expect(result[1].bookId == 1)
    }

    @Test("読書中の棚: 上限10件")
    func continueReadingLimitsTo10() throws {
        let container = try makeContainer()
        let context = container.mainContext

        for i in 1 ... 15 {
            let bookmark = Bookmark(bookId: i, title: "本\(i)", authorName: "著者", scrollOffset: 0)
            bookmark.lastReadAt = Date(timeIntervalSince1970: Double(i) * 1000)
            context.insert(bookmark)
        }
        try context.save()

        let vm = HomeViewModel()
        let result = vm.loadContinueReading(context: context)

        #expect(result.count == 10)
    }

    @Test("読書中の棚: ブックマーク0件で空配列")
    func continueReadingEmptyWhenNoBookmarks() throws {
        let container = try makeContainer()
        let vm = HomeViewModel()
        let result = vm.loadContinueReading(context: container.mainContext)
        #expect(result.isEmpty)
    }

    // MARK: - Recent Reviews

    @Test("レビュー棚: updatedAt 降順で返す")
    func recentReviewsSortedByUpdatedAtDesc() throws {
        let container = try makeContainer()
        let context = container.mainContext

        let r1 = BookReview(bookId: 1, title: "本A", authorName: "著者A", rating: 4, comment: "良い")
        r1.updatedAt = Date(timeIntervalSince1970: 1000)
        let r2 = BookReview(bookId: 2, title: "本B", authorName: "著者B", rating: 5, comment: "最高")
        r2.updatedAt = Date(timeIntervalSince1970: 2000)
        context.insert(r1)
        context.insert(r2)
        try context.save()

        let vm = HomeViewModel()
        let result = vm.loadRecentReviews(context: context)

        #expect(result.count == 2)
        #expect(result[0].bookId == 2)
        #expect(result[1].bookId == 1)
    }

    @Test("レビュー棚: 上限10件")
    func recentReviewsLimitsTo10() throws {
        let container = try makeContainer()
        let context = container.mainContext

        for i in 1 ... 15 {
            let review = BookReview(bookId: i, title: "本\(i)", authorName: "著者", rating: 3, comment: "普通")
            review.updatedAt = Date(timeIntervalSince1970: Double(i) * 1000)
            context.insert(review)
        }
        try context.save()

        let vm = HomeViewModel()
        let result = vm.loadRecentReviews(context: context)

        #expect(result.count == 10)
    }

    @Test("レビュー棚: レビュー0件で空配列")
    func recentReviewsEmptyWhenNoReviews() throws {
        let container = try makeContainer()
        let vm = HomeViewModel()
        let result = vm.loadRecentReviews(context: container.mainContext)
        #expect(result.isEmpty)
    }
}
