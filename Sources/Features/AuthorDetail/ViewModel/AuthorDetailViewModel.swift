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
        if let url = await AuthorPortraitService.shared.portraitURL(for: person) {
            portraitURL = url
            portraitSource = "出典: Wikimedia Commons"
        }
    }
}
