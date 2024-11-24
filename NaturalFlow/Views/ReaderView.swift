import SwiftData
import SwiftUI

struct ReaderView: View {
    let book: Book
    @StateObject private var settings = ReaderSettings()
    @StateObject private var progressManager: ReadingProgressManager
    @StateObject private var epubManager = EPUBManager()
    @State private var showSettings = false
    @State private var showSidebar = false
    @State private var selectedWord: Word?
    @State private var learningWords: Set<String> = []
    @State private var currentBookId: String?

    init(book: Book) {
        self.book = book
        self._progressManager = StateObject(wrappedValue: ReadingProgressManager(bookId: book.id))
    }

    var body: some View {
        HStack(spacing: 0) {
            // Main content
            ZStack {
                readerContent
                    .padding(.horizontal, 40)

                // Bottom navigation overlay
                VStack {
                    Spacer()
                    if !showSidebar {
                        NavigationBar(
                            chapter: epubManager.currentChapter,
                            onPrevious: navigateToPreviousChapter,
                            onNext: navigateToNextChapter,
                            isFirstChapter: epubManager.currentChapter
                                == epubManager.chapters.first,
                            isLastChapter: epubManager.currentChapter == epubManager.chapters.last
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Sidebar
            if showSidebar {
                ReaderSidebar(
                    chapters: epubManager.chapters,
                    currentChapter: $epubManager.currentChapter,
                    settings: settings
                )
                .frame(width: 300)
                .transition(.move(edge: .trailing))
            }
        }
        .navigationTitle(book.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    withAnimation(.spring()) {
                        showSidebar.toggle()
                    }
                } label: {
                    Label("Contents", systemImage: "sidebar.right")
                }
                .help("Toggle Sidebar")
            }
        }
        .task(id: book.id) {  // Add id parameter to task
            // Reset state if book changed
            if currentBookId != book.id {
                epubManager.reset()
                currentBookId = book.id
            }

            do {
                try await epubManager.loadEPUB(from: URL(fileURLWithPath: book.filePath))
            } catch {
                print("Error loading EPUB: \(error)")
            }
        }
    }

    private func handleWordSelection(_ word: String) {
        // Here you would typically:
        // 1. Look up the word in your dictionary
        // 2. Create a Word object with the translation
        // 3. Set it as the selectedWord
        let newWord = Word(
            term: word,
            translation: "Translation goes here",  // Replace with actual translation
            pronunciation: "Pronunciation goes here",  // Replace with actual pronunciation
            category: .basics
        )
        selectedWord = newWord
    }
}

struct ReaderContentView: View {
    let content: String
    @ObservedObject var settings: ReaderSettings
    let onWordSelected: (String) -> Void

    // State for tracking scroll position and UI
    @State private var scrollPosition: CGFloat = 0
    @State private var showControls: Bool = false
    @State private var lastScrollTime: Date = Date()
    @State private var contentWidth: CGFloat = 0
    @State private var lastContent: String = ""

    private let controlsFadeDelay: TimeInterval = 2

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                // Main content
                TextView(
                    text: content,
                    font: NSFont(name: settings.fontName, size: settings.fontSize)
                        ?? .systemFont(ofSize: settings.fontSize),
                    textColor: NSColor(cgColor: settings.theme.textColor.cgColor!)!,
                    lineSpacing: settings.lineSpacing,
                    onWordSelected: onWordSelected,
                    settings: settings  // Pass settings to TextView
                )
                .frame(
                    maxWidth: min(geometry.size.width, min(geometry.size.width * 0.9, 800)),
                    maxHeight: .infinity,
                    alignment: .center
                )
                .padding(.horizontal, calculateHorizontalPadding(for: geometry.size.width))
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: proxy.frame(in: .named("scroll")).minY
                        )
                    }
                )

                // Reading progress indicator
                VStack {
                    Spacer()
                    if showControls {
                        ReadingProgressBar(progress: calculateProgress())
                            .frame(height: 2)
                            .padding(.horizontal)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollPosition = value
                showControls = true
                lastScrollTime = Date()

                // Hide controls after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + controlsFadeDelay) {
                    if Date().timeIntervalSince(lastScrollTime) >= controlsFadeDelay {
                        withAnimation {
                            showControls = false
                        }
                    }
                }
            }
        }
        .background(settings.theme.backgroundColor)
        .animation(.easeOut(duration: 0.2), value: settings.fontSize)
        .animation(.easeOut(duration: 0.2), value: settings.lineSpacing)
        .onHover { isHovered in
            withAnimation {
                showControls = isHovered
            }
        }
        .onChange(of: content) { _ in
            // Reset state when content changes
            scrollPosition = 0
            contentWidth = 0
        }
    }

    // Calculate horizontal padding based on window width
    private func calculateHorizontalPadding(for width: CGFloat) -> CGFloat {
        let baseWidth: CGFloat = 800  // Ideal reading width
        let minimumPadding: CGFloat = 20

        if width <= baseWidth + (minimumPadding * 2) {
            return minimumPadding
        } else {
            return (width - baseWidth) / 2
        }
    }

    // Calculate reading progress
    private func calculateProgress() -> Double {
        let visibleHeight = -scrollPosition
        let totalHeight = contentWidth
        guard totalHeight > 0 else { return 0 }
        return min(max(visibleHeight / totalHeight, 0), 1)
    }
}

struct ChapterProgressOverlay: View {
    let progress: Double

    var body: some View {
        VStack(spacing: 4) {
            Text("Chapter Progress")
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))

                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * CGFloat(progress))
                }
            }
            .frame(height: 2)

            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(8)
        .padding()
    }
}
// Reading progress bar component
struct ReadingProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))

                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * progress)
                    .animation(.linear(duration: 0.1), value: progress)
            }
        }
        .cornerRadius(1)
    }
}

// Preference key for scroll position
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Helper view for measuring content size
struct ContentSizeReader: View {
    let content: String
    @Binding var contentWidth: CGFloat

    var body: some View {
        Text(content)
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ContentSizePreferenceKey.self,
                        value: geometry.size.width
                    )
                }
            )
            .onPreferenceChange(ContentSizePreferenceKey.self) { width in
                contentWidth = width
            }
    }
}

struct ContentSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Preview provider
#Preview {
    ReaderContentView(
        content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit...",
        settings: ReaderSettings(),
        onWordSelected: { _ in }
    )
    .frame(width: 800, height: 600)
}

extension ReaderView {
    var readerContent: some View {
        ReaderContentView(
            content: epubManager.currentChapter?.content ?? "",
            settings: settings,
            onWordSelected: handleWordSelection
        )
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width > threshold {
                        // Swipe right - previous chapter
                        navigateToPreviousChapter()
                    } else if value.translation.width < -threshold {
                        // Swipe left - next chapter
                        navigateToNextChapter()
                    }
                }
        )
    }

    private func navigateToNextChapter() {
        withAnimation(.easeInOut(duration: 0.3)) {
            guard let current = epubManager.currentChapter,
                let currentIndex = epubManager.chapters.firstIndex(where: { $0.id == current.id }),
                currentIndex < epubManager.chapters.count - 1
            else { return }

            epubManager.currentChapter = epubManager.chapters[currentIndex + 1]
        }
    }

    private func navigateToPreviousChapter() {
        guard let current = epubManager.currentChapter,
            let currentIndex = epubManager.chapters.firstIndex(where: { $0.id == current.id }),
            currentIndex > 0
        else { return }

        withAnimation {
            epubManager.currentChapter = epubManager.chapters[currentIndex - 1]
        }
    }
}

struct NavigationBar: View {
    let chapter: EPUBChapter?
    let onPrevious: () -> Void
    let onNext: () -> Void
    let isFirstChapter: Bool
    let isLastChapter: Bool

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .disabled(isFirstChapter)

            Spacer()

            if let chapter = chapter {
                Text(chapter.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .disabled(isLastChapter)
        }
        .padding(8)
        .background(.thinMaterial)
        .cornerRadius(8)
        .padding()
    }
}
