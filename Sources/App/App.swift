import SwiftData
import SwiftUI

@main
struct MainApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            FavoriteBook.self,
            Bookmark.self,
            BookReview.self,
            ReadingHistory.self,
            GeneratedSummary.self,
        ])
    }
}
