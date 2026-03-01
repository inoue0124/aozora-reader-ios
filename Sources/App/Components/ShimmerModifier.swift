import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .redacted(reason: .placeholder)
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.4),
                            .clear,
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: phase * geo.size.width)
                    .blendMode(.sourceAtop)
                }
                .clipped()
            }
            .onAppear {
                withAnimation(
                    .linear(duration: 1.2)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1.5
                }
            }
            .accessibilityLabel("読み込み中")
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
