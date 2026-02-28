import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                Text("検索画面（実装予定）")
                    .navigationTitle("作品検索")
            }
            .tabItem {
                Label("検索", systemImage: "magnifyingglass")
            }

            NavigationStack {
                Text("お気に入り画面（実装予定）")
                    .navigationTitle("お気に入り")
            }
            .tabItem {
                Label("お気に入り", systemImage: "heart.fill")
            }
        }
    }
}
