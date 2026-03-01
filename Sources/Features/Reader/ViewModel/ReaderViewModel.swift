import Foundation
import SwiftData

@Observable
@MainActor
final class ReaderViewModel {
    let book: Book
    var content: AttributedString?
    var isLoading = false
    var errorMessage: String?
    var savedScrollOffset: Double = 0

    private let textFetchService = TextFetchService.shared
    private let parser = AozoraTextParser()

    init(book: Book) {
        self.book = book
    }

    func loadContent() async {
        isLoading = true
        errorMessage = nil

        do {
            let html = try await textFetchService.fetchText(for: book)
            let parsed = parser.parse(html: html)

            if parsed.characters.isEmpty {
                errorMessage = "本文を表示できませんでした（データが空です）"
                content = nil
            } else {
                content = parsed
            }
        } catch {
            errorMessage = error.localizedDescription
            content = nil
        }

        isLoading = false
    }

    func loadBookmark(context: ModelContext) {
        let bookId = book.id
        let descriptor = FetchDescriptor<Bookmark>(
            predicate: #Predicate { $0.bookId == bookId }
        )
        if let bookmark = try? context.fetch(descriptor).first {
            savedScrollOffset = bookmark.scrollOffset
        }
    }

    func saveBookmark(scrollOffset: Double, context: ModelContext) {
        let bookId = book.id
        let descriptor = FetchDescriptor<Bookmark>(
            predicate: #Predicate { $0.bookId == bookId }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.scrollOffset = scrollOffset
            existing.lastReadAt = .now
        } else {
            let bookmark = Bookmark(
                bookId: book.id,
                title: book.title,
                authorName: book.authorName,
                classification: book.classification,
                scrollOffset: scrollOffset
            )
            context.insert(bookmark)
        }

        try? context.save()
    }
}
