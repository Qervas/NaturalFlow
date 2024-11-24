import SwiftUI
import AppKit

struct TextView: NSViewRepresentable {
    typealias NSViewType = NSScrollView
    let text: String
    let font: NSFont
    let textColor: NSColor
    let lineSpacing: CGFloat
    let onWordSelected: (String) -> Void
    @ObservedObject var settings: ReaderSettings

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.drawsBackground = false

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator

        if let textContainer = textView.textContainer {
            textContainer.lineFragmentPadding = 0
            textContainer.widthTracksTextView = true
            textContainer.containerSize = NSSize(
                width: scrollView.bounds.width,
                height: CGFloat.greatestFiniteMagnitude
            )
        }

        textView.layoutManager?.usesFontLeading = true
        textView.layoutManager?.allowsNonContiguousLayout = true

        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.minSize = NSSize(width: 0, height: 0)

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update text container width to match scroll view
        textView.textContainer?.containerSize = NSSize(
            width: max(scrollView.contentSize.width - 20, 0),
            height: CGFloat.greatestFiniteMagnitude
        )

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = 12
        paragraphStyle.alignment = .natural
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]

        let processedText = text.replacingOccurrences(of: "\n", with: "\n\n")
        let attributedString = NSAttributedString(string: processedText, attributes: attributes)
        textView.textStorage?.setAttributedString(attributedString)

        if context.coordinator.lastContent != text {
            scrollView.documentView?.scroll(.zero)
            context.coordinator.lastContent = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onWordSelected: onWordSelected)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        let onWordSelected: (String) -> Void
        var lastContent: String = ""

        init(onWordSelected: @escaping (String) -> Void) {
            self.onWordSelected = onWordSelected
        }

        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            if let selectedText = textView.selectedText, !selectedText.isEmpty {
                onWordSelected(selectedText)
                return true
            }
            return false
        }
    }
}

extension NSColor {
    convenience init(_ color: Color) {
        self.init(cgColor: color.cgColor ?? .black)!
    }
}

extension NSTextView {
    var selectedText: String? {
        guard let range = selectedRanges.first as? NSRange,
            let text = textStorage?.string
        else { return nil }
        return (text as NSString).substring(with: range)
    }
}
