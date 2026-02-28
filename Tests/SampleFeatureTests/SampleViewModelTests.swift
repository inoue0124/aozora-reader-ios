@testable import App
import Testing

@MainActor
struct SampleViewModelTests {
    @Test
    func addItem() async {
        let viewModel = SampleViewModel(repository: SampleRepository())
        viewModel.newItemTitle = "Test Item"
        await viewModel.addItem()

        #expect(viewModel.items.count == 1)
        #expect(viewModel.items.first?.title == "Test Item")
        #expect(viewModel.newItemTitle.isEmpty)
    }

    @Test
    func addItemWithEmptyTitle() async {
        let viewModel = SampleViewModel(repository: SampleRepository())
        viewModel.newItemTitle = "   "
        await viewModel.addItem()

        #expect(viewModel.items.isEmpty)
    }

    @Test
    func toggleItem() async {
        let viewModel = SampleViewModel(repository: SampleRepository())
        viewModel.newItemTitle = "Test"
        await viewModel.addItem()

        let item = viewModel.items[0]
        #expect(!item.isCompleted)

        await viewModel.toggleItem(item)
        #expect(viewModel.items[0].isCompleted)
    }

    @Test
    func deleteItem() async {
        let viewModel = SampleViewModel(repository: SampleRepository())
        viewModel.newItemTitle = "Test"
        await viewModel.addItem()
        #expect(viewModel.items.count == 1)

        let item = viewModel.items[0]
        await viewModel.deleteItem(item)
        #expect(viewModel.items.isEmpty)
    }
}
