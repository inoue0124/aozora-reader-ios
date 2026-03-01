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

    // Pre-compiled regexes for performance
    private let compiledNGPatterns: [NSRegularExpression]
    private let compiledDesumasuPatterns: [NSRegularExpression]
    private let compiledDearuPatterns: [NSRegularExpression]

    private let convertDesumasuRules: [(NSRegularExpression, String)]
    private let convertDearuRules: [(NSRegularExpression, String)]

    init() {
        compiledNGPatterns = Self.ngPatterns.compactMap { try? NSRegularExpression(pattern: $0) }
        compiledDesumasuPatterns = Self.desumasuPatterns.compactMap { try? NSRegularExpression(pattern: $0) }
        compiledDearuPatterns = Self.dearuPatterns.compactMap { try? NSRegularExpression(pattern: $0) }

        let desumasuReplacements: [(String, String)] = [
            ("である(。)", "です$1"),
            ("であった(。)", "でした$1"),
            ("ではない", "ではありません"),
            ("であろう", "でしょう"),
        ]
        convertDesumasuRules = desumasuReplacements.compactMap { pattern, replacement in
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
            return (regex, replacement)
        }

        let dearuReplacements: [(String, String)] = [
            ("です(。)", "である$1"),
            ("でした(。)", "であった$1"),
            ("ではありません", "ではない"),
            ("でしょう", "であろう"),
            ("ました(。)", "た$1"),
        ]
        convertDearuRules = dearuReplacements.compactMap { pattern, replacement in
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
            return (regex, replacement)
        }
    }

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
        let range = NSRange(text.startIndex..., in: text)
        for regex in compiledNGPatterns where regex.firstMatch(in: text, range: range) != nil {
            return true
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
        let range = NSRange(text.startIndex..., in: text)
        let desumasuCount = countMatches(text, range: range, patterns: compiledDesumasuPatterns)
        let dearuCount = countMatches(text, range: range, patterns: compiledDearuPatterns)

        guard desumasuCount > 0, dearuCount > 0 else { return text }

        if desumasuCount >= dearuCount {
            return applyReplacements(text, rules: convertDesumasuRules)
        } else {
            return applyReplacements(text, rules: convertDearuRules)
        }
    }

    private func countMatches(_ text: String, range: NSRange, patterns: [NSRegularExpression]) -> Int {
        var count = 0
        for regex in patterns {
            count += regex.numberOfMatches(in: text, range: range)
        }
        return count
    }

    private func applyReplacements(_ text: String, rules: [(NSRegularExpression, String)]) -> String {
        var result = text
        for (regex, replacement) in rules {
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: replacement)
        }
        return result
    }
}
