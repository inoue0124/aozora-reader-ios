import Foundation

@Observable
@MainActor
final class ReaderViewModel {
    let book: Book
    var content: AttributedString?
    var isLoading = false
    var errorMessage: String?

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
            content = parser.parse(html: html)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
