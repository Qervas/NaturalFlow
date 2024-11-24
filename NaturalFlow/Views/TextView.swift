import AppKit
import SwiftUI

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

        let contentSize = NSSize(width: scrollView.bounds.width, height: .greatestFiniteMagnitude)
        let textView = NSTextView(frame: NSRect(origin: .zero, size: contentSize))
        scrollView.documentView = textView

        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = contentSize

        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        // Improve text layout
        textView.layoutManager?.allowsNonContiguousLayout = true
        textView.layoutManager?.usesDefaultHyphenation = true  // Updated from hyphenationFactor
        textView.layoutManager?.usesFontLeading = true

        // Add gesture recognizer for click
        let clickGesture = NSClickGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        textView.addGestureRecognizer(clickGesture)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = 12
        paragraphStyle.alignment = .natural
        paragraphStyle.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(
                name: ReaderSettings.availableFonts[settings.fontName] ?? ".AppleSystemUIFont",
                size: settings.fontSize) ?? .systemFont(ofSize: settings.fontSize),
            .foregroundColor: NSColor(settings.theme.textColor),
            .paragraphStyle: paragraphStyle,
        ]

        // Update existing text with new attributes
        if let textStorage = textView.textStorage {
            textStorage.beginEditing()
            textStorage.setAttributes(
                attributes, range: NSRange(location: 0, length: textStorage.length))
            if textStorage.string != text {
                textStorage.setAttributedString(
                    NSAttributedString(string: text, attributes: attributes))
            }
            textStorage.endEditing()
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
            super.init()
        }

        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let textView = gesture.view as? NSTextView else { return }

            // Get click location
            let point = gesture.location(in: textView)

            // Convert point to text position
            let index = textView.characterIndex(for: point)

            // Find word boundaries
            if let word = findWord(in: textView, at: index) {
                onWordSelected(word)
            }

            // Clear selection
            textView.selectedRange = NSRange()
        }

        private func findWord(in textView: NSTextView, at index: Int) -> String? {
            guard let text = textView.string as NSString?,
                index < text.length
            else { return nil }

            let range = findWordRange(in: text, at: index)
            guard range.location != NSNotFound else { return nil }

            return text.substring(with: range)
        }

        private func findWordRange(in text: NSString, at index: Int) -> NSRange {
            var start = index
            var end = index

            // Find start of word
            while start > 0 {
                let char = text.substring(with: NSRange(location: start - 1, length: 1))
                if char.rangeOfCharacter(from: .whitespaces) != nil {
                    break
                }
                start -= 1
            }

            // Find end of word
            while end < text.length {
                let char = text.substring(with: NSRange(location: end, length: 1))
                if char.rangeOfCharacter(from: .whitespaces) != nil {
                    break
                }
                end += 1
            }

            return NSRange(location: start, length: end - start)
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
