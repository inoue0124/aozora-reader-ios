import SwiftUI
import UIKit

struct VerticalPagedReaderView: UIViewRepresentable {
    let content: AttributedString
    let settings: ReadingSettings
    let onScroll: (Double) -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        textView.isPagingEnabled = true
        textView.alwaysBounceHorizontal = true
        textView.alwaysBounceVertical = false
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.textContainerInset = UIEdgeInsets(
            top: settings.padding.value,
            left: settings.padding.value,
            bottom: settings.padding.value,
            right: settings.padding.value
        )
        textView.textContainer.lineFragmentPadding = 0
        textView.semanticContentAttribute = .forceRightToLeft
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.backgroundColor = UIColor(settings.theme.backgroundColor)

        let mutable = NSMutableAttributedString(attributedString: NSAttributedString(content))
        let fullRange = NSRange(location: 0, length: mutable.length)
        mutable.addAttributes([
            .verticalGlyphForm: 1,
            .foregroundColor: UIColor(settings.theme.textColor),
            .font: UIFont.systemFont(ofSize: CGFloat(settings.fontSize.rawValue))
        ], range: fullRange)

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = settings.lineSpacing.value
        paragraph.alignment = .natural
        mutable.addAttribute(.paragraphStyle, value: paragraph, range: fullRange)

        uiView.attributedText = mutable
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScroll: onScroll)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        let onScroll: (Double) -> Void

        init(onScroll: @escaping (Double) -> Void) {
            self.onScroll = onScroll
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            onScroll(scrollView.contentOffset.x)
        }
    }
}
