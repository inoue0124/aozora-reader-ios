import SwiftUI

/// ジャンル別表紙デザインプリセット
struct CoverDesignPreset: Sendable {
    let palette: ColorPalette
    let pattern: CoverPattern
    let titleFont: Font.Design
    let authorFont: Font.Design

    struct ColorPalette: Sendable {
        let background: (red: Double, green: Double, blue: Double)
        let gradientEnd: (red: Double, green: Double, blue: Double)
        let accent: (red: Double, green: Double, blue: Double)
        let text: (red: Double, green: Double, blue: Double)

        var backgroundColor: Color {
            Color(red: background.red, green: background.green, blue: background.blue)
        }

        var gradientEndColor: Color {
            Color(red: gradientEnd.red, green: gradientEnd.green, blue: gradientEnd.blue)
        }

        var accentColor: Color {
            Color(red: accent.red, green: accent.green, blue: accent.blue)
        }

        var textColor: Color {
            Color(red: text.red, green: text.green, blue: text.blue)
        }
    }

    enum CoverPattern: Sendable {
        case literary // 文芸 — 帯+装飾ライン
        case poetry // 詩 — 余白と繊細なライン
        case children // 児童文学 — 丸みのあるポップ
        case drama // 戯曲 — 劇場カーテン風
        case essay // エッセイ — ミニマル横書き
        case classic // デフォルト
    }

    // MARK: - Palette Variations per genre

    private static let literaryPalettes: [ColorPalette] = [
        ColorPalette(
            background: (0.10, 0.12, 0.22),
            gradientEnd: (0.18, 0.22, 0.38),
            accent: (0.85, 0.72, 0.42),
            text: (0.95, 0.93, 0.88)
        ),
        ColorPalette(
            background: (0.22, 0.14, 0.12),
            gradientEnd: (0.38, 0.22, 0.18),
            accent: (0.90, 0.80, 0.55),
            text: (0.95, 0.93, 0.88)
        ),
        ColorPalette(
            background: (0.08, 0.18, 0.15),
            gradientEnd: (0.14, 0.30, 0.25),
            accent: (0.82, 0.78, 0.55),
            text: (0.92, 0.95, 0.90)
        ),
        ColorPalette(
            background: (0.18, 0.12, 0.22),
            gradientEnd: (0.30, 0.20, 0.38),
            accent: (0.88, 0.75, 0.50),
            text: (0.95, 0.92, 0.95)
        ),
    ]

    private static let poetryPalettes: [ColorPalette] = [
        ColorPalette(
            background: (0.28, 0.32, 0.48),
            gradientEnd: (0.40, 0.45, 0.62),
            accent: (0.92, 0.90, 0.82),
            text: (0.98, 0.97, 0.95)
        ),
        ColorPalette(
            background: (0.35, 0.30, 0.45),
            gradientEnd: (0.50, 0.42, 0.60),
            accent: (0.95, 0.88, 0.80),
            text: (0.98, 0.96, 0.94)
        ),
        ColorPalette(
            background: (0.25, 0.38, 0.42),
            gradientEnd: (0.38, 0.52, 0.55),
            accent: (0.95, 0.92, 0.85),
            text: (0.98, 0.98, 0.96)
        ),
    ]

    private static let childrenPalettes: [ColorPalette] = [
        ColorPalette(
            background: (0.92, 0.52, 0.20),
            gradientEnd: (0.95, 0.68, 0.32),
            accent: (1.0, 1.0, 1.0),
            text: (1.0, 1.0, 1.0)
        ),
        ColorPalette(
            background: (0.22, 0.62, 0.52),
            gradientEnd: (0.32, 0.75, 0.62),
            accent: (1.0, 0.95, 0.82),
            text: (1.0, 1.0, 1.0)
        ),
        ColorPalette(
            background: (0.55, 0.42, 0.72),
            gradientEnd: (0.68, 0.55, 0.82),
            accent: (1.0, 0.95, 0.85),
            text: (1.0, 1.0, 1.0)
        ),
    ]

    private static let dramaPalettes: [ColorPalette] = [
        ColorPalette(
            background: (0.42, 0.10, 0.12),
            gradientEnd: (0.58, 0.15, 0.18),
            accent: (0.95, 0.85, 0.55),
            text: (0.98, 0.95, 0.90)
        ),
        ColorPalette(
            background: (0.10, 0.10, 0.12),
            gradientEnd: (0.20, 0.18, 0.25),
            accent: (0.95, 0.82, 0.45),
            text: (0.98, 0.96, 0.92)
        ),
    ]

    private static let essayPalettes: [ColorPalette] = [
        ColorPalette(
            background: (0.93, 0.91, 0.86),
            gradientEnd: (0.88, 0.85, 0.80),
            accent: (0.20, 0.22, 0.28),
            text: (0.15, 0.15, 0.18)
        ),
        ColorPalette(
            background: (0.90, 0.92, 0.88),
            gradientEnd: (0.84, 0.87, 0.82),
            accent: (0.22, 0.28, 0.22),
            text: (0.15, 0.18, 0.15)
        ),
    ]

    private static let classicPalettes: [ColorPalette] = [
        ColorPalette(
            background: (0.15, 0.28, 0.40),
            gradientEnd: (0.25, 0.40, 0.52),
            accent: (0.92, 0.85, 0.68),
            text: (0.95, 0.95, 0.92)
        ),
        ColorPalette(
            background: (0.28, 0.22, 0.35),
            gradientEnd: (0.40, 0.32, 0.48),
            accent: (0.88, 0.82, 0.65),
            text: (0.95, 0.93, 0.95)
        ),
    ]

    /// タイトルから安定したハッシュを生成（hashValue は起動ごとに変わるため独自実装）
    static func stableHash(for string: String) -> Int {
        var hash = 5381
        for char in string.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ Int(char)
        }
        return abs(hash)
    }

    /// WorkType とタイトルからプリセットを決定
    static func preset(for workType: WorkType, title: String) -> Self {
        let hash = Self.stableHash(for: title)

        switch workType {
        case .novel, .shortStory:
            let palette = Self.literaryPalettes[hash % Self.literaryPalettes.count]
            return Self(palette: palette, pattern: .literary, titleFont: .serif, authorFont: .default)
        case .poetry:
            let palette = Self.poetryPalettes[hash % Self.poetryPalettes.count]
            return Self(palette: palette, pattern: .poetry, titleFont: .serif, authorFont: .serif)
        case .childrenLiterature:
            let palette = Self.childrenPalettes[hash % Self.childrenPalettes.count]
            return Self(palette: palette, pattern: .children, titleFont: .rounded, authorFont: .rounded)
        case .drama:
            let palette = Self.dramaPalettes[hash % Self.dramaPalettes.count]
            return Self(palette: palette, pattern: .drama, titleFont: .serif, authorFont: .default)
        case .essay:
            let palette = Self.essayPalettes[hash % Self.essayPalettes.count]
            return Self(palette: palette, pattern: .essay, titleFont: .default, authorFont: .default)
        case .other:
            let palette = Self.classicPalettes[hash % Self.classicPalettes.count]
            return Self(palette: palette, pattern: .classic, titleFont: .serif, authorFont: .default)
        }
    }

    /// フォールバック用のデフォルトプリセット
    static let fallback = Self(
        palette: Self.classicPalettes[0],
        pattern: .classic,
        titleFont: .serif,
        authorFont: .default
    )
}
