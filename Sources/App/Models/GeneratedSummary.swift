import Foundation
import SwiftData

@Model
final class GeneratedSummary {
    @Attribute(.unique) var bookId: Int
    var summary: String
    var createdAt: Date

    init(bookId: Int, summary: String) {
        self.bookId = bookId
        self.summary = summary
        createdAt = .now
    }
}
