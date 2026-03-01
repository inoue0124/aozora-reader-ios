import SwiftUI

struct HomeScreen: View {
    @State private var viewModel = HomeViewModel()
    @State private var showWelcome = !UserDefaults.standard.bool(forKey: "hasSeenWelcome")
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 32) {
                if viewModel.isLoading {
                    loadingSection
                } else {
                    if showWelcome {
                        welcomeSection
                    }
                    continueReadingSection
                    recommendedAuthorsSection
                    recentReviewsSection
                    workTypeShelvesSection
                }
            }
            .padding(.vertical)
            .animation(.easeOut(duration: 0.3), value: viewModel.isLoading)
        }
        .navigationTitle("青空リーダー")
        .toolbarTitleDisplayMode(.inlineLarge)
        .navigationDestination(for: Book.self) { book in
            WorkDetailScreen(book: book)
        }
        .navigationDestination(for: Person.self) { person in
            AuthorDetailScreen(person: person)
        }
        .refreshable {
            await viewModel.load(context: modelContext)
        }
        .task {
            await viewModel.load(context: modelContext)
        }
    }

    // MARK: - Welcome

    private var welcomeSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.accent)

            Text("青空リーダーへようこそ")
                .font(.title3.bold())

            Text("青空文庫の作品を探して読んでみよう")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink(value: "search") {
                Label("作品を探す", systemImage: "magnifyingglass")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(AppColors.accent, in: Capsule())
                    .foregroundStyle(.white)
            }
            .padding(.top, 4)

            Button("閉じる") {
                withAnimation {
                    showWelcome = false
                    UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }

    // MARK: - Loading

    private var loadingSection: some View {
        VStack(alignment: .leading, spacing: 28) {
            skeletonShelf
            skeletonShelf
        }
        .shimmer()
    }

    private var skeletonShelf: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(.quaternary)
                .frame(width: 140, height: 20)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0 ..< 4, id: \.self) { _ in
                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.quaternary)
                                .frame(width: 110, height: 155)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.quaternary)
                                .frame(width: 90, height: 14)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.quaternary)
                                .frame(width: 60, height: 12)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
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
        } else if !showWelcome {
            ShelfSection(title: "続きから読む", systemImage: "bookmark.fill") {
                Text("作品を読み始めると、ここに表示されます")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
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
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(AppColors.accent, in: RoundedRectangle(cornerRadius: 7))

                Text(title)
                    .font(.title3.weight(.bold))

                Spacer()
            }
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(bookmark.title)、\(bookmark.authorName)、続きから読む")
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(book.title)、\(book.authorName)")
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
