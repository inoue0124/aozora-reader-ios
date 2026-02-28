import SwiftData
import SwiftUI

struct FavoritesScreen: View {
    @Query(sort: \FavoriteBook.addedAt, order: .reverse) private var favorites: [FavoriteBook]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if favorites.isEmpty {
                ContentUnavailableView(
                    "お気に入りなし",
                    systemImage: "heart.slash",
                    description: Text("作品詳細画面からお気に入りに追加できます")
                )
            } else {
                List {
                    ForEach(favorites) { favorite in
                        NavigationLink {
                            FavoriteBookDestination(favorite: favorite)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(favorite.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                Text(favorite.authorName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(favorites[index])
                        }
                        try? modelContext.save()
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("お気に入り")
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
