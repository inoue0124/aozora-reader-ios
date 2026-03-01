import SwiftData
import SwiftUI

struct ContentView: View {
    @Query private var favorites: [FavoriteBook]

    var body: some View {
        TabView {
            NavigationStack {
                HomeScreen()
            }
            .tabItem {
                Label("ホーム", systemImage: "books.vertical.fill")
            }

            NavigationStack {
                SearchScreen()
            }
            .tabItem {
                Label("検索", systemImage: "magnifyingglass")
            }

            NavigationStack {
                FavoritesScreen()
            }
            .tabItem {
                Label("お気に入り", systemImage: "bookmark.fill")
            }
            .badge(favorites.count)
        }
        .tint(AppColors.accent)
    }
}
