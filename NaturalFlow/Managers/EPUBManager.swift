import Foundation
import SwiftUI
import ZIPFoundation

class EPUBManager: ObservableObject {
    @Published var chapters: [EPUBChapter] = []
    @Published var currentChapter: EPUBChapter?
    @Published var metadata: EPUBMetadata?
    @Published var readingProgress: ReadingProgress
    @Published var isLoading = false

    private var epubURL: URL?
    private var extractedPath: URL?

    init() {
        self.readingProgress = ReadingProgress(chapterIndex: 0, position: 0, lastReadDate: Date())
    }

    func reset() {
        chapters = []
        currentChapter = nil
        metadata = nil
        readingProgress = ReadingProgress(chapterIndex: 0, position: 0, lastReadDate: Date())
        cleanup()
    }

    @MainActor
    func loadEPUB(from url: URL) async throws {
        isLoading = true
        defer { isLoading = false }

        self.epubURL = url

        // Create temporary directory for extraction
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        self.extractedPath = tempDir

        // Extract EPUB
        try FileManager.default.unzipItem(at: url, to: tempDir)

        // Parse container.xml to find OPF file
        let containerURL = tempDir.appendingPathComponent("META-INF/container.xml")
        let opfPath = try parseContainerXML(at: containerURL)

        // Parse OPF file
        let opfURL = tempDir.appendingPathComponent(opfPath)
        try await parseOPFFile(at: opfURL)
    }

    private func parseContainerXML(at url: URL) throws -> String {
        let containerData = try Data(contentsOf: url)
        let xml = try XMLDocument(data: containerData, options: [])

        guard let rootElement = xml.rootElement(),
            let rootfiles = rootElement.elements(forName: "rootfiles").first,
            let rootfile = rootfiles.elements(forName: "rootfile").first,
            let opfPath = rootfile.attribute(forName: "full-path")?.stringValue
        else {
            throw EPUBError.invalidContainer
        }

        return opfPath
    }

    @MainActor
    private func updateState(with newChapters: [EPUBChapter]) {
        self.chapters = newChapters
        self.currentChapter = newChapters.first
    }

    private func parseOPFFile(at url: URL) async throws {
        let opfData = try Data(contentsOf: url)
        let xml = try XMLDocument(data: opfData, options: [])
        guard let rootElement = xml.rootElement() else {
            throw EPUBError.invalidOPF
        }

        // Parse metadata
        if let metadataElement = rootElement.elements(forName: "metadata").first {
            metadata = try parseMetadata(from: metadataElement)
        }

        // Parse manifest and spine
        let manifest = try parseManifest(from: rootElement)
        let spine = try parseSpine(from: rootElement)

        // Load chapters
        let newChapters = try await loadChapters(
            spine: spine, manifest: manifest, baseURL: url.deletingLastPathComponent())
        await updateState(with: newChapters)
    }

    private func loadChapters(spine: [String], manifest: [String: ManifestItem], baseURL: URL)
        async throws -> [EPUBChapter]
    {
        var chapters: [EPUBChapter] = []

        for (index, itemref) in spine.enumerated() {
            guard let item = manifest[itemref] else { continue }

            // Get the absolute URL for the chapter file
            let chapterURL = baseURL.appendingPathComponent(item.href)

            do {
                // Read the chapter content
                let chapterData = try Data(contentsOf: chapterURL)

                // Try to determine the text encoding
                let encoding: String.Encoding
                if let contentString = String(data: chapterData, encoding: .utf8) {
                    encoding = .utf8
                } else if let contentString = String(data: chapterData, encoding: .utf16) {
                    encoding = .utf16
                } else {
                    encoding = .isoLatin1  // Fallback encoding
                }

                // Convert data to string using the determined encoding
                if let chapterContent = String(data: chapterData, encoding: encoding) {
                    let cleanContent = cleanupHTML(chapterContent)

                    // Only create chapter if content is not empty
                    if !cleanContent.isEmpty {
                        let chapter = EPUBChapter(
                            id: item.id,
                            title: item.title ?? "Chapter \(index + 1)",
                            content: cleanContent,
                            index: index
                        )
                        chapters.append(chapter)
                    }
                }
            } catch {
                print("Error loading chapter at \(chapterURL): \(error)")
                continue  // Skip problematic chapters but continue loading others
            }
        }

        return chapters
    }

    private func parseMetadata(from element: XMLElement) throws -> EPUBMetadata {
        func getValue(forName name: String) -> String? {
            element.elements(forName: name).first?.stringValue
        }

        return EPUBMetadata(
            title: getValue(forName: "title") ?? "Untitled",
            creator: getValue(forName: "creator"),
            language: getValue(forName: "language") ?? "en",
            identifier: getValue(forName: "identifier") ?? UUID().uuidString,
            publisher: getValue(forName: "publisher"),
            date: getValue(forName: "date"),
            rights: getValue(forName: "rights")
        )
    }

    private func parseManifest(from root: XMLElement) throws -> [String: ManifestItem] {
        guard let manifestElement = root.elements(forName: "manifest").first else {
            throw EPUBError.invalidManifest
        }

        var manifest: [String: ManifestItem] = [:]
        let items = manifestElement.elements(forName: "item")

        for item in items {
            guard let id = item.attribute(forName: "id")?.stringValue,
                let href = item.attribute(forName: "href")?.stringValue,
                let mediaType = item.attribute(forName: "media-type")?.stringValue
            else { continue }

            // Only include HTML content
            if mediaType.contains("html") || mediaType.contains("xhtml") {
                manifest[id] = ManifestItem(id: id, href: href, mediaType: mediaType)
            }
        }

        return manifest
    }

    private func parseSpine(from root: XMLElement) throws -> [String] {
        guard let spineElement = root.elements(forName: "spine").first else {
            throw EPUBError.invalidSpine
        }

        // Get reading order from spine
        return spineElement.elements(forName: "itemref")
            .compactMap { $0.attribute(forName: "idref")?.stringValue }
    }

    private func cleanupHTML(_ html: String) -> String {
        // More sophisticated HTML cleanup
        var content = html

        // Remove scripts and style tags with their content
        content = content.replacingOccurrences(
            of: "<script[^>]*>([\\s\\S]*?)</script>",
            with: "",
            options: .regularExpression
        )
        content = content.replacingOccurrences(
            of: "<style[^>]*>([\\s\\S]*?)</style>",
            with: "",
            options: .regularExpression
        )

        // Remove HTML comments
        content = content.replacingOccurrences(
            of: "<!--[\\s\\S]*?-->",
            with: "",
            options: .regularExpression
        )

        // Replace common block elements with newlines
        let blockElements = ["p", "div", "h[1-6]", "br", "li", "tr"]
        for element in blockElements {
            content = content.replacingOccurrences(
                of: "</?\(element)[^>]*>",
                with: "\n",
                options: .regularExpression
            )
        }

        // Remove remaining HTML tags
        content = content.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )

        // Fix whitespace
        content = content.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        content = content.replacingOccurrences(
            of: "\n\\s+", with: "\n", options: .regularExpression)
        content = content.replacingOccurrences(
            of: "\\s+\n", with: "\n", options: .regularExpression)
        content = content.replacingOccurrences(of: "\n+", with: "\n\n", options: .regularExpression)

        // Decode HTML entities
        content = content.replacingOccurrences(of: "&nbsp;", with: " ")
        content = content.replacingOccurrences(of: "&quot;", with: "\"")
        content = content.replacingOccurrences(of: "&apos;", with: "'")
        content = content.replacingOccurrences(of: "&lt;", with: "<")
        content = content.replacingOccurrences(of: "&gt;", with: ">")
        content = content.replacingOccurrences(of: "&amp;", with: "&")

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func saveProgress() {
        guard let chapter = currentChapter else { return }
        readingProgress.chapterIndex = chapter.index
        readingProgress.lastReadDate = Date()
    }

    func cleanup() {
        if let extractedPath = extractedPath {
            try? FileManager.default.removeItem(at: extractedPath)
            self.extractedPath = nil
        }
        self.epubURL = nil
    }

    deinit {
        cleanup()
    }
}

struct ManifestItem {
    let id: String
    let href: String
    let mediaType: String
    var title: String?
}

enum EPUBError: Error {
    case invalidContainer
    case invalidOPF
    case invalidMetadata
    case invalidManifest
    case invalidSpine
}
