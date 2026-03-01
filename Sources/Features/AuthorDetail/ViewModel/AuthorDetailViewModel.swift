import Foundation

@Observable
@MainActor
final class AuthorDetailViewModel {
    let person: Person
    var works: [Book] = []
    var representativeWorks: [Book] = []
    var portraitURL: URL?
    var portraitSource: String?
    var biography: AuthorBiography?
    var timeline: [AuthorTimelineEntry] = []
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
        async let biographyTask: Void = loadBiography()
        _ = await (worksTask, portraitTask, biographyTask)
        buildTimeline()
        isLoading = false
    }

    private func loadWorks() async {
        do {
            let allWorks = try await catalogService.booksByPerson(personId: person.id)
            works = allWorks
            representativeWorks = Array(
                allWorks
                    .sorted { $0.releaseDate < $1.releaseDate }
                    .prefix(5)
            )
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

    private func loadBiography() async {
        biography = await AuthorBiographyService.shared.biography(for: person)
    }

    private func buildTimeline() {
        var entries: [AuthorTimelineEntry] = []

        let birthYear = String(person.birthDate.prefix(4))
        if !birthYear.isEmpty, birthYear != "0000" {
            entries.append(AuthorTimelineEntry(year: birthYear, label: "誕生"))
        }

        for work in works.sorted(by: { $0.releaseDate < $1.releaseDate }) {
            let year = String(work.releaseDate.prefix(4))
            guard !year.isEmpty, year != "0000" else { continue }
            entries.append(AuthorTimelineEntry(year: year, label: "『\(work.title)』公開"))
        }

        let deathYear = String(person.deathDate.prefix(4))
        if !deathYear.isEmpty, deathYear != "0000" {
            entries.append(AuthorTimelineEntry(year: deathYear, label: "逝去"))
        }

        timeline = entries
    }
}
