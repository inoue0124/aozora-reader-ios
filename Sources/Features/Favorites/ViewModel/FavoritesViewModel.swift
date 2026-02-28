import Foundation
import SwiftData

@Observable
@MainActor
final class FavoritesViewModel {
    func isFavorite(bookId: Int, context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<FavoriteBook>(
            predicate: #Predicate { $0.bookId == bookId }
        )
        return (try? context.fetchCount(descriptor)) ?? 0 > 0
    }

    func toggleFavorite(book: Book, context: ModelContext) {
        let bookId = book.id
        let descriptor = FetchDescriptor<FavoriteBook>(
            predicate: #Predicate { $0.bookId == bookId }
        )

        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        } else {
            let favorite = FavoriteBook(
                bookId: book.id,
                title: book.title,
                authorName: book.authorName,
                personId: book.personId
            )
            context.insert(favorite)
        }

        try? context.save()
    }
}
