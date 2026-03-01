import SwiftData
import SwiftUI

struct FavoritesScreen: View {
    @Query(sort: \FavoriteBook.addedAt, order: .reverse) private var favorites: [FavoriteBook]
    @Environment(\.modelContext) private var modelContext
    @State private var isGridView = false

    var body: some View {
        Group {
            if favorites.isEmpty {
                ContentUnavailableView(
                    "お気に入りなし",
                    systemImage: "heart.slash",
                    description: Text("作品詳細画面からお気に入りに追加できます")
                )
            } else if isGridView {
                gridView
            } else {
                listView
            }
        }
        .navigationTitle("お気に入り")
        .toolbar {
            if !favorites.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isGridView.toggle()
                        }
                    } label: {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                    }
                }
            }
        }
    }

    // MARK: - List View

    private var listView: some View {
        List {
            ForEach(favorites) { favorite in
                NavigationLink {
                    FavoriteBookDestination(favorite: favorite)
                } label: {
                    favoriteRow(favorite)
                }
                .contextMenu {
                    contextMenuItems(for: favorite)
                }
            }
            .onDelete { indexSet in
                withAnimation {
                    for index in indexSet {
                        modelContext.delete(favorites[index])
                    }
                    try? modelContext.save()
                }
            }
        }
        .listStyle(.plain)
        .animation(.default, value: favorites.count)
    }

    private func favoriteRow(_ favorite: FavoriteBook) -> some View {
        HStack(spacing: 12) {
            BookCoverView(
                title: favorite.title,
                authorName: favorite.authorName,
                width: 60,
                height: 85
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(favorite.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(favorite.authorName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(favorite.addedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Grid View

    private var gridView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 16),
                    count: 3
                ),
                spacing: 20
            ) {
                ForEach(favorites) { favorite in
                    NavigationLink {
                        FavoriteBookDestination(favorite: favorite)
                    } label: {
                        favoriteGridCell(favorite)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        contextMenuItems(for: favorite)
                    }
                }
            }
            .padding()
        }
    }

    private func favoriteGridCell(_ favorite: FavoriteBook) -> some View {
        VStack(spacing: 6) {
            BookCoverView(
                title: favorite.title,
                authorName: favorite.authorName,
                width: 100,
                height: 140
            )

            Text(favorite.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(favorite.authorName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuItems(for favorite: FavoriteBook) -> some View {
        NavigationLink {
            FavoriteBookDestination(favorite: favorite)
        } label: {
            Label("詳細を見る", systemImage: "info.circle")
        }

        Button(role: .destructive) {
            withAnimation {
                modelContext.delete(favorite)
                try? modelContext.save()
            }
        } label: {
            Label("お気に入りから削除", systemImage: "heart.slash")
        }
    }
}

private struct FavoriteBookDestination: View {
    let favorite: FavoriteBook
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
            book = try? await CatalogService.shared.book(id: favorite.bookId)
        }
    }
}
