import SwiftUI

struct BookCoverView: View {
    let book: Book
    var width: CGFloat = 60
    var height: CGFloat = 85

    static func coverColor(forTitle title: String) -> Color {
        let hash = abs(title.hashValue)
        let colors: [Color] = [
            Color(red: 0.2, green: 0.4, blue: 0.6),
            Color(red: 0.6, green: 0.3, blue: 0.3),
            Color(red: 0.3, green: 0.5, blue: 0.3),
            Color(red: 0.5, green: 0.4, blue: 0.6),
            Color(red: 0.6, green: 0.5, blue: 0.3),
            Color(red: 0.4, green: 0.5, blue: 0.5),
            Color(red: 0.5, green: 0.3, blue: 0.5),
            Color(red: 0.3, green: 0.4, blue: 0.5),
        ]
        return colors[hash % colors.count]
    }

    private var coverColor: Color {
        Self.coverColor(forTitle: book.title)
    }

    private var isLarge: Bool {
        width >= 90
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 8)
                .fill(coverColor.gradient)

            // Spine accent
            HStack(spacing: 0) {
                Rectangle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Title area
            VStack(spacing: 4) {
                Spacer()

                Text(book.title)
                    .font(.system(size: isLarge ? 13 : 10, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(isLarge ? 4 : 2)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 1, y: 1)

                Text(book.authorName)
                    .font(.system(size: isLarge ? 9 : 7, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, isLarge ? 10 : 6)
            .padding(.vertical, isLarge ? 12 : 6)
        }
        .frame(width: width, height: height)
        .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 3)
    }
}
