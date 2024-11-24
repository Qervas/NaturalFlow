import Foundation
import SwiftData

@Model
final class Word {
    var term: String
    var translation: String
    var pronunciation: String
    var category: Category
    var isInLearningList: Bool
    var context: String?
    var timestamp: Date

    init(term: String, translation: String, pronunciation: String, category: Category) {
        self.term = term
        self.translation = translation
        self.pronunciation = pronunciation
        self.category = category
        self.isInLearningList = false
        self.timestamp = Date()
    }
}

enum Category: String, Codable {
    case basics
    case intermediate
    case advanced
}
