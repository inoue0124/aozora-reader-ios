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

    func booksByWorkType(_ workType: WorkType, limit: Int = 20) async throws -> [Book] {
        try await loadCatalog()
        guard let catalog else { throw CatalogError.catalogNotLoaded }
        return Array(
            catalog.books
                .filter { WorkType.from(classification: $0.classification) == workType }
                .prefix(limit)
        )
    }

    func newestBooks(limit: Int = 20) async throws -> [Book] {
        try await loadCatalog()
        guard let catalog else { throw CatalogError.catalogNotLoaded }
        return Array(
            catalog.books
                .sorted { $0.releaseDate > $1.releaseDate }
                .prefix(limit)
        )
    }

    func topAuthorsByWorkCount(limit: Int = 10) async throws -> [(person: Person, workCount: Int)] {
        try await loadCatalog()
        guard let catalog else { throw CatalogError.catalogNotLoaded }

        var countByPerson: [Int: Int] = [:]
        for book in catalog.books {
            countByPerson[book.personId, default: 0] += 1
        }

        return countByPerson
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .compactMap { personId, count in
                guard let person = personIndex[personId] else { return nil }
                return (person: person, workCount: count)
            }
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
