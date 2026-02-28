import SwiftUI

struct ReaderScreen: View {
    let book: Book

    var body: some View {
        Text("読書画面（実装予定）")
            .navigationTitle(book.title)
    }
}
