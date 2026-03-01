import SwiftUI

struct SearchScreen: View {
    @State private var viewModel = SearchViewModel()

    var body: some View {
        List {
            if !viewModel.hasSearched {
                searchIdleSection
            } else if viewModel.isLoading {
                ForEach(0 ..< 5, id: \.self) { _ in
                    searchSkeletonRow
                }
                .listRowSeparator(.hidden)
                .shimmer()
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
                resultCountHeader
                ForEach(viewModel.results) { book in
                    NavigationLink(value: book) {
                        BookRowView(book: book)
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            if viewModel.hasSearched, !viewModel.query.isEmpty {
                await viewModel.search()
            }
        }
        .animation(.easeOut(duration: 0.25), value: viewModel.results.count)
        .searchable(
            text: $viewModel.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: viewModel.searchMode == .title ? "タイトルで検索" : "著者名で検索"
        )
        .onSubmit(of: .search) {
            Task { await viewModel.search() }
        }
        .onChange(of: viewModel.query) {
            if viewModel.query.isEmpty {
                viewModel.results = []
                viewModel.hasSearched = false
            } else if viewModel.query.count >= 2 {
                Task { await viewModel.search() }
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

    // MARK: - Idle State

    @ViewBuilder
    private var searchIdleSection: some View {
        if !viewModel.recentSearches.isEmpty {
            recentSearchesSection
        }

        searchHintsSection
    }

    private var recentSearchesSection: some View {
        Section {
            FlowLayout(spacing: 8) {
                ForEach(viewModel.recentSearches, id: \.self) { keyword in
                    Button {
                        viewModel.query = keyword
                        Task { await viewModel.search() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption2)
                            Text(keyword)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.quaternary, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .listRowSeparator(.hidden)
        } header: {
            HStack {
                Text("最近の検索")
                Spacer()
                Button("クリア") {
                    viewModel.clearRecentSearches()
                }
                .font(.caption)
            }
        }
    }

    private var searchHintsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("検索のヒント", systemImage: "lightbulb")
                    .font(.subheadline)
                    .fontWeight(.medium)

                VStack(alignment: .leading, spacing: 8) {
                    hintRow(icon: "person", text: "夏目漱石、宮沢賢治、太宰治…")
                    hintRow(icon: "book", text: "吾輩は猫である、銀河鉄道の夜…")
                    hintRow(icon: "tag", text: "セグメントで「著者」に切り替えて著者名で検索")
                }
            }
            .padding(.vertical, 8)
            .listRowSeparator(.hidden)
        }
    }

    private func hintRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(text)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Result Count

    private var resultCountHeader: some View {
        Text("\(viewModel.results.count)件の作品が見つかりました")
            .font(.caption)
            .foregroundStyle(.secondary)
            .listRowSeparator(.hidden)
    }

    // MARK: - Skeleton

    private var searchSkeletonRow: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(.quaternary)
                .frame(width: 50, height: 70)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(width: 160, height: 16)
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(width: 100, height: 12)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: currentY + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
