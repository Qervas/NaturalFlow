import Foundation
import SwiftData
import SwiftUI

class ReaderSettings: ObservableObject {
    @Published var theme: ReaderTheme
    @Published var fontSize: CGFloat
    @Published var fontName: String
    @Published var lineSpacing: CGFloat
    @Published var showPageNumbers: Bool
    @Published var brightness: Double

    static let availableFonts = [
        "System": ".AppleSystemUIFont",
        "Georgia": "Georgia",
        "New York": "New York",
        "Times New Roman": "Times New Roman",
    ]

    init() {
        self.theme = ReaderTheme.defaults[0]
        self.fontSize = 16
        self.fontName = "Georgia"
        self.lineSpacing = 1.4
        self.showPageNumbers = true
        self.brightness = 1.0
    }
}
