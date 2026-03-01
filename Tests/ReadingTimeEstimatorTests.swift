@testable import App
import Foundation
import Testing

@Suite("ReadingTimeEstimator 読書時間推定")
struct ReadingTimeEstimatorTests {
    // MARK: - remainingMinutes

    @Test("最終ページでは残り0分")
    func lastPageReturnsZero() {
        let minutes = ReadingTimeEstimator.remainingMinutes(currentPage: 10, totalPages: 10)
        #expect(minutes == 0)
    }

    @Test("先頭ページでは残りページ数と一致")
    func firstPageReturnsTotal() {
        let minutes = ReadingTimeEstimator.remainingMinutes(currentPage: 1, totalPages: 10)
        #expect(minutes == 9)
    }

    @Test("中間ページの残り時間が正しい")
    func middlePageCalculation() {
        let minutes = ReadingTimeEstimator.remainingMinutes(currentPage: 5, totalPages: 10)
        #expect(minutes == 5)
    }

    @Test("1ページのみの場合は0分")
    func singlePageReturnsZero() {
        let minutes = ReadingTimeEstimator.remainingMinutes(currentPage: 1, totalPages: 1)
        #expect(minutes == 0)
    }

    @Test("currentPageがtotalPagesを超えても負にならない")
    func overflowPageReturnsZero() {
        let minutes = ReadingTimeEstimator.remainingMinutes(currentPage: 15, totalPages: 10)
        #expect(minutes == 0)
    }

    // MARK: - formattedRemainingTime

    @Test("残りがある場合は「約N分」と表示")
    func formatsMinutesCorrectly() {
        let text = ReadingTimeEstimator.formattedRemainingTime(currentPage: 1, totalPages: 6)
        #expect(text == "約5分")
    }

    @Test("最終ページでは「まもなく読了」と表示")
    func lastPageShowsCompletion() {
        let text = ReadingTimeEstimator.formattedRemainingTime(currentPage: 10, totalPages: 10)
        #expect(text == "まもなく読了")
    }

    @Test("残り1ページでは「約1分」と表示")
    func onePageRemaining() {
        let text = ReadingTimeEstimator.formattedRemainingTime(currentPage: 9, totalPages: 10)
        #expect(text == "約1分")
    }
}
