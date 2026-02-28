import Foundation

@Observable
@MainActor
final class AuthorDetailViewModel {
    let person: Person
    var works: [Book] = []
    var portraitURL: URL?
    var portraitSource: String?
    var isLoading = false
    var errorMessage: String?

    private let catalogService = CatalogService.shared

    init(person: Person) {
        self.person = person
    }

    func load() async {
        isLoading = true
        async let worksTask: Void = loadWorks()
        async let portraitTask: Void = loadPortrait()
        _ = await (worksTask, portraitTask)
        isLoading = false
    }

    private func loadWorks() async {
        do {
            works = try await catalogService.booksByPerson(personId: person.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadPortrait() async {
        let fullName = "\(person.lastName)\(person.firstName)"
        guard let encodedName = fullName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(
                  string: "https://ja.wikipedia.org/api/rest_v1/page/summary/\(encodedName)"
              )
        else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else { return }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let thumbnail = json?["thumbnail"] as? [String: Any],
               let source = thumbnail["source"] as? String
            {
                portraitURL = URL(string: source)
                portraitSource = "出典: Wikimedia Commons"
            }
        } catch {
            // Portrait is optional; silently ignore errors
        }
    }
}
