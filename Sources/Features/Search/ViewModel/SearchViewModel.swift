import Foundation

enum SearchMode: String, CaseIterable, Sendable {
    case title = "タイトル"
    case author = "著者"
}

@Observable
@MainActor
final class SearchViewModel {
    var query = ""
    var searchMode: SearchMode = .title
    var results: [Book] = []
    var isLoading = false
    var hasSearched = false
    var errorMessage: String?

    private let catalogService = CatalogService.shared

    func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            hasSearched = false
            return
        }

        isLoading = true
        errorMessage = nil
        hasSearched = true

        do {
            switch searchMode {
            case .title:
                results = try await catalogService.searchBooksByTitle(query: trimmed)
            case .author:
                results = try await catalogService.searchBooksByAuthor(query: trimmed)
            }
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }

        isLoading = false
    }
}
