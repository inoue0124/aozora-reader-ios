import Foundation
import SwiftData

@Observable
@MainActor
final class HomeViewModel {
    var continueReadingBooks: [Bookmark] = []
    var recommendedAuthors: [RecommendedAuthor] = []
    var recentReviews: [BookReview] = []
    var workTypeShelves: [WorkTypeShelf] = []
    var authorPortraitURLs: [Int: URL] = [:]
    var isLoading = false
    var isFallbackAuthors = false

    func load(context: ModelContext) async {
        isLoading = true

        // Fast synchronous SwiftData fetches → show immediately
        continueReadingBooks = loadContinueReading(context: context)
        recentReviews = loadRecentReviews(context: context)
        isLoading = false

        // Start shelf loading concurrently (no context needed)
        async let shelvesTask = loadWorkTypeShelves()

        // Authors need context — run while shelves load in parallel
        recommendedAuthors = await loadRecommendedAuthors(context: context)
        isFallbackAuthors = recommendedAuthors.first?.isFallback ?? true

        workTypeShelves = await shelvesTask

        // Load author portraits in background after content is shown
        await loadAuthorPortraits()
    }

    // MARK: - Internal (testable)

    func loadContinueReading(context: ModelContext) -> [Bookmark] {
        var descriptor = FetchDescriptor<Bookmark>(
            sortBy: [SortDescriptor(\.lastReadAt, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        return (try? context.fetch(descriptor)) ?? []
    }

    private func loadRecommendedAuthors(context: ModelContext) async -> [RecommendedAuthor] {
        await RecommendationService.shared.recommendAuthors(context: context)
    }

    func loadRecentReviews(context: ModelContext) -> [BookReview] {
        var descriptor = FetchDescriptor<BookReview>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        return (try? context.fetch(descriptor)) ?? []
    }

    private func loadWorkTypeShelves() async -> [WorkTypeShelf] {
        let shelfTypes = WorkType.shelfTypes
        return await withTaskGroup(of: (Int, WorkTypeShelf?).self) { group in
            for (index, workType) in shelfTypes.enumerated() {
                group.addTask {
                    let books = await (try? CatalogService.shared.booksByWorkType(workType)) ?? []
                    let shelf = books.isEmpty ? nil : WorkTypeShelf(workType: workType, books: books)
                    return (index, shelf)
                }
            }
            var indexed: [(Int, WorkTypeShelf)] = []
            for await (index, shelf) in group {
                if let shelf {
                    indexed.append((index, shelf))
                }
            }
            return indexed.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    private func loadAuthorPortraits() async {
        await withTaskGroup(of: (Int, URL?).self) { group in
            for author in recommendedAuthors {
                group.addTask {
                    let url = await AuthorPortraitService.shared.portraitURL(for: author.person)
                    return (author.personId, url)
                }
            }
            for await (personId, url) in group {
                if let url {
                    authorPortraitURLs[personId] = url
                }
            }
        }
    }
}

struct WorkTypeShelf: Identifiable, Sendable {
    let workType: WorkType
    let books: [Book]
    var id: String {
        workType.rawValue
    }
}
