import Foundation
import SwiftData

@Observable
@MainActor
final class WorkDetailViewModel {
    let book: Book
    var author: Person?
    var summary: String?
    var isLoading = false
    var isSummaryLoading = false
    var hasReadingProgress = false
    var errorMessage: String?

    private let catalogService = CatalogService.shared
    private let summaryService = SummaryService.shared

    init(book: Book) {
        self.book = book
    }

    func loadAuthor() async {
        isLoading = true
        do {
            author = try await catalogService.person(id: book.personId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func checkReadingProgress(context: ModelContext) {
        let bookId = book.id
        let descriptor = FetchDescriptor<Bookmark>(
            predicate: #Predicate { $0.bookId == bookId }
        )
        hasReadingProgress = (try? context.fetch(descriptor).first) != nil
    }

    func loadSummary(context: ModelContext) async {
        isSummaryLoading = true
        summary = await summaryService.summary(for: book.id, context: context)
        isSummaryLoading = false
    }
}
