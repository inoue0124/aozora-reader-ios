import Foundation
import SwiftData

@Observable
@MainActor
final class ReviewViewModel {
    var rating: Int = 0
    var comment: String = ""
    var existingReview: BookReview?

    func loadReview(bookId: Int, context: ModelContext) {
        let descriptor = FetchDescriptor<BookReview>(
            predicate: #Predicate { $0.bookId == bookId }
        )
        if let review = try? context.fetch(descriptor).first {
            existingReview = review
            rating = review.rating
            comment = review.comment
        }
    }

    func saveReview(book: Book, context: ModelContext) {
        if let existing = existingReview {
            existing.rating = rating
            existing.comment = comment
            existing.updatedAt = .now
        } else {
            let review = BookReview(
                bookId: book.id,
                title: book.title,
                authorName: book.authorName,
                rating: rating,
                comment: comment
            )
            context.insert(review)
            existingReview = review
        }
        try? context.save()
    }

    func deleteReview(context: ModelContext) {
        if let existing = existingReview {
            context.delete(existing)
            try? context.save()
            existingReview = nil
            rating = 0
            comment = ""
        }
    }
}
