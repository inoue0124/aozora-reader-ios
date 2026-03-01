import SwiftUI

struct AuthorDetailScreen: View {
    let person: Person
    @State private var viewModel: AuthorDetailViewModel
    @State private var isBiographyExpanded = false
    @State private var isTimelineExpanded = false
    @State private var isWorksExpanded = false

    init(person: Person) {
        self.person = person
        _viewModel = State(initialValue: AuthorDetailViewModel(person: person))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                portraitSection
                biographySection
                representativeWorksSection
                timelineSection
                worksSection
                sourcesSection
            }
            .padding()
        }
        .navigationTitle("著者詳細")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    // MARK: - Portrait

    private var portraitSection: some View {
        HStack(spacing: 16) {
            if let url = viewModel.portraitURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        portraitFallback
                    default:
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary)
                            .shimmer()
                    }
                }
                .frame(width: 100, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("\(person.fullName)の肖像")
            } else {
                portraitFallback
                    .accessibilityLabel("肖像画なし")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(person.fullName)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(person.fullNameYomi)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(person.lifespan)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let source = viewModel.portraitSource {
                    Text(source)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    private var portraitFallback: some View {
        Image(systemName: "person.crop.rectangle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 130)
            .foregroundStyle(.quaternary)
    }

    // MARK: - Biography

    private var biographySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("来歴")
                .font(.headline)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if let bio = viewModel.biography {
                Text(bio.extract)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .lineLimit(isBiographyExpanded ? nil : 5)

                if bio.extract.count > 200 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isBiographyExpanded.toggle()
                        }
                    } label: {
                        Text(isBiographyExpanded ? "閉じる" : "もっと見る")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("来歴情報はありません")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("来歴セクション")
    }

    // MARK: - Representative Works

    private var representativeWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("代表作")
                .font(.headline)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.representativeWorks.isEmpty {
                Text("代表作の情報はありません")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(viewModel.representativeWorks) { book in
                    NavigationLink {
                        WorkDetailScreen(book: book)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "book")
                                .foregroundStyle(AppColors.accent)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if !book.subtitle.isEmpty {
                                    Text(book.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("代表作: \(book.title)")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("年表")
                .font(.headline)

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.timeline.isEmpty {
                Text("年表情報はありません")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                let entries = viewModel.timeline
                let visibleEntries = isTimelineExpanded ? entries : Array(entries.prefix(5))

                VStack(spacing: 0) {
                    ForEach(Array(visibleEntries.enumerated()), id: \.element.id) { index, entry in
                        TimelineEntryRow(
                            entry: entry,
                            isFirst: index == 0,
                            isLast: index == visibleEntries.count - 1
                        )
                    }
                }

                if entries.count > 5 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isTimelineExpanded.toggle()
                        }
                    } label: {
                        Text(isTimelineExpanded ? "閉じる" : "もっと見る（\(entries.count - 5)件）")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Works List

    private var worksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("作品一覧（\(viewModel.works.count)件）")
                .font(.headline)

            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.works.isEmpty {
                Text("作品情報はありません")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                let visibleWorks = isWorksExpanded ? viewModel.works : Array(viewModel.works.prefix(5))

                ForEach(visibleWorks) { book in
                    NavigationLink {
                        WorkDetailScreen(book: book)
                    } label: {
                        HStack(spacing: 12) {
                            BookCoverView(book: book, width: 40, height: 56)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(book.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(2)
                                if !book.subtitle.isEmpty {
                                    Text(book.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    if book.id != visibleWorks.last?.id {
                        Divider()
                    }
                }

                if viewModel.works.count > 5 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isWorksExpanded.toggle()
                        }
                    } label: {
                        Text(isWorksExpanded ? "閉じる" : "すべて表示（\(viewModel.works.count)件）")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Sources

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("出典")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Text("作品データ: 青空文庫（aozora.gr.jp）")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            if viewModel.portraitSource != nil {
                Text("肖像画像: Wikimedia Commons")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if viewModel.biography != nil {
                Text("来歴情報: Wikipedia（ja.wikipedia.org）")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("出典情報")
    }
}

// MARK: - Timeline Entry Row

private struct TimelineEntryRow: View {
    let entry: AuthorTimelineEntry
    let isFirst: Bool
    let isLast: Bool

    private var dotSize: CGFloat {
        (isFirst || isLast) ? 10 : 8
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(entry.year)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.timeline)
                .frame(width: 44, alignment: .trailing)

            ZStack {
                if !isLast {
                    VStack {
                        Spacer()
                            .frame(height: dotSize / 2 + 4)
                        Rectangle()
                            .fill(AppColors.timeline.opacity(0.3))
                            .frame(width: 2)
                    }
                }

                VStack {
                    Circle()
                        .fill(AppColors.timeline)
                        .frame(width: dotSize, height: dotSize)
                        .padding(.top, 4)
                    Spacer(minLength: 0)
                }
            }
            .frame(width: 10)

            Text(entry.label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, isLast ? 0 : 12)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.year)年、\(entry.label)")
    }
}
