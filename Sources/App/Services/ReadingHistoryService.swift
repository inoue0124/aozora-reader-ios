import Foundation
import SwiftData

@MainActor
@Observable
final class ReadingHistoryService {
    static let shared = ReadingHistoryService()

    private init() {}

    func recordView(book: Book, context: ModelContext) {
        let bookId = book.id
        let descriptor = FetchDescriptor<ReadingHistory>(
            predicate: #Predicate { $0.bookId == bookId }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.viewCount += 1
            existing.lastViewedAt = .now
        } else {
            let history = ReadingHistory(
                bookId: book.id,
                authorPersonId: book.personId,
                title: book.title,
                authorName: book.authorName,
                classification: book.classification
            )
            context.insert(history)
        }

        try? context.save()
    }

    func allHistory(context: ModelContext) -> [ReadingHistory] {
        let descriptor = FetchDescriptor<ReadingHistory>(
            sortBy: [SortDescriptor(\.lastViewedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func historyForAuthor(personId: Int, context: ModelContext) -> [ReadingHistory] {
        let descriptor = FetchDescriptor<ReadingHistory>(
            predicate: #Predicate { $0.authorPersonId == personId }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
