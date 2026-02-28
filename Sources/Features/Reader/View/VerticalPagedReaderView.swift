import SwiftUI
import WebKit

struct VerticalPagedReaderView: UIViewRepresentable {
    let content: AttributedString
    let settings: ReadingSettings
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

        let plain = String(content.characters)
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "\n", with: "<br>")

        let css = """
        <style>
        :root { color-scheme: light dark; }
        html, body {
          margin: 0;
          padding: 0;
          width: 100%;
          height: 100%;
          overflow: hidden;
          background: \(settings.theme.hexBackground);
          color: \(settings.theme.hexText);
          font-family: -apple-system, 'Hiragino Mincho ProN', serif;
          -webkit-user-select: text;
        }
        #reader {
          box-sizing: border-box;
          width: 100vw;
          height: 100vh;
          padding: \(Int(settings.padding.value))px;
          writing-mode: vertical-rl;
          text-orientation: mixed;
          font-size: \(settings.fontSize.rawValue)px;
          line-height: \(Double(settings.fontSize.rawValue) + settings.lineSpacing.value)px;
          overflow-x: auto;
          overflow-y: hidden;
          scroll-snap-type: x mandatory;
          column-fill: auto;
          column-width: calc(100vw - \(Int(settings.padding.value * 2))px);
          column-gap: 0;
          word-break: keep-all;
        }
        </style>
        """

        let html = """
        <html>
        <head>
        <meta name='viewport' content='width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no'>
        \(css)
        </head>
        <body>
          <div id='reader'>\(plain)</div>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScroll: onScroll, onPageChanged: onPageChanged)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, UIScrollViewDelegate {
        var onScroll: (Double) -> Void
        var onPageChanged: (_ current: Int, _ total: Int) -> Void
        weak var webView: WKWebView?

        init(onScroll: @escaping (Double) -> Void, onPageChanged: @escaping (_ current: Int, _ total: Int) -> Void) {
            self.onScroll = onScroll
            self.onPageChanged = onPageChanged
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let offset = scrollView.contentOffset.x
            onScroll(offset)

            let pageWidth = max(scrollView.bounds.width, 1)
            let totalPages = max(Int(ceil(scrollView.contentSize.width / pageWidth)), 1)
            let currentPage = min(max(Int(round(offset / pageWidth)) + 1, 1), totalPages)
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
                guard let self,
                      let dict = result as? [String: Any],
                      let width = dict["width"] as? Double,
                      let viewport = dict["viewport"] as? Double
                else { return }

                let total = max(Int(ceil(width / max(viewport, 1))), 1)
                self.onPageChanged(1, total)
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
