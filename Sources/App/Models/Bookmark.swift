import Foundation
import SwiftData

@Model
final class Bookmark {
    @Attribute(.unique) var bookId: Int
    var title: String
    var authorName: String
    var classification: String
    var scrollOffset: Double
    var lastReadAt: Date

    init(bookId: Int, title: String, authorName: String, classification: String = "", scrollOffset: Double) {
        self.bookId = bookId
        self.title = title
        self.authorName = authorName
        self.classification = classification
        self.scrollOffset = scrollOffset
        lastReadAt = .now
    }
}
