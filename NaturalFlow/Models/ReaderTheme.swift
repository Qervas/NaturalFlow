import SwiftUI
import AppKit

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
            backgroundColor: Color(nsColor: .textBackgroundColor),
            textColor: Color(nsColor: .textColor),
            fontName: "New York",
            fontSize: 16,
            lineSpacing: 1.4,
            paragraphSpacing: 12
        ),
        ReaderTheme(
            id: "dark",
            name: "Dark",
            backgroundColor: Color(nsColor: NSColor.init(white: 0.12, alpha: 1)),
            textColor: Color(nsColor: NSColor.init(white: 0.9, alpha: 1)),
            fontName: "New York",
            fontSize: 16,
            lineSpacing: 1.4,
            paragraphSpacing: 12
        ),
        ReaderTheme(
            id: "sepia",
            name: "Sepia",
            backgroundColor: Color(red: 0.98, green: 0.95, blue: 0.9),
            textColor: Color(red: 0.35, green: 0.25, blue: 0.15),
            fontName: "New York",
            fontSize: 16,
            lineSpacing: 1.4,
            paragraphSpacing: 12
        )
    ]
}

private struct ColorComponents: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    init(color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? .black
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        self.red = Double(red)
        self.green = Double(green)
        self.blue = Double(blue)
        self.opacity = Double(alpha)
    }
}

extension Color {
    fileprivate init(components: ColorComponents) {
        self.init(
            red: components.red,
            green: components.green,
            blue: components.blue,
            opacity: components.opacity
        )
    }
    
    init(nsColor: NSColor) {
        let color = nsColor.usingColorSpace(.deviceRGB) ?? .black
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        self.init(red: Double(red), green: Double(green), blue: Double(blue), opacity: Double(alpha))
    }
}

extension ReaderTheme {
    static func systemTheme(for colorScheme: ColorScheme) -> ReaderTheme {
        let baseTheme = colorScheme == .dark ? defaults[1] : defaults[0]
        return ReaderTheme(
            id: "system",
            name: "System",
            backgroundColor: Color(nsColor: colorScheme == .dark ? .black : .white),
            textColor: Color(nsColor: colorScheme == .dark ? .white : .black),
            fontName: baseTheme.fontName,
            fontSize: baseTheme.fontSize,
            lineSpacing: baseTheme.lineSpacing,
            paragraphSpacing: baseTheme.paragraphSpacing
        )
    }
}
