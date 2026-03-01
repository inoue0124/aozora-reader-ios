import Foundation
import SwiftUI

actor CoverImageService {
    static let shared = CoverImageService()

    /// プリセットキャッシュ（bookId → CoverDesignPreset）
    private var presetCache: [Int: CoverDesignPreset] = [:]

    private init() {}

    /// Book からプリセットを取得（キャッシュ付き）
    func preset(for book: Book) -> CoverDesignPreset {
        if let cached = presetCache[book.id] {
            return cached
        }
        let workType = WorkType.from(classification: book.classification)
        let result = CoverDesignPreset.preset(for: workType, title: book.title)
        presetCache[book.id] = result
        return result
    }

    /// タイトルと分類からプリセットを取得（フォールバック付き）
    func preset(title: String, classification: String) -> CoverDesignPreset {
        let workType = WorkType.from(classification: classification)
        return CoverDesignPreset.preset(for: workType, title: title)
    }

    /// フォールバック：分類情報がない場合のプリセット
    func fallbackPreset(title: String) -> CoverDesignPreset {
        CoverDesignPreset.preset(for: .other, title: title)
    }

    /// キャッシュクリア
    func clearCache() {
        presetCache.removeAll()
    }
}
