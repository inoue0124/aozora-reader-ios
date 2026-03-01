import SwiftUI

struct AuthorDetailScreen: View {
    let person: Person
    @State private var viewModel: AuthorDetailViewModel

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
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 100, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel("\(person.fullName)の肖像")
            } else {
                Image(systemName: "person.crop.rectangle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 130)
                    .foregroundStyle(.quaternary)
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
                                .foregroundStyle(.blue)
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
                ForEach(viewModel.timeline) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        Text(entry.year)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                            .frame(width: 44, alignment: .trailing)

                        Circle()
                            .fill(.blue)
                            .frame(width: 8, height: 8)
                            .padding(.top, 4)

                        Text(entry.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(entry.year)年、\(entry.label)")
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
                ForEach(viewModel.works) { book in
                    NavigationLink {
                        WorkDetailScreen(book: book)
                    } label: {
                        BookRowView(book: book)
                    }
                    .buttonStyle(.plain)

                    if book.id != viewModel.works.last?.id {
                        Divider()
                    }
                }
            }
        }
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
