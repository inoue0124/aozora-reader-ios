import Foundation

struct AozoraCatalog: Sendable, Codable {
    let books: [Book]
    let persons: [Person]
}
