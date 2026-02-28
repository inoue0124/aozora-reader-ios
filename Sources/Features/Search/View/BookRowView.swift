import SwiftUI

struct BookRowView: View {
    let book: Book
    var showCacheIcon = false

    var body: some View {
        HStack(spacing: 12) {
            BookCoverView(book: book)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(book.authorName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !book.subtitle.isEmpty {
                    Text(book.subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if showCacheIcon {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}
