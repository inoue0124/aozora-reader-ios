import Foundation

enum WorkType: String, CaseIterable, Sendable {
    case shortStory = "短編"
    case novel = "長編"
    case essay = "エッセイ"
    case drama = "戯曲"
    case childrenLiterature = "児童文学"
    case poetry = "詩"
    case other = "その他"

    var displayName: String {
        rawValue
    }

    var iconName: String {
        switch self {
        case .shortStory: "doc.text"
        case .novel: "book.closed"
        case .essay: "pencil.and.outline"
        case .drama: "theatermasks"
        case .childrenLiterature: "book.and.wrench"
        case .poetry: "leaf"
        case .other: "square.grid.2x2"
        }
    }

    /// NDC 分類コードまたはキーワードから WorkType を推定する
    static func from(classification: String) -> Self {
        let cl = classification

        // 詩・詩歌
        if cl.contains("詩") || cl.contains("詩歌") || cl.hasPrefix("911") {
            return .poetry
        }

        // 戯曲・脚本
        if cl.contains("戯曲") || cl.contains("脚本") || cl.hasPrefix("912") {
            return .drama
        }

        // 児童文学・童話
        if cl.contains("童話") || cl.contains("児童") || cl.hasPrefix("K") || cl.hasPrefix("913.8") {
            return .childrenLiterature
        }

        // エッセイ・随筆
        if cl.contains("随筆") || cl.contains("エッセイ") || cl.contains("評論") || cl.hasPrefix("914") {
            return .essay
        }

        // 小説系の判定 - NDC 913 (日本小説)
        if cl.hasPrefix("913") || cl.contains("小説") {
            return .novel
        }

        // 短編（分類名に明示的に含まれる場合）
        if cl.contains("短編") || cl.contains("短篇") {
            return .shortStory
        }

        // NDC 9xx 番台（文学）でキャッチできなかったもの
        if cl.hasPrefix("9") {
            return .novel
        }

        return .other
    }

    /// ホーム棚に表示するタイプ一覧（other を除く）
    static var shelfTypes: [Self] {
        [.shortStory, .novel, .essay, .drama, .childrenLiterature, .poetry]
    }
}
