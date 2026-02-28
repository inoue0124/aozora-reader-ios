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
                profileSection
                worksSection
            }
            .padding()
        }
        .navigationTitle("著者詳細")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    @ViewBuilder
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
            } else {
                Image(systemName: "person.crop.rectangle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 130)
                    .foregroundStyle(.quaternary)
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

    @ViewBuilder
    private var profileSection: some View {
        if !person.lastNameRomaji.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("ローマ字表記")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(person.lastNameRomaji) \(person.firstNameRomaji)")
                    .font(.subheadline)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var worksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("作品一覧（\(viewModel.works.count)件）")
                .font(.headline)

            if viewModel.isLoading {
                ProgressView()
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
}
