import SwiftUI

struct HomeScreen: View {
    @State private var viewModel = HomeViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
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
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.continueReadingBooks, id: \.bookId) { bookmark in
                            NavigationLink {
                                BookmarkDestination(bookmark: bookmark)
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
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.recommendedAuthors, id: \.personId) { author in
                            NavigationLink(value: author.person) {
                                RecommendedAuthorCard(author: author)
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
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.recentReviews, id: \.bookId) { review in
                            NavigationLink {
                                ReviewBookDestination(review: review)
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

    @ViewBuilder
    private var workTypeShelvesSection: some View {
        ForEach(viewModel.workTypeShelves) { shelf in
            ShelfSection(title: shelf.workType.displayName, systemImage: shelf.workType.iconName) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
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
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .padding(.horizontal)

            content
        }
    }
}

// MARK: - Continue Reading Card

private struct ContinueReadingCard: View {
    let bookmark: Bookmark

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(coverColor.gradient)
                .frame(width: 100, height: 140)
                .overlay {
                    VStack(spacing: 2) {
                        Text(String(bookmark.title.prefix(4)))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        Text("参考ビジュアル")
                            .font(.system(size: 5))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(4)
                }

            Text(bookmark.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: 100, alignment: .leading)

            Text(bookmark.authorName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)
        }
    }

    private var coverColor: Color {
        let hash = abs(bookmark.title.hashValue)
        let colors: [Color] = [
            Color(red: 0.2, green: 0.4, blue: 0.6),
            Color(red: 0.6, green: 0.3, blue: 0.3),
            Color(red: 0.3, green: 0.5, blue: 0.3),
            Color(red: 0.5, green: 0.4, blue: 0.6),
            Color(red: 0.6, green: 0.5, blue: 0.3),
            Color(red: 0.4, green: 0.5, blue: 0.5),
            Color(red: 0.5, green: 0.3, blue: 0.5),
            Color(red: 0.3, green: 0.4, blue: 0.5),
        ]
        return colors[hash % colors.count]
    }
}

// MARK: - Recommended Author Card

private struct RecommendedAuthorCard: View {
    let author: RecommendedAuthor

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundStyle(.secondary)

            Text(author.person.fullName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            if let work = author.representativeWork {
                Text(work.title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 100)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Recent Review Card

private struct RecentReviewCard: View {
    let review: BookReview

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(review.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)

            StarRatingView(rating: review.rating, size: .caption2)

            if !review.comment.isEmpty {
                Text(review.comment)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Text(review.authorName)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .frame(width: 150, alignment: .leading)
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Book Shelf Card

private struct BookShelfCard: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            BookCoverView(book: book, width: 100, height: 140)

            Text(book.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(width: 100, alignment: .leading)

            Text(book.authorName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)
        }
    }
}

// MARK: - Navigation Destinations

private struct BookmarkDestination: View {
    let bookmark: Bookmark
    @State private var book: Book?

    var body: some View {
        Group {
            if let book {
                WorkDetailScreen(book: book)
            } else {
                ProgressView()
            }
        }
        .task {
            book = try? await CatalogService.shared.book(id: bookmark.bookId)
        }
    }
}

private struct ReviewBookDestination: View {
    let review: BookReview
    @State private var book: Book?

    var body: some View {
        Group {
            if let book {
                WorkDetailScreen(book: book)
            } else {
                ProgressView()
            }
        }
        .task {
            book = try? await CatalogService.shared.book(id: review.bookId)
        }
    }
}
