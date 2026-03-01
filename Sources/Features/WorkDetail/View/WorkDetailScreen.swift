import SwiftData
import SwiftUI

struct WorkDetailScreen: View {
    let book: Book
    @State private var viewModel: WorkDetailViewModel
    @State private var favoritesVM = FavoritesViewModel()
    @State private var isFavorite = false
    @State private var showReview = false
    @State private var showReader = false
    @State private var review: BookReview?
    @State private var isSummaryExpanded = false
    @Environment(\.modelContext) private var modelContext

    init(book: Book) {
        self.book = book
        _viewModel = State(initialValue: WorkDetailViewModel(book: book))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                summarySection
                metadataSection
                reviewSection
                actionSection
            }
            .padding()
        }
        .navigationTitle("作品詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    favoritesVM.toggleFavorite(book: book, context: modelContext)
                    withAnimation(.bouncy(duration: 0.3)) {
                        isFavorite.toggle()
                    }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .symbolEffect(.bounce, value: isFavorite)
                        .foregroundStyle(isFavorite ? AppColors.favorite : .secondary)
                        .contentTransition(.symbolEffect(.replace))
                }
            }
        }
        .sheet(isPresented: $showReview, onDismiss: loadReview) {
            ReviewSheet(book: book)
        }
        .fullScreenCover(isPresented: $showReader) {
            ReaderScreen(book: book)
        }
        .refreshable {
            await viewModel.loadAuthor()
            viewModel.checkReadingProgress(context: modelContext)
            isFavorite = favoritesVM.isFavorite(bookId: book.id, context: modelContext)
            loadReview()
            await viewModel.loadSummary(context: modelContext)
        }
        .task {
            await viewModel.loadAuthor()
            viewModel.checkReadingProgress(context: modelContext)
            isFavorite = favoritesVM.isFavorite(bookId: book.id, context: modelContext)
            loadReview()
            isSummaryExpanded = false
            await viewModel.loadSummary(context: modelContext)
        }
    }

    private func loadReview() {
        let bookId = book.id
        let descriptor = FetchDescriptor<BookReview>(
            predicate: #Predicate { $0.bookId == bookId }
        )
        review = try? modelContext.fetch(descriptor).first
    }

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            BookCoverView(book: book, width: 130, height: 182)

            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.title)
                    .fontWeight(.bold)

                if !book.subtitle.isEmpty {
                    Text(book.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let author = viewModel.author {
                    NavigationLink {
                        AuthorDetailScreen(person: author)
                    } label: {
                        Label(author.fullName, systemImage: "person")
                            .font(.subheadline)
                    }
                } else {
                    Label(book.authorName, systemImage: "person")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("あらすじ")
                .font(.headline)

            if viewModel.isSummaryLoading {
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .frame(width: 180, height: 14)
                }
                .shimmer()
            } else if let summary = viewModel.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .lineLimit(isSummaryExpanded ? nil : 3)

                if summary.count > 70 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isSummaryExpanded.toggle()
                        }
                    } label: {
                        Text(isSummaryExpanded ? "閉じる" : "もっと見る")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("あらすじはありません")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !book.classification.isEmpty {
                MetadataRow(icon: "tag", label: "分類", value: book.classification)
                if !book.releaseDate.isEmpty || book.cardURL != nil {
                    Divider().padding(.leading, 36)
                }
            }

            if !book.releaseDate.isEmpty {
                MetadataRow(icon: "calendar", label: "公開日", value: book.releaseDate)
                if book.cardURL != nil {
                    Divider().padding(.leading, 36)
                }
            }

            if let url = book.cardURL {
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    Text("図書カード")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Link("青空文庫で見る", destination: url)
                        .font(.subheadline)
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("レビュー")
                    .font(.headline)
                Spacer()
                Button {
                    showReview = true
                } label: {
                    Text(review == nil ? "レビューを書く" : "編集")
                        .font(.subheadline)
                }
            }

            if let review {
                VStack(alignment: .leading, spacing: 4) {
                    StarRatingView(rating: review.rating)
                    if !review.comment.isEmpty {
                        Text(review.comment)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("まだレビューはありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("最初のレビューを書いてみよう")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var actionSection: some View {
        Button {
            showReader = true
        } label: {
            Label(
                viewModel.hasReadingProgress ? "続きを読む" : "この作品を読む",
                systemImage: "book"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [AppColors.accent, AppColors.accent.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: AppColors.accent.opacity(0.3), radius: 4, y: 2)
        }
    }
}

private struct MetadataRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
        .padding(.vertical, 8)
    }
}
