import SwiftUI

struct ReaderScreen: View {
    let book: Book
    @State private var viewModel: ReaderViewModel

    init(book: Book) {
        self.book = book
        _viewModel = State(initialValue: ReaderViewModel(book: book))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("本文を取得中…")
                        .foregroundStyle(.secondary)
                }
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "読み込みエラー",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if let content = viewModel.content {
                ScrollView {
                    Text(content)
                        .textSelection(.enabled)
                        .padding()
                }
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadContent() }
    }
}
