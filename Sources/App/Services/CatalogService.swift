import Foundation

actor CatalogService {
    static let shared = CatalogService()

    private var catalog: AozoraCatalog?
    private var bookIndex: [Int: Book] = [:]
    private var personIndex: [Int: Person] = [:]

    private init() {}

    func loadCatalog() async throws {
        if catalog != nil { return }

        guard let url = Bundle.main.url(forResource: "aozora_catalog", withExtension: "json") else {
            throw CatalogError.catalogNotFound
        }

        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(AozoraCatalog.self, from: data)
        catalog = decoded

        for book in decoded.books {
            bookIndex[book.id] = book
        }
        for person in decoded.persons {
            personIndex[person.id] = person
        }
    }

    func searchBooks(query: String) async throws -> [Book] {
        try await loadCatalog()
        guard let catalog else { throw CatalogError.catalogNotLoaded }

        let lowered = query.lowercased()
        return catalog.books.filter { book in
            book.title.lowercased().contains(lowered)
                || book.titleYomi.lowercased().contains(lowered)
                || book.authorName.lowercased().contains(lowered)
        }
    }

    func searchBooksByTitle(query: String) async throws -> [Book] {
        try await loadCatalog()
        guard let catalog else { throw CatalogError.catalogNotLoaded }

        let lowered = query.lowercased()
        return catalog.books.filter { book in
            book.title.lowercased().contains(lowered)
                || book.titleYomi.lowercased().contains(lowered)
        }
    }

    func searchBooksByAuthor(query: String) async throws -> [Book] {
        try await loadCatalog()
        guard let catalog else { throw CatalogError.catalogNotLoaded }

        let lowered = query.lowercased()
        return catalog.books.filter { book in
            book.authorName.lowercased().contains(lowered)
        }
    }

    func book(id: Int) async throws -> Book? {
        try await loadCatalog()
        return bookIndex[id]
    }

    func person(id: Int) async throws -> Person? {
        try await loadCatalog()
        return personIndex[id]
    }

    func booksByPerson(personId: Int) async throws -> [Book] {
        try await loadCatalog()
        guard let catalog else { throw CatalogError.catalogNotLoaded }
        return catalog.books.filter { $0.personId == personId }
    }
}

enum CatalogError: LocalizedError {
    case catalogNotFound
    case catalogNotLoaded

    var errorDescription: String? {
        switch self {
        case .catalogNotFound:
            "カタログデータが見つかりません"
        case .catalogNotLoaded:
            "カタログの読み込みに失敗しました"
        }
    }
}
