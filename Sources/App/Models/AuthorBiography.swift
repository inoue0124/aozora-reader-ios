import Foundation

struct AuthorBiography: Sendable {
    let extract: String
    let description: String
    let source: String
}

struct AuthorTimelineEntry: Identifiable, Sendable {
    let id = UUID()
    let year: String
    let label: String
}
