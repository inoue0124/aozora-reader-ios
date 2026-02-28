import Foundation
import SwiftData

@Observable
@MainActor
final class HomeViewModel {
    var continueReadingBooks: [Bookmark] = []
    var recommendedAuthors: [RecommendedAuthor] = []
    var recentReviews: [BookReview] = []
    var workTypeShelves: [WorkTypeShelf] = []
    var newestBooks: [Book] = []
    var isLoading = false
    var isFallbackAuthors = false

    func load(context: ModelContext) async {
        isLoading = true

        // Synchronous SwiftData fetches (must stay on MainActor)
        continueReadingBooks = loadContinueReading(context: context)
        recentReviews = loadRecentReviews(context: context)
        recommendedAuthors = await loadRecommendedAuthors(context: context)

        // Async loads without context in parallel
        async let shelves = loadWorkTypeShelves()
        async let newest = loadNewestBooks()
        workTypeShelves = await shelves
        newestBooks = await newest

        isFallbackAuthors = recommendedAuthors.first?.isFallback ?? true
        isLoading = false
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
            let books = (try? await CatalogService.shared.booksByWorkType(workType)) ?? []
            if !books.isEmpty {
                shelves.append(WorkTypeShelf(workType: workType, books: books))
            }
        }
        return shelves
    }

    private func loadNewestBooks() async -> [Book] {
        (try? await CatalogService.shared.newestBooks()) ?? []
    }
}

struct WorkTypeShelf: Identifiable {
    let workType: WorkType
    let books: [Book]
    var id: String { workType.rawValue }
}
