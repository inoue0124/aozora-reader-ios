import SwiftData
import SwiftUI

struct ReaderScreen: View {
    let book: Book
    @State private var viewModel: ReaderViewModel
    @State private var settings = ReadingSettings.shared
    @State private var showSettings = false
    @Environment(\.modelContext) private var modelContext

    init(book: Book) {
        self.book = book
        _viewModel = State(initialValue: ReaderViewModel(book: book))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("本文を取得中…")
                        .foregroundStyle(.secondary)
                }
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(
                    "読み込みエラー",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if let content = viewModel.content {
                if settings.layoutMode == .verticalPaged {
                    VerticalPagedReaderView(content: content, settings: settings) { offset in
                        viewModel.saveBookmark(scrollOffset: offset, context: modelContext)
                    }
                    .background(settings.theme.backgroundColor)
                } else {
                    ScrollViewReader { _ in
                        ScrollView {
                            VStack(spacing: 0) {
                                Color.clear
                                    .frame(height: 0)
                                    .id("top")

                                Text(content)
                                    .font(settings.fontSize.font)
                                    .lineSpacing(settings.lineSpacing.value)
                                    .foregroundStyle(settings.theme.textColor)
                                    .textSelection(.enabled)
                                    .padding(settings.padding.value)
                            }
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: ScrollOffsetKey.self,
                                        value: -geo.frame(in: .named("scroll")).origin.y
                                    )
                                }
                            )
                        }
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetKey.self) { offset in
                            viewModel.saveBookmark(scrollOffset: offset, context: modelContext)
                        }
                    }
                    .background(settings.theme.backgroundColor)
                }
            } else {
                ContentUnavailableView(
                    "本文が表示できません",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("別の作品で試してみて。改善するから、タイトルを教えてくれると助かる")
                )
            }
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "textformat.size")
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            ReadingSettingsSheet(settings: settings)
        }
        .task {
            viewModel.loadBookmark(context: modelContext)
            await viewModel.loadContent()
        }
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: Double = 0
    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = nextValue()
    }
}
