import Foundation

actor AuthorBiographyService {
    static let shared = AuthorBiographyService()

    private var cache: [Int: AuthorBiography] = [:]

    private init() {}

    func biography(for person: Person) async -> AuthorBiography? {
        if let cached = cache[person.id] {
            return cached
        }

        let fullName = "\(person.lastName)\(person.firstName)"
        guard
            let encodedName = fullName.addingPercentEncoding(
                withAllowedCharacters: .urlQueryAllowed
            ),
            let url = URL(
                string: "https://ja.wikipedia.org/api/rest_v1/page/summary/\(encodedName)"
            )
        else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard
                let httpResponse = response as? HTTPURLResponse,
                httpResponse.statusCode == 200
            else { return nil }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let extract = json?["extract"] as? String ?? ""
            let description = json?["description"] as? String ?? ""

            guard !extract.isEmpty else { return nil }

            let bio = AuthorBiography(
                extract: extract,
                description: description,
                source: "出典: Wikipedia（ja.wikipedia.org）"
            )
            cache[person.id] = bio
            return bio
        } catch {
            return nil
        }
    }
}
