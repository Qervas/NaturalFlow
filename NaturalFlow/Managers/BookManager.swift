import Foundation
import SwiftData
import UniformTypeIdentifiers

class BookManager: ObservableObject {
    private var modelContext: ModelContext?
    static let shared = BookManager()
    private let fileManager = FileManager.default
    private let appSupportURL: URL

    private init() {
        // Get Application Support directory
        guard
            let appSupport = fileManager.urls(
                for: .applicationSupportDirectory, in: .userDomainMask
            ).first
        else {
            fatalError("Could not access Application Support directory")
        }

        // Create a books directory
        let booksDirectory = appSupport.appendingPathComponent("Books", isDirectory: true)
        self.appSupportURL = booksDirectory

        try? fileManager.createDirectory(at: booksDirectory, withIntermediateDirectories: true)
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func handleIncomingURL(_ url: URL, language: Language) throws {
        guard let modelContext = self.modelContext else {
            throw BookError.noModelContext
        }

        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw BookError.fileAccessError
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // Create unique filename
        let uniqueFilename = UUID().uuidString + "_" + url.lastPathComponent
        let destinationURL = appSupportURL.appendingPathComponent(uniqueFilename)

        do {
            // Copy the file
            try fileManager.copyItem(at: url, to: destinationURL)

            // Create book record
            let book = Book(
                title: url.deletingPathExtension().lastPathComponent,
                author: "Unknown",
                language: language,
                filePath: destinationURL.path
            )

            modelContext.insert(book)
            try modelContext.save()

        } catch {
            print("Error handling file: \(error)")
            throw BookError.fileAccessError
        }
    }
}

enum BookError: Error {
    case invalidFileFormat
    case fileAccessError
    case noModelContext

    var localizedDescription: String {
        switch self {
        case .invalidFileFormat:
            return "The selected file is not a valid EPUB file."
        case .fileAccessError:
            return "Could not access the file. Please try again."
        case .noModelContext:
            return "Internal error: Could not access the database."
        }
    }
}
