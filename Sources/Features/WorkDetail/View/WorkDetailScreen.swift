import SwiftUI

struct WorkDetailScreen: View {
    let book: Book
    @State private var viewModel: WorkDetailViewModel

    init(book: Book) {
        self.book = book
        _viewModel = State(initialValue: WorkDetailViewModel(book: book))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                metadataSection
                actionSection
            }
            .padding()
        }
        .navigationTitle("作品詳細")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadAuthor() }
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(book.title)
                .font(.title)
                .fontWeight(.bold)

            if !book.subtitle.isEmpty {
                Text(book.subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            if let author = viewModel.author {
                NavigationLink {
                    AuthorDetailScreen(person: author)
                } label: {
                    Label(author.fullName, systemImage: "person")
                        .font(.headline)
                }
            } else {
                Label(book.authorName, systemImage: "person")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
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

    @ViewBuilder
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
