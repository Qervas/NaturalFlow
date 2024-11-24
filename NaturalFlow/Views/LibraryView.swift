import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var books: [Book]
    @State private var selectedLanguage: Language?
    @State private var isImporting = false

    var body: some View {
        NavigationSplitView {
            List(Language.allCases, id: \.self, selection: $selectedLanguage) {
                language in
                NavigationLink(value: language) {
                    Text(language.rawValue.capitalized)
                }
            }
            .navigationTitle("Languages")
        } content: {
            if let selectedLanguage = selectedLanguage {
                BookListView(language: selectedLanguage)
                    .navigationTitle("\(selectedLanguage.rawValue.capitalized) Books")
            } else {
                ContentUnavailableView(
                    "Select a language",
                    systemImage: "book.closed")
            }
        } detail: {
            ContentUnavailableView(
                "Select a book",
                systemImage: "book")
        }
    }
}

struct BookListView: View {
    @Environment(\.modelContext) private var modelContext
    let language: Language
    @Query private var books: [Book]
    @State private var showingFileImporter = false
    @State private var errorMessage: String?
    @State private var showingError = false

    init(language: Language) {
        self.language = language
        _books = Query(
            filter: #Predicate<Book> { book in
                book.languageCode == language.rawValue
            },
            sort: [SortDescriptor(\Book.timestamp, order: .reverse)]
        )
    }

    var body: some View {
        Group {
            if books.isEmpty {
                ContentUnavailableView {
                    Label("No Books", systemImage: "book.closed")
                } description: {
                    Text("Drop EPUB files here or use the Add button")
                }
            } else {
                List {
                    ForEach(books) { book in
                        NavigationLink {
                            ReaderView(book: book)
                        } label: {
                            BookRowView(book: book)
                        }
                    }
                    .onDelete(perform: deleteBooks)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button(action: { showingFileImporter = true }) {
                    Label("Add Book", systemImage: "plus")
                }
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [UTType(filenameExtension: "epub")!],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
            return true
        }
        .onAppear {
            BookManager.shared.setModelContext(modelContext)
        }
        .alert(
            "Error", isPresented: $showingError,
            actions: {
                Button("OK") {}
            },
            message: {
                Text(errorMessage ?? "An unknown error occurred")
            })
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            for url in urls {
                do {
                    try BookManager.shared.handleIncomingURL(url, language: language)
                } catch {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        } catch {
            errorMessage = "Could not access the selected file."
            showingError = true
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) {
                item, error in
                guard let data = item as? Data,
                    let url = URL(dataRepresentation: data, relativeTo: nil)
                else { return }

                DispatchQueue.main.async {
                    do {
                        try BookManager.shared.handleIncomingURL(url, language: language)
                    } catch {
                        print("Error handling dropped file: \(error)")
                    }
                }
            }
        }
    }

    private func deleteBooks(at offsets: IndexSet) {
        for index in offsets {
            let book = books[index]
            // Delete the file
            try? FileManager.default.removeItem(atPath: book.filePath)
            modelContext.delete(book)
        }
    }
}

struct BookRowView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading) {
            Text(book.title)
                .font(.headline)
            Text(book.author)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
