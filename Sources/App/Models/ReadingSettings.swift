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

    var label: String {
        switch self {
        case .light: "ライト"
        case .dark: "ダーク"
        case .sepia: "セピア"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .light: .white
        case .dark: Color(red: 0.1, green: 0.1, blue: 0.1)
        case .sepia: Color(red: 0.96, green: 0.93, blue: 0.86)
        }
    }

    var textColor: Color {
        switch self {
        case .light: .black
        case .dark: .white
        case .sepia: Color(red: 0.3, green: 0.2, blue: 0.1)
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

    private let defaults = UserDefaults.standard
    private let layoutModeKey = "readingLayoutMode"
    private let fontSizeKey = "readingFontSize"
    private let lineSpacingKey = "readingLineSpacing"
    private let paddingKey = "readingPadding"
    private let themeKey = "readingTheme"

    private init() {
        layoutMode = ReadingLayoutMode(rawValue: defaults.string(forKey: layoutModeKey) ?? "") ?? .horizontalScroll
        fontSize = FontSizeLevel(rawValue: defaults.integer(forKey: fontSizeKey)) ?? .medium
        lineSpacing = LineSpacingLevel(rawValue: defaults.integer(forKey: lineSpacingKey)) ?? .normal
        padding = PaddingLevel(rawValue: defaults.integer(forKey: paddingKey)) ?? .normal
        theme = ReadingTheme(rawValue: defaults.string(forKey: themeKey) ?? "") ?? .light
    }

    private func save() {
        defaults.set(layoutMode.rawValue, forKey: layoutModeKey)
        defaults.set(fontSize.rawValue, forKey: fontSizeKey)
        defaults.set(lineSpacing.rawValue, forKey: lineSpacingKey)
        defaults.set(padding.rawValue, forKey: paddingKey)
        defaults.set(theme.rawValue, forKey: themeKey)
    }
}
