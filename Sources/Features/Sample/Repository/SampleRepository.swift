import Foundation

protocol SampleRepositoryProtocol: Sendable {
    func fetchItems() async throws -> [SampleItem]
    func addItem(title: String) async throws -> SampleItem
    func toggleItem(_ item: SampleItem) async throws -> SampleItem
    func deleteItem(_ item: SampleItem) async throws
}

final class SampleRepository: SampleRepositoryProtocol, @unchecked Sendable {
    private var items: [SampleItem] = []

    func fetchItems() async throws -> [SampleItem] {
        items
    }

    func addItem(title: String) async throws -> SampleItem {
        let item = SampleItem(title: title)
        items.append(item)
        return item
    }

    func toggleItem(_ item: SampleItem) async throws -> SampleItem {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            throw SampleError.itemNotFound
        }
        items[index].isCompleted.toggle()
        return items[index]
    }

    func deleteItem(_ item: SampleItem) async throws {
        items.removeAll { $0.id == item.id }
    }
}

enum SampleError: LocalizedError {
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            "Item not found"
        }
    }
}
