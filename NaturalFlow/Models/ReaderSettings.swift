import Foundation
import SwiftData
import SwiftUI

class ReaderSettings: ObservableObject {
    @Published var theme: ReaderTheme {
        didSet {
            updateTextAttributes()
        }
    }
    @Published var fontSize: CGFloat {
        didSet {
            updateTextAttributes()
        }
    }
    @Published var fontName: String {
        didSet {
            updateTextAttributes()
        }
    }
    @Published var lineSpacing: CGFloat {
        didSet {
            updateTextAttributes()
        }
    }
    @Published var showPageNumbers: Bool
    @Published var brightness: Double

    @Published var textAttributes: [NSAttributedString.Key: Any] = [:]

    static let availableFonts = [
        "System": ".AppleSystemUIFont",
        "Georgia": "Georgia",
        "New York": ".SFNS-Regular",
        "Times New Roman": "Times New Roman",
    ]

    init() {
        self.theme = ReaderTheme.systemTheme(for: .light)
        self.fontSize = 16
        self.fontName = "System"
        self.lineSpacing = 1.4
        self.showPageNumbers = true
        self.brightness = 1.0
        updateTextAttributes()
    }

    private func updateTextAttributes() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = 12

        let font =
            NSFont(
                name: ReaderSettings.availableFonts[fontName] ?? ".AppleSystemUIFont",
                size: fontSize)
            ?? .systemFont(ofSize: fontSize)

        textAttributes = [
            .font: font,
            .foregroundColor: NSColor(theme.textColor),
            .paragraphStyle: paragraphStyle,
        ]
    }
}
