import SwiftUI

struct BookCoverView: View {
    let book: Book
    var width: CGFloat = 60
    var height: CGFloat = 85

    private var coverColor: Color {
        let hash = abs(book.title.hashValue)
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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(coverColor.gradient)

            VStack(spacing: 2) {
                Text(String(book.title.prefix(4)))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text("参考ビジュアル")
                    .font(.system(size: 5))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(4)
        }
        .frame(width: width, height: height)
    }
}
