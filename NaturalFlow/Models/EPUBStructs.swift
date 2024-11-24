import Foundation

struct EPUBChapter: Identifiable, Equatable {
    let id: String
    let title: String
    let content: String
    let index: Int
    var highlights: [Highlight] = []
    var bookmarks: [Bookmark] = []

    // Add explicit Equatable conformance for arrays
    static func == (lhs: EPUBChapter, rhs: EPUBChapter) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.content == rhs.content
            && lhs.index == rhs.index && lhs.highlights == rhs.highlights
            && lhs.bookmarks == rhs.bookmarks
    }
}

struct EPUBMetadata: Codable {
    let title: String
    let creator: String?
    let language: String
    let identifier: String
    let publisher: String?
    let date: String?
    let rights: String?
}

struct Highlight: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let color: HighlightColor
    let note: String?
    let dateCreated: Date
    
    enum HighlightColor: String, Codable, Equatable {
        case yellow
        case green
        case blue
        case pink
        case purple
    }
}

struct Bookmark: Identifiable, Codable, Equatable {
    let id: UUID
    let position: Double
    let text: String
    let dateCreated: Date
    let note: String?
}

struct ReadingProgress: Codable {
    var chapterIndex: Int
    var position: Double
    var lastReadDate: Date
}
