import SwiftData
import SwiftUI

struct ReviewSheet: View {
    let book: Book
    @State private var viewModel = ReviewViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("評価") {
                    HStack(spacing: 8) {
                        ForEach(1 ... 5, id: \.self) { star in
                            Button {
                                viewModel.rating = star
                            } label: {
                                Image(systemName: star <= viewModel.rating ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(star <= viewModel.rating ? .yellow : .gray)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }

                Section("感想") {
                    TextEditor(text: $viewModel.comment)
                        .frame(minHeight: 120)
                }

                Section {
                    Button("保存") {
                        viewModel.saveReview(book: book, context: modelContext)
                        dismiss()
                    }
                    .disabled(viewModel.rating == 0)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                if viewModel.existingReview != nil {
                    Section {
                        Button("レビューを削除", role: .destructive) {
                            viewModel.deleteReview(context: modelContext)
                            dismiss()
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("レビュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
            .task {
                viewModel.loadReview(bookId: book.id, context: modelContext)
            }
        }
    }
}
