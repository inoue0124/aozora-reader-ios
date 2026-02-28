import Foundation
import SwiftData

@Model
final class BookReview {
    @Attribute(.unique) var bookId: Int
    var title: String
    var authorName: String
    var rating: Int
    var comment: String
    var createdAt: Date
    var updatedAt: Date

    init(bookId: Int, title: String, authorName: String, rating: Int, comment: String) {
        self.bookId = bookId
        self.title = title
        self.authorName = authorName
        self.rating = rating
        self.comment = comment
        createdAt = .now
        updatedAt = .now
    }
}
