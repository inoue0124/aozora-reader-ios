import SwiftUI

struct ReaderScreen: View {
    let book: Book
    @State private var viewModel: ReaderViewModel
    @State private var settings = ReadingSettings.shared
    @State private var showSettings = false

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
                        .font(settings.fontSize.font)
                        .lineSpacing(settings.lineSpacing.value)
                        .foregroundStyle(settings.theme.textColor)
                        .textSelection(.enabled)
                        .padding(settings.padding.value)
                }
                .background(settings.theme.backgroundColor)
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "textformat.size")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            ReadingSettingsSheet(settings: settings)
        }
        .task { await viewModel.loadContent() }
    }
}
