import SwiftUI

struct AuthorDetailScreen: View {
    let person: Person

    var body: some View {
        Text(person.fullName)
            .navigationTitle("著者詳細")
    }
}
