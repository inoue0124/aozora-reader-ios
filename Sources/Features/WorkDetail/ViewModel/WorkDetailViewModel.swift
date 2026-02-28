import Foundation

@Observable
@MainActor
final class WorkDetailViewModel {
    let book: Book
    var author: Person?
    var isLoading = false
    var errorMessage: String?

    private let catalogService = CatalogService.shared

    init(book: Book) {
        self.book = book
    }

    func loadAuthor() async {
        isLoading = true
        do {
            author = try await catalogService.person(id: book.personId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
