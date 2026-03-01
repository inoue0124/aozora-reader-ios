import Foundation
import SwiftUI

struct AozoraTextParser: Sendable {
    private static let rubyRegex = try? NSRegularExpression(
        pattern: "<ruby><rb>([^<]*)</rb>[^<]*<rt>([^<]*)</rt>[^<]*</ruby>"
    )

    func parse(html: String) -> AttributedString {
        let cleaned = extractBody(from: html)
        let plainText = stripHTMLTags(cleaned)
        let finalText = cleanAozoraNotations(plainText)

        var result = AttributedString(finalText)
        result.font = .body
        return result
    }

    private func extractBody(from html: String) -> String {
        if
            let mainStart = html.range(of: "<div class=\"main_text\">"),
            let mainEnd = html.range(of: "<div class=\"bibliographical_information\">")
        {
            return String(html[mainStart.upperBound ..< mainEnd.lowerBound])
        }

        if
            let bodyStart = html.range(of: "<body"),
            let bodyTagEnd = html[bodyStart.lowerBound...].range(of: ">"),
            let bodyEnd = html.range(of: "</body>")
        {
            return String(html[bodyTagEnd.upperBound ..< bodyEnd.lowerBound])
        }

        return html
    }

    private func stripHTMLTags(_ text: String) -> String {
        var result = text

        result = result.replacingOccurrences(of: "<br[^>]*>", with: "\n", options: .regularExpression)
        result = result.replacingOccurrences(of: "</p>", with: "\n\n", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "</div>", with: "\n", options: .caseInsensitive)

        if let regex = Self.rubyRegex {
            let nsString = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsString.length))
            for match in matches.reversed() {
                let base = nsString.substring(with: match.range(at: 1))
                let ruby = nsString.substring(with: match.range(at: 2))
                result = (result as NSString).replacingCharacters(
                    in: match.range,
                    with: "\(base)（\(ruby)）"
                )
            }
        }

        result = result.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        result = result.replacingOccurrences(of: "&nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&#[0-9]+;", with: "", options: .regularExpression)

        return result
    }

    private func cleanAozoraNotations(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(
            of: "※［＃[^］]*］",
            with: "",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "［＃[^］]*］",
            with: "",
            options: .regularExpression
        )

        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
