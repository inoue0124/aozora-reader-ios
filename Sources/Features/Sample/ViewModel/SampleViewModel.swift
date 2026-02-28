import Foundation
import Observation

@MainActor
@Observable
final class SampleViewModel {
    private(set) var items: [SampleItem] = []
    private(set) var isLoading = false
    var newItemTitle = ""
    private(set) var errorMessage: String?

    private let repository: SampleRepositoryProtocol

    init(repository: SampleRepositoryProtocol = SampleRepository()) {
        self.repository = repository
    }

    func fetchItems() async {
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await repository.fetchItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addItem() async {
        let title = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        do {
            let item = try await repository.addItem(title: title)
            items.append(item)
            newItemTitle = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleItem(_ item: SampleItem) async {
        do {
            let updated = try await repository.toggleItem(item)
            if let index = items.firstIndex(where: { $0.id == updated.id }) {
                items[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteItem(_ item: SampleItem) async {
        do {
            try await repository.deleteItem(item)
            items.removeAll { $0.id == item.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
