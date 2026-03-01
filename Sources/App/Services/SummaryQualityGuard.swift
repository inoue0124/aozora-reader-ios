import Foundation

struct SummaryQualityGuard: Sendable {
    enum Result: Sendable, Equatable {
        case valid(String)
        case rejected
    }

    static let lengthRange = 120 ... 220
    static let fallbackSuffix = "……"

    private static let ngPatterns: [String] = [
        "死ぬ", "死んだ", "殺す", "殺される", "殺された",
        "犯人は", "真犯人", "正体は", "ネタバレ",
        "結末は", "最後に.*死", "実は.*だった",
    ]

    private static let desumasuPatterns: [String] = [
        "です[。、）)]", "ます[。、）)]", "ません", "でした[。、）)]",
        "ました[。、）)]", "でしょう", "ましょう",
    ]

    private static let dearuPatterns: [String] = [
        "である[。、）)]", "であった[。、）)]", "ではない", "であろう",
        "だった[。、）)]", "ている[。、）)]", "られる[。、）)]",
    ]

    func validate(_ text: String) -> Result {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return .rejected }

        if containsNGPattern(cleaned) {
            return .rejected
        }

        let adjusted = adjustLength(cleaned)
        let unified = unifyStyle(adjusted)
        return .valid(unified)
    }

    private func containsNGPattern(_ text: String) -> Bool {
        for pattern in Self.ngPatterns {
            if
                let regex = try? NSRegularExpression(pattern: pattern),
                regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
            {
                return true
            }
        }
        return false
    }

    private func adjustLength(_ text: String) -> String {
        if text.count > Self.lengthRange.upperBound {
            let endIdx = text.index(text.startIndex, offsetBy: Self.lengthRange.upperBound - Self.fallbackSuffix.count)
            let truncated = String(text[..<endIdx])
            let trimmed = truncateAtSentenceBoundary(truncated)
            return trimmed + Self.fallbackSuffix
        }
        return text
    }

    private func truncateAtSentenceBoundary(_ text: String) -> String {
        let sentenceEndings: [Character] = ["。", "、", "」", "）"]
        if let lastIdx = text.lastIndex(where: { sentenceEndings.contains($0) }) {
            let candidate = String(text[...lastIdx])
            if candidate.count >= Self.lengthRange.lowerBound / 2 {
                return candidate
            }
        }
        return text
    }

    private func unifyStyle(_ text: String) -> String {
        let desumasuCount = countMatches(text, patterns: Self.desumasuPatterns)
        let dearuCount = countMatches(text, patterns: Self.dearuPatterns)

        guard desumasuCount > 0, dearuCount > 0 else { return text }

        if desumasuCount >= dearuCount {
            return convertToDesumasu(text)
        } else {
            return convertToDearu(text)
        }
    }

    private func countMatches(_ text: String, patterns: [String]) -> Int {
        var count = 0
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                count += regex.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
            }
        }
        return count
    }

    private func convertToDesumasu(_ text: String) -> String {
        var result = text
        result = replacePattern(result, pattern: "である(。)", with: "です$1")
        result = replacePattern(result, pattern: "であった(。)", with: "でした$1")
        result = replacePattern(result, pattern: "ではない", with: "ではありません")
        result = replacePattern(result, pattern: "であろう", with: "でしょう")
        return result
    }

    private func convertToDearu(_ text: String) -> String {
        var result = text
        result = replacePattern(result, pattern: "です(。)", with: "である$1")
        result = replacePattern(result, pattern: "でした(。)", with: "であった$1")
        result = replacePattern(result, pattern: "ではありません", with: "ではない")
        result = replacePattern(result, pattern: "でしょう", with: "であろう")
        result = replacePattern(result, pattern: "ました(。)", with: "た$1")
        return result
    }

    private func replacePattern(_ text: String, pattern: String, with replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        return regex.stringByReplacingMatches(
            in: text,
            range: NSRange(text.startIndex..., in: text),
            withTemplate: replacement
        )
    }
}
