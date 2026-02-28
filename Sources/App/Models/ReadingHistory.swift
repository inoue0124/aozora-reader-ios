import Foundation
import SwiftData

@Model
final class ReadingHistory {
    @Attribute(.unique) var bookId: Int
    var authorPersonId: Int
    var title: String
    var authorName: String
    var classification: String
    var viewCount: Int
    var lastViewedAt: Date

    init(
        bookId: Int,
        authorPersonId: Int,
        title: String,
        authorName: String,
        classification: String
    ) {
        self.bookId = bookId
        self.authorPersonId = authorPersonId
        self.title = title
        self.authorName = authorName
        self.classification = classification
        viewCount = 1
        lastViewedAt = .now
    }
}
