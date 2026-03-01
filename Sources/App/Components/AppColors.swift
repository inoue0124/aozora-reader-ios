import SwiftUI

enum AppColors {
    /// Primary action color (読むボタン, 検索導線, 年表アクセント)
    static let accent = Color.blue

    /// Favorite heart color
    static let favorite = Color.red

    /// Star rating active color
    static let rating = Color.yellow

    /// Star rating inactive color
    static let ratingInactive = Color.gray.opacity(0.3)

    /// Timeline dot and year accent
    static let timeline = Color.blue

    /// Cached/downloaded indicator
    static let cached = Color.green
}
