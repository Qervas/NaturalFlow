import Foundation
import SwiftData
import SwiftUI

class ReaderSettings: ObservableObject {
    @Published var theme: ReaderTheme {
        didSet {
            updateTextAttributes()
            objectWillChange.send()
        }
    }
    @Published var fontSize: CGFloat {
        didSet {
            updateTextAttributes()
            objectWillChange.send()
        }
    }
    @Published var fontName: String {
        didSet {
            updateTextAttributes()
            objectWillChange.send()
        }
    }
    @Published var lineSpacing: CGFloat {
        didSet {
            updateTextAttributes()
            objectWillChange.send()
        }
    }
    @Published var showPageNumbers: Bool
    @Published var brightness: Double
    @Published var textAttributes: [NSAttributedString.Key: Any] = [:]

    static let availableFonts = [
        "System": ".AppleSystemUIFont",
        "Georgia": "Georgia",
        "New York": "New York",
        "Times New Roman": "Times New Roman",
    ]

    init() {
        // Get the current system appearance
        let appearance = NSApp.effectiveAppearance
        let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

        self.theme = ReaderTheme.systemTheme(for: isDark ? .dark : .light)
        self.fontSize = 16
        self.fontName = "System"
        self.lineSpacing = 1.4
        self.showPageNumbers = true
        self.brightness = 1.0
        updateTextAttributes()

        // Observe system appearance changes
        DistributedNotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppearanceChange),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }

    @objc private func handleAppearanceChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let appearance = NSApp.effectiveAppearance
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua

            if self.theme.id == "system" {
                self.theme = ReaderTheme.systemTheme(for: isDark ? .dark : .light)
            }
        }
    }

    private func updateTextAttributes() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.paragraphSpacing = 12

        let font =
            NSFont(
                name: ReaderSettings.availableFonts[fontName] ?? ".AppleSystemUIFont",
                size: fontSize
            ) ?? .systemFont(ofSize: fontSize)

        textAttributes = [
            .font: font,
            .foregroundColor: NSColor(theme.textColor),
            .paragraphStyle: paragraphStyle,
        ]
    }

    deinit {
        DistributedNotificationCenter.default.removeObserver(self)
    }
}
