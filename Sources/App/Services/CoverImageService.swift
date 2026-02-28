import Foundation
import SwiftUI

actor CoverImageService {
    static let shared = CoverImageService()

    private init() {}

    func coverColor(for book: Book) -> Color {
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
}
