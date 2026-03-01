import Foundation
import SwiftUI

enum FontSizeLevel: Int, CaseIterable, Sendable, Codable {
    case small = 14
    case medium = 17
    case large = 21
    case extraLarge = 26

    var label: String {
        switch self {
        case .small: "小"
        case .medium: "中"
        case .large: "大"
        case .extraLarge: "特大"
        }
    }

    var font: Font {
        .system(size: CGFloat(rawValue))
    }
}

enum LineSpacingLevel: Int, CaseIterable, Sendable, Codable {
    case narrow = 4
    case normal = 8
    case wide = 14

    var label: String {
        switch self {
        case .narrow: "狭い"
        case .normal: "普通"
        case .wide: "広い"
        }
    }

    var value: CGFloat {
        CGFloat(rawValue)
    }
}

enum PaddingLevel: Int, CaseIterable, Sendable, Codable {
    case narrow = 8
    case normal = 16
    case wide = 32

    var label: String {
        switch self {
        case .narrow: "狭い"
        case .normal: "普通"
        case .wide: "広い"
        }
    }

    var value: CGFloat {
        CGFloat(rawValue)
    }
}

enum ReadingTheme: String, CaseIterable, Sendable, Codable {
    case light
    case dark
    case sepia
    case matcha
    case yozakura

    var label: String {
        switch self {
        case .light: "ライト"
        case .dark: "ダーク"
        case .sepia: "セピア"
        case .matcha: "抹茶"
        case .yozakura: "夜桜"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .light: .white
        case .dark: Color(red: 0.1, green: 0.1, blue: 0.1)
        case .sepia: Color(red: 0.96, green: 0.93, blue: 0.86)
        case .matcha: Color(red: 0.91, green: 0.94, blue: 0.89)
        case .yozakura: Color(red: 0.16, green: 0.11, blue: 0.21)
        }
    }

    var textColor: Color {
        switch self {
        case .light: .black
        case .dark: .white
        case .sepia: Color(red: 0.3, green: 0.2, blue: 0.1)
        case .matcha: Color(red: 0.18, green: 0.23, blue: 0.18)
        case .yozakura: Color(red: 0.91, green: 0.84, blue: 0.94)
        }
    }
}

enum FontFamily: String, CaseIterable, Sendable, Codable {
    case hiraMincho
    case hiraKaku
    case yuMincho
    case tsukushiMaruGo

    var label: String {
        switch self {
        case .hiraMincho: "ヒラギノ明朝"
        case .hiraKaku: "ヒラギノ角ゴ"
        case .yuMincho: "游明朝"
        case .tsukushiMaruGo: "筑紫A丸ゴシック"
        }
    }

    var cssValue: String {
        switch self {
        case .hiraMincho: "'Hiragino Mincho ProN', serif"
        case .hiraKaku: "'Hiragino Sans', 'Hiragino Kaku Gothic ProN', sans-serif"
        case .yuMincho: "'YuMincho', 'Yu Mincho', serif"
        case .tsukushiMaruGo: "'TsukuARdGothic-Regular', 'Tsukushi A Round Gothic', sans-serif"
        }
    }

    var uiFontName: String {
        switch self {
        case .hiraMincho: "HiraMinProN-W3"
        case .hiraKaku: "HiraginoSans-W3"
        case .yuMincho: "YuMincho"
        case .tsukushiMaruGo: "TsukuARdGothic-Regular"
        }
    }
}

enum ReadingLayoutMode: String, CaseIterable, Sendable, Codable {
    case horizontalScroll
    case verticalPaged

    var label: String {
        switch self {
        case .horizontalScroll: "横書きスクロール"
        case .verticalPaged: "縦書きページ"
        }
    }
}

@Observable
final class ReadingSettings: @unchecked Sendable {
    static let shared = ReadingSettings()

    var layoutMode: ReadingLayoutMode {
        didSet { save() }
    }

    var fontSize: FontSizeLevel {
        didSet { save() }
    }

    var lineSpacing: LineSpacingLevel {
        didSet { save() }
    }

    var padding: PaddingLevel {
        didSet { save() }
    }

    var theme: ReadingTheme {
        didSet { save() }
    }

    var showReadingHUD: Bool {
        didSet { save() }
    }

    var fontFamily: FontFamily {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard
    private let layoutModeKey = "readingLayoutMode"
    private let fontSizeKey = "readingFontSize"
    private let lineSpacingKey = "readingLineSpacing"
    private let paddingKey = "readingPadding"
    private let themeKey = "readingTheme"
    private let showReadingHUDKey = "readingShowHUD"
    private let fontFamilyKey = "readingFontFamily"

    private init() {
        layoutMode = ReadingLayoutMode(rawValue: defaults.string(forKey: layoutModeKey) ?? "") ?? .verticalPaged
        fontSize = FontSizeLevel(rawValue: defaults.integer(forKey: fontSizeKey)) ?? .medium
        lineSpacing = LineSpacingLevel(rawValue: defaults.integer(forKey: lineSpacingKey)) ?? .normal
        padding = PaddingLevel(rawValue: defaults.integer(forKey: paddingKey)) ?? .normal
        theme = ReadingTheme(rawValue: defaults.string(forKey: themeKey) ?? "") ?? .light
        showReadingHUD = defaults.object(forKey: showReadingHUDKey) as? Bool ?? true
        fontFamily = FontFamily(rawValue: defaults.string(forKey: fontFamilyKey) ?? "") ?? .hiraMincho
    }

    private func save() {
        defaults.set(layoutMode.rawValue, forKey: layoutModeKey)
        defaults.set(fontSize.rawValue, forKey: fontSizeKey)
        defaults.set(lineSpacing.rawValue, forKey: lineSpacingKey)
        defaults.set(padding.rawValue, forKey: paddingKey)
        defaults.set(theme.rawValue, forKey: themeKey)
        defaults.set(showReadingHUD, forKey: showReadingHUDKey)
        defaults.set(fontFamily.rawValue, forKey: fontFamilyKey)
    }
}
