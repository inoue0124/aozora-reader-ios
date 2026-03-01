import Foundation

actor AuthorPortraitService {
    static let shared = AuthorPortraitService()

    private var cache: [Int: URL] = [:]

    private init() {}

    /// Wikipedia から著者の肖像画 URL を取得する（キャッシュ付き）
    func portraitURL(for person: Person) async -> URL? {
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
            if
                let thumbnail = json?["thumbnail"] as? [String: Any],
                let source = thumbnail["source"] as? String,
                let imageURL = URL(string: source)
            {
                cache[person.id] = imageURL
                return imageURL
            }
        } catch {
            // Portrait is optional; silently ignore errors
        }
        return nil
    }
}
