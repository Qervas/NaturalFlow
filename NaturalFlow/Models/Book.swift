import Foundation
import SwiftData

@Model
final class Book {
    @Attribute(.unique) var id: String
    var title: String
    var author: String
    var languageCode: String  // Store as String instead of enum
    var filePath: String
    var lastReadPosition: Double
    var lastReadDate: Date
    var timestamp: Date

    var language: Language {
        get { Language(rawValue: languageCode) ?? .swedish }
        set { languageCode = newValue.rawValue }
    }

    init(title: String, author: String, language: Language, filePath: String) {
        self.id = UUID().uuidString
        self.title = title
        self.author = author
        self.languageCode = language.rawValue
        self.filePath = filePath
        self.lastReadPosition = 0
        self.lastReadDate = Date()
        self.timestamp = Date()
    }
}
