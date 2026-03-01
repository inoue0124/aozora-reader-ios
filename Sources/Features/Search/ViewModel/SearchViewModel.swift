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
    var recentSearches: [String] = []

    private static let recentSearchesKey = "recentSearches"
    private static let maxRecentSearches = 8
    private let catalogService = CatalogService.shared

    init() {
        recentSearches = UserDefaults.standard.stringArray(forKey: Self.recentSearchesKey) ?? []
    }

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
            addToRecentSearches(trimmed)
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }

        isLoading = false
    }

    func removeRecentSearch(_ keyword: String) {
        recentSearches.removeAll { $0 == keyword }
        UserDefaults.standard.set(recentSearches, forKey: Self.recentSearchesKey)
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: Self.recentSearchesKey)
    }

    private func addToRecentSearches(_ keyword: String) {
        recentSearches.removeAll { $0 == keyword }
        recentSearches.insert(keyword, at: 0)
        if recentSearches.count > Self.maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(Self.maxRecentSearches))
        }
        UserDefaults.standard.set(recentSearches, forKey: Self.recentSearchesKey)
    }
}
