import SwiftUI

struct BookCoverView: View {
    let title: String
    let authorName: String
    let classification: String
    var width: CGFloat = 60
    var height: CGFloat = 85
    private let preset: CoverDesignPreset

    init(book: Book, width: CGFloat = 60, height: CGFloat = 85) {
        title = book.title
        authorName = book.authorName
        classification = book.classification
        self.width = width
        self.height = height
        let workType = WorkType.from(classification: book.classification)
        preset = CoverDesignPreset.preset(for: workType, title: book.title)
    }

    init(title: String, authorName: String, classification: String = "", width: CGFloat = 60, height: CGFloat = 85) {
        self.title = title
        self.authorName = authorName
        self.classification = classification
        self.width = width
        self.height = height
        let workType = WorkType.from(classification: classification)
        preset = CoverDesignPreset.preset(for: workType, title: title)
    }

    private var isLarge: Bool {
        width >= 90
    }

    private var isMedium: Bool {
        width >= 60
    }

    var body: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: isLarge ? 6 : 4)
                .fill(
                    LinearGradient(
                        colors: [preset.palette.backgroundColor, preset.palette.gradientEndColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Pattern overlay
            patternOverlay

            // Content layout
            contentLayout
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: isLarge ? 6 : 4))
        .overlay(
            // Spine + edge highlight
            HStack(spacing: 0) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .white.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: isLarge ? 4 : 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: isLarge ? 6 : 4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: isLarge ? 6 : 4)
                .strokeBorder(.black.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.25), radius: isLarge ? 6 : 3, x: 2, y: 3)
        .drawingGroup(opaque: false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)、\(authorName)")
    }

    // MARK: - Pattern Overlay

    @ViewBuilder
    private var patternOverlay: some View {
        switch preset.pattern {
        case .literary:
            literaryPattern
        case .poetry:
            poetryPattern
        case .children:
            childrenPattern
        case .drama:
            dramaPattern
        case .essay:
            essayPattern
        case .classic:
            classicPattern
        }
    }

    private var literaryPattern: some View {
        VStack(spacing: 0) {
            Spacer()
            // 帯（obi）装飾
            Rectangle()
                .fill(preset.palette.accentColor.opacity(0.9))
                .frame(height: height * 0.12)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(height: 0.5)
                }
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(.white.opacity(0.3))
                        .frame(height: 0.5)
                }
                .offset(y: -height * 0.18)
            Spacer()
                .frame(height: height * 0.18)
        }
    }

    private var poetryPattern: some View {
        VStack(spacing: 0) {
            // 上部の繊細な装飾ライン
            Spacer()
                .frame(height: height * 0.15)
            HStack {
                Spacer()
                Rectangle()
                    .fill(preset.palette.accentColor.opacity(0.25))
                    .frame(width: width * 0.45, height: 0.5)
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                Rectangle()
                    .fill(preset.palette.accentColor.opacity(0.25))
                    .frame(width: width * 0.45, height: 0.5)
                Spacer()
            }
            Spacer()
                .frame(height: height * 0.15)
        }
    }

    private var childrenPattern: some View {
        GeometryReader { geo in
            // ポップな丸ドット装飾
            let dotSize: CGFloat = isLarge ? 8 : 5
            ForEach(0 ..< 4, id: \.self) { i in
                Circle()
                    .fill(preset.palette.accentColor.opacity(0.12))
                    .frame(width: dotSize, height: dotSize)
                    .position(dotPosition(index: i, in: geo.size))
            }
        }
    }

    private func dotPosition(index: Int, in size: CGSize) -> CGPoint {
        let positions: [(CGFloat, CGFloat)] = [
            (0.8, 0.12), (0.15, 0.25), (0.85, 0.78), (0.2, 0.88),
        ]
        let pos = positions[index % positions.count]
        return CGPoint(x: size.width * pos.0, y: size.height * pos.1)
    }

    private var dramaPattern: some View {
        VStack(spacing: 0) {
            // 劇場カーテン風のトップ装飾
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            preset.palette.accentColor.opacity(0.15),
                            .clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height * 0.2)
            Spacer()
        }
    }

    private var essayPattern: some View {
        VStack(spacing: 0) {
            Spacer()
            // 底部のアクセントライン
            HStack {
                Rectangle()
                    .fill(preset.palette.accentColor.opacity(0.6))
                    .frame(width: width * 0.4, height: 2)
                Spacer()
            }
            .padding(.leading, isLarge ? 14 : 8)
            .padding(.bottom, isLarge ? 14 : 8)
        }
    }

    private var classicPattern: some View {
        VStack(spacing: 0) {
            // シンプルな上下ボーダー
            Rectangle()
                .fill(preset.palette.accentColor.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, isLarge ? 12 : 8)
                .padding(.top, isLarge ? 10 : 6)
            Spacer()
            Rectangle()
                .fill(preset.palette.accentColor.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, isLarge ? 12 : 8)
                .padding(.bottom, isLarge ? 10 : 6)
        }
    }

    // MARK: - Content Layout

    @ViewBuilder
    private var contentLayout: some View {
        if preset.pattern == .essay {
            essayContentLayout
        } else {
            defaultContentLayout
        }
    }

    private var defaultContentLayout: some View {
        VStack(spacing: isLarge ? 6 : 3) {
            Spacer()

            Text(title)
                .font(.system(
                    size: titleFontSize,
                    weight: .bold,
                    design: preset.titleFont
                ))
                .foregroundStyle(preset.palette.textColor)
                .lineLimit(isLarge ? 4 : isMedium ? 3 : 2)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.4), radius: 1, y: 1)

            if isMedium {
                Text(authorName)
                    .font(.system(
                        size: authorFontSize,
                        weight: .medium,
                        design: preset.authorFont
                    ))
                    .foregroundStyle(preset.palette.textColor.opacity(0.75))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, isLarge ? 12 : isMedium ? 8 : 5)
        .padding(.vertical, isLarge ? 14 : 8)
    }

    private var essayContentLayout: some View {
        VStack(alignment: .leading, spacing: isLarge ? 6 : 3) {
            Spacer()
                .frame(height: height * 0.2)

            Text(title)
                .font(.system(
                    size: titleFontSize,
                    weight: .semibold,
                    design: preset.titleFont
                ))
                .foregroundStyle(preset.palette.textColor)
                .lineLimit(isLarge ? 4 : 3)
                .multilineTextAlignment(.leading)

            if isMedium {
                Text(authorName)
                    .font(.system(
                        size: authorFontSize,
                        weight: .regular,
                        design: preset.authorFont
                    ))
                    .foregroundStyle(preset.palette.textColor.opacity(0.65))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, isLarge ? 14 : 8)
        .padding(.vertical, isLarge ? 10 : 6)
    }

    // MARK: - Font Sizes

    private var titleFontSize: CGFloat {
        if isLarge { return 14 }
        if isMedium { return 11 }
        return 9
    }

    private var authorFontSize: CGFloat {
        if isLarge { return 10 }
        return 8
    }
}

// MARK: - Legacy Color Helper (for non-Book contexts)

extension BookCoverView {
    static func coverColor(forTitle title: String) -> Color {
        let workType = WorkType.other
        let preset = CoverDesignPreset.preset(for: workType, title: title)
        return preset.palette.backgroundColor
    }
}
