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

        // Synchronous SwiftData fetches (must stay on MainActor)
        continueReadingBooks = loadContinueReading(context: context)
        recentReviews = loadRecentReviews(context: context)
        recommendedAuthors = await loadRecommendedAuthors(context: context)

        // Async load without context
        workTypeShelves = await loadWorkTypeShelves()

        isFallbackAuthors = recommendedAuthors.first?.isFallback ?? true
        isLoading = false

        // Load author portraits in background after content is shown
        await loadAuthorPortraits()
    }

    // MARK: - Private

    private func loadContinueReading(context: ModelContext) -> [Bookmark] {
        var descriptor = FetchDescriptor<Bookmark>(
            sortBy: [SortDescriptor(\.lastReadAt, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        return (try? context.fetch(descriptor)) ?? []
    }

    private func loadRecommendedAuthors(context: ModelContext) async -> [RecommendedAuthor] {
        await RecommendationService.shared.recommendAuthors(context: context)
    }

    private func loadRecentReviews(context: ModelContext) -> [BookReview] {
        var descriptor = FetchDescriptor<BookReview>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        return (try? context.fetch(descriptor)) ?? []
    }

    private func loadWorkTypeShelves() async -> [WorkTypeShelf] {
        var shelves: [WorkTypeShelf] = []
        for workType in WorkType.shelfTypes {
            let books = await (try? CatalogService.shared.booksByWorkType(workType)) ?? []
            if !books.isEmpty {
                shelves.append(WorkTypeShelf(workType: workType, books: books))
            }
        }
        return shelves
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
