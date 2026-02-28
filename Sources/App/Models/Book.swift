import Foundation

struct Book: Identifiable, Sendable, Codable, Hashable {
    let id: Int
    let title: String
    let titleYomi: String
    let personId: Int
    let authorName: String
    let cardUrl: String
    let textUrl: String
    let htmlUrl: String
    let releaseDate: String
    let subtitle: String
    let classification: String

    var cardURL: URL? {
        URL(string: cardUrl)
    }

    var textFileURL: URL? {
        URL(string: textUrl)
    }

    var htmlFileURL: URL? {
        URL(string: htmlUrl)
    }
}
