@testable import App
import Foundation
import Testing

@Suite("SummaryQualityGuard 品質検証")
struct SummaryQualityGuardTests {
    private let qualityGuard = SummaryQualityGuard()

    // MARK: - Length Control

    @Test("短文: 120文字未満でもそのまま返す")
    func shortTextPassesThrough() {
        let text = String(repeating: "あ", count: 80)
        let result = qualityGuard.validate(text)
        #expect(result == .valid(text))
    }

    @Test("範囲内: 120〜220文字はそのまま返す")
    func withinRangePassesThrough() {
        let text = String(repeating: "あ", count: 150)
        let result = qualityGuard.validate(text)
        #expect(result == .valid(text))
    }

    @Test("長文: 220文字超は切り詰め+省略記号")
    func longTextIsTruncated() {
        let text = String(repeating: "あ", count: 300)
        if case let .valid(cleaned) = qualityGuard.validate(text) {
            #expect(cleaned.count <= SummaryQualityGuard.lengthRange.upperBound)
            #expect(cleaned.hasSuffix("……"))
        } else {
            Issue.record("Expected .valid result")
        }
    }

    @Test("長文: 句点位置で切り詰め")
    func longTextTruncatesAtSentenceBoundary() {
        let prefix = String(repeating: "あ", count: 150) + "。"
        let suffix = String(repeating: "い", count: 100)
        let text = prefix + suffix
        if case let .valid(cleaned) = qualityGuard.validate(text) {
            #expect(cleaned.contains("。"))
            #expect(cleaned.count <= SummaryQualityGuard.lengthRange.upperBound)
        } else {
            Issue.record("Expected .valid result")
        }
    }

    // MARK: - NG Pattern Guard

    @Test("NG: 犯人は を含む文は拒否される")
    func rejectsHanninPattern() {
        let text = String(repeating: "あ", count: 100) + "犯人は太郎だった。" + String(repeating: "い", count: 50)
        #expect(qualityGuard.validate(text) == .rejected)
    }

    @Test("NG: ネタバレ を含む文は拒否される")
    func rejectsNetabarePattern() {
        let text = String(repeating: "あ", count: 100) + "ネタバレ注意" + String(repeating: "い", count: 50)
        #expect(qualityGuard.validate(text) == .rejected)
    }

    @Test("NG: 殺された を含む文は拒否される")
    func rejectsKorosaretePattern() {
        let text = String(repeating: "あ", count: 100) + "主人公は殺された。" + String(repeating: "い", count: 50)
        #expect(qualityGuard.validate(text) == .rejected)
    }

    @Test("NG: 正体は を含む文は拒否される")
    func rejectsShotaiPattern() {
        let text = String(repeating: "あ", count: 100) + "彼の正体は実は" + String(repeating: "い", count: 50)
        #expect(qualityGuard.validate(text) == .rejected)
    }

    @Test("安全: NGパターン非含有はそのまま返す")
    func safeTextPasses() {
        let text = "青年は故郷を離れ、東京の大学に通い始める。都会の喧騒の中で、新しい友人や恩師との出会いを通じて成長していく物語です。彼の日常は穏やかに過ぎていくが、やがて大きな転機が訪れることになる。"
        if case .valid = qualityGuard.validate(text) {
            // pass
        } else {
            Issue.record("Expected .valid result")
        }
    }

    // MARK: - Style Unification

    @Test("文体統一: です/ます優勢時にであるを変換")
    func unifiesStyleToDesumasu() {
        let text = "これは物語です。主人公は旅に出ます。しかし彼は孤独である。最後に帰還しました。青春の日々を描いた名作です。読者を魅了する美しい文体です。"
        if case let .valid(cleaned) = qualityGuard.validate(text) {
            #expect(!cleaned.contains("である。"))
        } else {
            Issue.record("Expected .valid result")
        }
    }

    @Test("文体統一: である優勢時にです/ますを変換")
    func unifiesStyleToDearu() {
        let text = "これは物語である。主人公は旅に出る。しかし彼は孤独である。彼の旅路は困難であった。だが希望もある。しかし展開は悲しいです。最後の場面は印象的であった。"
        if case let .valid(cleaned) = qualityGuard.validate(text) {
            #expect(!cleaned.contains("です。"))
        } else {
            Issue.record("Expected .valid result")
        }
    }

    @Test("文体統一: 混在なしはそのまま返す")
    func noMixedStylePassesThrough() {
        let text = "これは物語である。主人公は旅に出た。しかし彼は孤独であった。帰還した彼は静かに暮らしている。その日々は穏やかであった。彼の人生は波乱に満ちたものであった。"
        if case let .valid(cleaned) = qualityGuard.validate(text) {
            #expect(cleaned == text)
        } else {
            Issue.record("Expected .valid result")
        }
    }

    // MARK: - Edge Cases

    @Test("空文字は拒否される")
    func emptyTextIsRejected() {
        #expect(qualityGuard.validate("") == .rejected)
    }

    @Test("空白のみは拒否される")
    func whitespaceOnlyIsRejected() {
        #expect(qualityGuard.validate("   \n\t  ") == .rejected)
    }
}
