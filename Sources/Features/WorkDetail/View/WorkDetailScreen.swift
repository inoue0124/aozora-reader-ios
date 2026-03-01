import SwiftData
import SwiftUI

struct WorkDetailScreen: View {
    let book: Book
    @State private var viewModel: WorkDetailViewModel
    @State private var favoritesVM = FavoritesViewModel()
    @State private var isFavorite = false
    @State private var showReview = false
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
                    isFavorite.toggle()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : .secondary)
                }
            }
        }
        .sheet(isPresented: $showReview, onDismiss: loadReview) {
            ReviewSheet(book: book)
        }
        .task {
            await viewModel.loadAuthor()
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                BookCoverView(book: book, width: 100, height: 140)

                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.title2)
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
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("あらすじ")
                .font(.headline)

            if viewModel.isSummaryLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let summary = viewModel.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .lineLimit(isSummaryExpanded ? nil : 3)

                if summary.count > 70 {
                    Button {
                        isSummaryExpanded.toggle()
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
        VStack(alignment: .leading, spacing: 12) {
            if !book.classification.isEmpty {
                MetadataRow(label: "分類", value: book.classification)
            }

            if !book.releaseDate.isEmpty {
                MetadataRow(label: "公開日", value: book.releaseDate)
            }

            if let url = book.cardURL {
                HStack {
                    Text("図書カード")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Link("青空文庫で見る", destination: url)
                        .font(.subheadline)
                }
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
            }
        }
    }

    private var actionSection: some View {
        NavigationLink {
            ReaderScreen(book: book)
        } label: {
            Label("この作品を読む", systemImage: "book")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }
}
