import SwiftUI
import WebKit

struct VerticalPagedReaderView: UIViewRepresentable {
    let content: AttributedString
    let settings: ReadingSettings
    let savedPageRatio: Double
    @Binding var jumpToPage: Int?
    let onScroll: (Double) -> Void
    let onPageChanged: (_ current: Int, _ total: Int) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isPagingEnabled = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.alwaysBounceHorizontal = true
        webView.scrollView.alwaysBounceVertical = false
        webView.navigationDelegate = context.coordinator
        webView.scrollView.delegate = context.coordinator
        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onScroll = onScroll
        context.coordinator.onPageChanged = onPageChanged

        if let page = jumpToPage {
            DispatchQueue.main.async {
                jumpToPage = nil
            }
            context.coordinator.scrollToPage(page, in: webView)
            return
        }

        let html = buildHTML()
        guard html != context.coordinator.lastLoadedHTML else { return }
        context.coordinator.lastLoadedHTML = html
        context.coordinator.isLoadingHTML = true
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func buildHTML() -> String {
        let plain = String(content.characters)
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "\n", with: "<br>")

        let pad = Int(settings.padding.value)
        let lineHeight = Double(settings.fontSize.rawValue) + settings.lineSpacing.value

        return """
        <html>
        <head>
        <meta name='viewport' content='width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no'>
        <style>
        :root { color-scheme: light dark; }
        html, body {
          margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden;
          background: \(settings.theme.hexBackground);
          color: \(settings.theme.hexText);
          font-family: -apple-system, 'Hiragino Mincho ProN', serif;
          -webkit-user-select: text;
        }
        #reader {
          box-sizing: border-box; width: 100vw; height: 100vh; padding: \(pad)px;
          writing-mode: vertical-rl; text-orientation: mixed;
          font-size: \(settings.fontSize.rawValue)px; line-height: \(lineHeight)px;
          overflow-x: auto; overflow-y: hidden;
          scroll-snap-type: x mandatory; column-fill: auto;
          column-width: calc(100vw - \(pad * 2)px); column-gap: 0;
          line-break: strict; overflow-wrap: break-word;
        }
        </style>
        </head>
        <body><div id='reader'>\(plain)</div></body>
        </html>
        """
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            initialPageRatio: savedPageRatio,
            onScroll: onScroll,
            onPageChanged: onPageChanged
        )
    }

    final class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        var onScroll: (Double) -> Void
        var onPageChanged: (_ current: Int, _ total: Int) -> Void
        weak var webView: WKWebView?
        var isLoadingHTML = false
        var lastLoadedHTML: String?
        private var currentPageRatio: Double

        init(
            initialPageRatio: Double,
            onScroll: @escaping (Double) -> Void,
            onPageChanged: @escaping (_ current: Int, _ total: Int) -> Void
        ) {
            // Ignore legacy pixel-based bookmarks (values > 1.0)
            currentPageRatio = initialPageRatio <= 1 ? initialPageRatio : 0
            self.onScroll = onScroll
            self.onPageChanged = onPageChanged
        }

        func scrollToPage(_ page: Int, in webView: WKWebView) {
            let scrollView = webView.scrollView
            let pageWidth = max(scrollView.bounds.width, 1)
            let contentWidth = scrollView.contentSize.width
            let totalPages = max(Int(ceil(contentWidth / pageWidth)), 1)
            let targetPage = min(max(page - 1, 0), totalPages - 1)
            let offset = Double(targetPage) * pageWidth
            scrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard !isLoadingHTML else { return }

            let offset = scrollView.contentOffset.x
            let pageWidth = max(scrollView.bounds.width, 1)
            let contentWidth = scrollView.contentSize.width
            let totalPages = max(Int(ceil(contentWidth / pageWidth)), 1)
            let currentPage = min(max(Int(round(offset / pageWidth)) + 1, 1), totalPages)

            let ratio = totalPages > 1 ? Double(currentPage - 1) / Double(totalPages - 1) : 0
            currentPageRatio = ratio
            onScroll(ratio)
            onPageChanged(currentPage, totalPages)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = """
            (function() {
              var el = document.getElementById('reader');
              return { width: el.scrollWidth, viewport: el.clientWidth };
            })();
            """

            webView.evaluateJavaScript(js) { [weak self] result, _ in
                guard
                    let self,
                    let dict = result as? [String: Any],
                    let width = dict["width"] as? Double,
                    let viewport = dict["viewport"] as? Double
                else { return }

                let pageWidth = max(viewport, 1)
                let total = max(Int(ceil(width / pageWidth)), 1)

                if currentPageRatio > 0, total > 1 {
                    let targetPage = Int(round(currentPageRatio * Double(total - 1)))
                    let snappedOffset = Double(targetPage) * pageWidth
                    webView.scrollView.setContentOffset(
                        CGPoint(x: snappedOffset, y: 0), animated: false
                    )
                    let page = min(max(targetPage + 1, 1), total)
                    onPageChanged(page, total)
                } else {
                    onPageChanged(1, total)
                }

                isLoadingHTML = false
            }
        }
    }
}

private extension ReadingTheme {
    var hexBackground: String {
        switch self {
        case .light: "#FFFFFF"
        case .dark: "#1A1A1A"
        case .sepia: "#F4EEDF"
        }
    }

    var hexText: String {
        switch self {
        case .light: "#111111"
        case .dark: "#F7F7F7"
        case .sepia: "#4A3929"
        }
    }
}
