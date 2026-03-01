import SwiftUI

struct StarRatingView: View {
    let rating: Int
    var size: Font = .caption

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1 ... 5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(size)
                    .foregroundStyle(star <= rating ? AppColors.rating : AppColors.ratingInactive)
            }
        }
    }
}
