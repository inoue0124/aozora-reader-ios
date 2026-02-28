import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeScreen()
            }
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
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
                Label("お気に入り", systemImage: "heart.fill")
            }
        }
    }
}
