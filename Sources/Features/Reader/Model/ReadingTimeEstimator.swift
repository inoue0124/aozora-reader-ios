import Foundation

enum ReadingTimeEstimator {
    /// Average Japanese reading speed: approximately 500 characters per minute.
    /// A single vertical-paged reader page holds roughly 400–600 characters
    /// depending on font size and padding, so 1 page ≈ 1 minute is a reasonable
    /// default estimate.
    static let minutesPerPage: Double = 1.0

    /// Returns the estimated remaining reading time in minutes.
    static func remainingMinutes(currentPage: Int, totalPages: Int) -> Int {
        let remaining = max(totalPages - currentPage, 0)
        return max(Int(ceil(Double(remaining) * minutesPerPage)), 0)
    }

    /// Formats the remaining time for display (e.g. "約3分").
    static func formattedRemainingTime(currentPage: Int, totalPages: Int) -> String {
        let minutes = remainingMinutes(currentPage: currentPage, totalPages: totalPages)
        if minutes <= 0 {
            return "まもなく読了"
        }
        return "約\(minutes)分"
    }
}
