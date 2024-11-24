import Foundation
import SwiftData
import SwiftUI

struct ReaderTheme: Identifiable, Codable {
    let id: String
    let name: String
    fileprivate let backgroundColorComponents: ColorComponents
    fileprivate let textColorComponents: ColorComponents
    let fontName: String
    let fontSize: CGFloat
    let lineSpacing: CGFloat
    let paragraphSpacing: CGFloat

    var backgroundColor: Color {
        Color(components: backgroundColorComponents)
    }

    var textColor: Color {
        Color(components: textColorComponents)
    }

    init(
        id: String, name: String, backgroundColor: Color, textColor: Color, fontName: String,
        fontSize: CGFloat, lineSpacing: CGFloat, paragraphSpacing: CGFloat
    ) {
        self.id = id
        self.name = name
        self.backgroundColorComponents = ColorComponents(color: backgroundColor)
        self.textColorComponents = ColorComponents(color: textColor)
        self.fontName = fontName
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
        self.paragraphSpacing = paragraphSpacing
    }

    static let defaults: [ReaderTheme] = [
        ReaderTheme(
            id: "light",
            name: "Light",
            backgroundColor: .white,
            textColor: .black,
            fontName: "Georgia",
            fontSize: 16,
            lineSpacing: 1.4,
            paragraphSpacing: 12
        ),
        ReaderTheme(
            id: "dark",
            name: "Dark",
            backgroundColor: Color(white: 0.1),
            textColor: .white,
            fontName: "Georgia",
            fontSize: 16,
            lineSpacing: 1.4,
            paragraphSpacing: 12
        ),
        ReaderTheme(
            id: "sepia",
            name: "Sepia",
            backgroundColor: Color(red: 0.98, green: 0.95, blue: 0.9),
            textColor: Color(red: 0.35, green: 0.25, blue: 0.15),
            fontName: "Georgia",
            fontSize: 16,
            lineSpacing: 1.4,
            paragraphSpacing: 12
        ),
    ]
}

private struct ColorComponents: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    init(color: Color) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var opacity: CGFloat = 0

        #if os(macOS)
            NSColor(color).getRed(&red, green: &green, blue: &blue, alpha: &opacity)
        #else
            UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &opacity)
        #endif

        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.opacity = Double(opacity)
    }
}

extension Color {
    fileprivate init(components: ColorComponents) {
        self.init(
            red: components.red, green: components.green, blue: components.blue,
            opacity: components.opacity)
    }
}

extension ReaderTheme {
    static let elegant = ReaderTheme(
        id: "elegant",
        name: "Elegant",
        backgroundColor: Color(red: 0.98, green: 0.97, blue: 0.95),
        textColor: Color(red: 0.2, green: 0.2, blue: 0.2),
        fontName: "New York",
        fontSize: 16,
        lineSpacing: 1.4,
        paragraphSpacing: 12
    )
}
