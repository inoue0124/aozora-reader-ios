import Foundation

struct Person: Identifiable, Sendable, Codable, Hashable {
    let id: Int
    let lastName: String
    let firstName: String
    let lastNameYomi: String
    let firstNameYomi: String
    let lastNameRomaji: String
    let firstNameRomaji: String
    let birthDate: String
    let deathDate: String

    var fullName: String {
        "\(lastName) \(firstName)"
    }

    var fullNameYomi: String {
        "\(lastNameYomi) \(firstNameYomi)"
    }

    var lifespan: String {
        let birth = birthDate.isEmpty ? "?" : String(birthDate.prefix(4))
        let death = deathDate.isEmpty ? "?" : String(deathDate.prefix(4))
        return "\(birth)–\(death)"
    }
}
