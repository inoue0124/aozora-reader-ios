import SwiftData
import SwiftUI

struct ReaderScreen: View {
    let book: Book
    @State private var viewModel: ReaderViewModel
    @State private var settings = ReadingSettings.shared
    @State private var showSettings = false
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var scrollOffset: Double = 0
    @State private var contentHeight: Double = 0
    @State private var showScrubber = false
    @State private var scrubberPage: Double = 1
    @State private var isScrubbing = false
    @State private var scrubberHideTask: Task<Void, Never>?
    @State private var jumpToPage: Int?
    @State private var showPageJump = false
    @State private var pageJumpText = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(book: Book) {
        self.book = book
        _viewModel = State(initialValue: ReaderViewModel(book: book))
    }

    var body: some View {
        NavigationStack {
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
                    readerContent(content)
                } else {
                    ContentUnavailableView(
                        "本文が表示できません",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text(
                            "別の作品で試してみて。改善するから、タイトルを教えてくれると助かる"
                        )
                    )
                }
            }
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if totalPages > 1 {
                        Button { showPageJump = true } label: {
                            Image(systemName: "arrow.right.doc.on.clipboard")
                        }
                    }
                    Button { showSettings = true } label: {
                        Image(systemName: "textformat.size")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                ReadingSettingsSheet(settings: settings)
            }
            .alert("ページ移動", isPresented: $showPageJump) {
                TextField("ページ番号", text: $pageJumpText)
                    .keyboardType(.numberPad)
                Button("移動") {
                    if
                        let page = Int(pageJumpText),
                        page >= 1, page <= totalPages
                    {
                        jumpToPage = page
                    }
                    pageJumpText = ""
                }
                Button("キャンセル", role: .cancel) {
                    pageJumpText = ""
                }
            } message: {
                Text("1〜\(totalPages)ページ")
            }
            .task {
                viewModel.loadBookmark(context: modelContext)
                ReadingHistoryService.shared.recordView(book: book, context: modelContext)
                await viewModel.loadContent()
            }
        }
    }

    // MARK: - Reader Content

    @ViewBuilder
    private func readerContent(_ content: AttributedString) -> some View {
        if settings.layoutMode == .verticalPaged {
            verticalPagedContent(content)
        } else {
            horizontalScrollContent(content)
        }
    }

    private func verticalPagedContent(_ content: AttributedString) -> some View {
        ZStack(alignment: .bottom) {
            VerticalPagedReaderView(
                content: content,
                settings: settings,
                savedPageRatio: viewModel.savedScrollOffset,
                jumpToPage: $jumpToPage
            ) { ratio in
                viewModel.saveBookmark(scrollOffset: ratio, context: modelContext)
            } onPageChanged: { current, total in
                currentPage = current
                totalPages = total
                if !isScrubbing {
                    scrubberPage = Double(current)
                }
                scheduleScrubberHide()
            }
            .background(settings.theme.backgroundColor)
            .onTapGesture { toggleScrubber() }

            readerOverlay
        }
    }

    private func horizontalScrollContent(_ content: AttributedString) -> some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { _ in
                ScrollView {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 0).id("top")

                        Text(content)
                            .font(.custom(settings.fontFamily.uiFontName, size: CGFloat(settings.fontSize.rawValue)))
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
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ContentHeightKey.self,
                                value: geo.size.height
                            )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetKey.self) { offset in
                    scrollOffset = offset
                    viewModel.saveBookmark(scrollOffset: offset, context: modelContext)
                    updateHorizontalPages()
                }
                .onPreferenceChange(ContentHeightKey.self) { height in
                    contentHeight = height
                    updateHorizontalPages()
                }
            }
            .background(settings.theme.backgroundColor)

            readerOverlay
        }
    }

    // MARK: - Reader Overlay

    private var readerOverlay: some View {
        VStack(spacing: 0) {
            progressBar

            Spacer()

            if settings.showReadingHUD {
                readingHUD
            }

            if showScrubber, totalPages > 1 {
                pageScrubber
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showScrubber)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            let progress = totalPages > 1
                ? CGFloat(currentPage - 1) / CGFloat(totalPages - 1)
                : 0
            Rectangle()
                .fill(AppColors.accent)
                .frame(width: geo.size.width * progress, height: 2)
        }
        .frame(height: 2)
    }

    private var pageScrubber: some View {
        VStack(spacing: 4) {
            if isScrubbing {
                Text("\(Int(scrubberPage)) / \(totalPages)")
                    .font(.caption.monospacedDigit())
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }

            Slider(
                value: $scrubberPage,
                in: 1 ... max(Double(totalPages), 1),
                step: 1
            ) { editing in
                isScrubbing = editing
                if !editing {
                    let page = Int(scrubberPage)
                    jumpToPage = page
                    scheduleScrubberHide()
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    // MARK: - Reading HUD

    private var readingHUD: some View {
        let remaining = max(totalPages - currentPage, 0)
        let timeText = ReadingTimeEstimator.formattedRemainingTime(
            currentPage: currentPage,
            totalPages: totalPages
        )
        return HStack(spacing: 8) {
            Text("\(currentPage) / \(totalPages)")
            Text("·")
            Text("残り\(remaining)ページ")
            Text("·")
            Text(timeText)
        }
        .font(.caption.monospacedDigit())
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    // MARK: - Helpers

    private func updateHorizontalPages() {
        guard contentHeight > 0 else { return }
        let viewportHeight = UIScreen.main.bounds.height
        let estimatedTotal = max(Int(ceil(contentHeight / viewportHeight)), 1)
        let estimatedCurrent = min(max(Int(ceil(scrollOffset / viewportHeight)) + 1, 1), estimatedTotal)
        totalPages = estimatedTotal
        currentPage = estimatedCurrent
        if !isScrubbing {
            scrubberPage = Double(estimatedCurrent)
        }
    }

    private func toggleScrubber() {
        showScrubber.toggle()
        if showScrubber {
            scheduleScrubberHide()
        }
    }

    private func scheduleScrubberHide() {
        scrubberHideTask?.cancel()
        guard showScrubber, !isScrubbing else { return }
        scrubberHideTask = Task {
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled, !isScrubbing else { return }
            showScrubber = false
        }
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static let defaultValue: Double = 0
    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = nextValue()
    }
}

private struct ContentHeightKey: PreferenceKey {
    static let defaultValue: Double = 0
    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = nextValue()
    }
}
