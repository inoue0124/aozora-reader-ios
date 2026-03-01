import SwiftUI

struct HomeScreen: View {
    @State private var viewModel = HomeViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if viewModel.isLoading {
                    loadingSection
                } else {
                    continueReadingSection
                    recommendedAuthorsSection
                    recentReviewsSection
                    workTypeShelvesSection
                }
            }
            .padding(.vertical)
            .animation(.easeOut(duration: 0.3), value: viewModel.isLoading)
        }
        .navigationTitle("ホーム")
        .navigationDestination(for: Book.self) { book in
            WorkDetailScreen(book: book)
        }
        .navigationDestination(for: Person.self) { person in
            AuthorDetailScreen(person: person)
        }
        .task {
            await viewModel.load(context: modelContext)
        }
    }

    // MARK: - Loading

    private var loadingSection: some View {
        HStack {
            Spacer()
            ProgressView("読み込み中…")
            Spacer()
        }
        .padding(.top, 40)
    }

    // MARK: - Continue Reading

    @ViewBuilder
    private var continueReadingSection: some View {
        if !viewModel.continueReadingBooks.isEmpty {
            ShelfSection(title: "続きから読む", systemImage: "bookmark.fill") {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(viewModel.continueReadingBooks, id: \.bookId) { bookmark in
                            NavigationLink {
                                BookDestinationByID(bookId: bookmark.bookId)
                            } label: {
                                ContinueReadingCard(bookmark: bookmark)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Recommended Authors

    @ViewBuilder
    private var recommendedAuthorsSection: some View {
        if !viewModel.recommendedAuthors.isEmpty {
            let title = viewModel.isFallbackAuthors ? "人気の著者" : "おすすめの著者"
            let icon = viewModel.isFallbackAuthors ? "person.2.fill" : "star.fill"
            ShelfSection(title: title, systemImage: icon) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 14) {
                        ForEach(viewModel.recommendedAuthors, id: \.personId) { author in
                            NavigationLink(value: author.person) {
                                RecommendedAuthorCard(
                                    author: author,
                                    portraitURL: viewModel.authorPortraitURLs[author.personId]
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Recent Reviews

    @ViewBuilder
    private var recentReviewsSection: some View {
        if !viewModel.recentReviews.isEmpty {
            ShelfSection(title: "最近のレビュー", systemImage: "text.bubble.fill") {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 14) {
                        ForEach(viewModel.recentReviews, id: \.bookId) { review in
                            NavigationLink {
                                BookDestinationByID(bookId: review.bookId)
                            } label: {
                                RecentReviewCard(review: review)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Work Type Shelves

    private var workTypeShelvesSection: some View {
        ForEach(viewModel.workTypeShelves) { shelf in
            ShelfSection(title: shelf.workType.displayName, systemImage: shelf.workType.iconName) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(shelf.books) { book in
                            NavigationLink(value: book) {
                                BookShelfCard(book: book)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

// MARK: - Shelf Section

private struct ShelfSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.title3.weight(.bold))
                .padding(.horizontal)

            content
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Continue Reading Card

private struct ContinueReadingCard: View {
    let bookmark: Bookmark

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BookCoverView(
                title: bookmark.title,
                authorName: bookmark.authorName,
                classification: bookmark.classification,
                width: 110,
                height: 155
            )

            Text(bookmark.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: 110, alignment: .leading)

            Text(bookmark.authorName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 110, alignment: .leading)
        }
    }
}

// MARK: - Recommended Author Card

private struct RecommendedAuthorCard: View {
    let author: RecommendedAuthor
    let portraitURL: URL?

    var body: some View {
        VStack(spacing: 10) {
            Group {
                if let url = portraitURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            fallbackPortrait
                        }
                    }
                } else {
                    fallbackPortrait
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.12), radius: 3, y: 2)

            VStack(spacing: 3) {
                Text(author.person.fullName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if let work = author.representativeWork {
                    Text(work.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(width: 110)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    private var fallbackPortrait: some View {
        ZStack {
            Circle()
                .fill(.quaternary)
            Image(systemName: "person.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Recent Review Card

private struct RecentReviewCard: View {
    let review: BookReview

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(review.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)

            StarRatingView(rating: review.rating, size: .caption)

            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)

            Text(review.authorName)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .frame(width: 160, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }
}

// MARK: - Book Shelf Card

private struct BookShelfCard: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BookCoverView(book: book, width: 110, height: 155)

            Text(book.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: 110, alignment: .leading)

            Text(book.authorName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 110, alignment: .leading)
        }
    }
}

// MARK: - Navigation Destination

private struct BookDestinationByID: View {
    let bookId: Int
    @State private var book: Book?
    @State private var hasFailed = false

    var body: some View {
        Group {
            if let book {
                WorkDetailScreen(book: book)
            } else if hasFailed {
                ContentUnavailableView("作品が見つかりません", systemImage: "book.closed")
            } else {
                ProgressView()
            }
        }
        .task {
            do {
                book = try await CatalogService.shared.book(id: bookId)
                if book == nil { hasFailed = true }
            } catch {
                hasFailed = true
            }
        }
    }
}
