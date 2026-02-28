import SwiftUI

struct SampleView: View {
    @State private var viewModel = SampleViewModel()

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("New item", text: $viewModel.newItemTitle)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        Task { await viewModel.addItem() }
                    }
                    .disabled(viewModel.newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Section {
                ForEach(viewModel.items) { item in
                    HStack {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isCompleted ? .green : .secondary)
                            .onTapGesture {
                                Task { await viewModel.toggleItem(item) }
                            }
                        Text(item.title)
                            .strikethrough(item.isCompleted)
                    }
                }
                .onDelete { indexSet in
                    let itemsToDelete = indexSet.map { viewModel.items[$0] }
                    for item in itemsToDelete {
                        Task { await viewModel.deleteItem(item) }
                    }
                }
            }
        }
        .navigationTitle("Sample")
        .task { await viewModel.fetchItems() }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
