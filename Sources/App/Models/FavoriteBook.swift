import Foundation
import SwiftData

@Model
final class FavoriteBook {
    @Attribute(.unique) var bookId: Int
    var title: String
    var authorName: String
    var personId: Int
    var addedAt: Date

    init(bookId: Int, title: String, authorName: String, personId: Int) {
        self.bookId = bookId
        self.title = title
        self.authorName = authorName
        self.personId = personId
        self.addedAt = .now
    }
}
