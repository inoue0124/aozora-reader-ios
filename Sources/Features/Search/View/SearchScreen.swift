import SwiftUI

struct SearchScreen: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView("検索中…")
                    Spacer()
                }
                .listRowSeparator(.hidden)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "エラー",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
                .listRowSeparator(.hidden)
            } else if viewModel.hasSearched, viewModel.results.isEmpty {
                ContentUnavailableView.search(text: viewModel.query)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(viewModel.results) { book in
                    NavigationLink(value: book) {
                        BookRowView(book: book)
                    }
                }
            }
        }
        .listStyle(.plain)
        .searchable(
            text: $viewModel.query,
            prompt: viewModel.searchMode == .title ? "タイトルで検索" : "著者名で検索"
        )
        .onSubmit(of: .search) {
            Task { await viewModel.search() }
        }
        .onChange(of: viewModel.query) {
            if viewModel.query.isEmpty {
                viewModel.results = []
                viewModel.hasSearched = false
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Picker("検索モード", selection: $viewModel.searchMode) {
                    ForEach(SearchMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
        }
        .navigationTitle("作品検索")
        .navigationDestination(for: Book.self) { book in
            WorkDetailScreen(book: book)
        }
    }
}
