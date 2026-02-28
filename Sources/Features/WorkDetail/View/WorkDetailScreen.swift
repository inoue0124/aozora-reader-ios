import SwiftUI

struct WorkDetailScreen: View {
    let book: Book

    var body: some View {
        Text(book.title)
            .navigationTitle("作品詳細")
    }
}
