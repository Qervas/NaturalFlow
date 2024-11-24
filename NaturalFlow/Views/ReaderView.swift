import SwiftData
import SwiftUI

struct ReaderView: View {
    let book: Book
    @StateObject private var settings = ReaderSettings()
    @StateObject private var progressManager: ReadingProgressManager
    @StateObject private var epubManager = EPUBManager()
    @State private var showSettings = false
    @State private var showChapters = false
    @State private var selectedWord: Word?
    @State private var learningWords: Set<String> = []

    init(book: Book) {
        self.book = book
        self._progressManager = StateObject(wrappedValue: ReadingProgressManager(bookId: book.id))
    }

    var body: some View {
        HSplitView {
            ZStack {
                readerContent
                    .padding(.horizontal, 40)  // Add comfortable reading margins

                // Reading progress overlay at the bottom
                VStack {
                    Spacer()
                    HStack {
                        Button(action: navigateToPreviousChapter) {
                            Label("Previous", systemImage: "chevron.left")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.plain)
                        .disabled(epubManager.currentChapter == epubManager.chapters.first)

                        Spacer()

                        // Chapter progress
                        Text("\(epubManager.currentChapter?.title ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button(action: navigateToNextChapter) {
                            Label("Next", systemImage: "chevron.right")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.plain)
                        .disabled(epubManager.currentChapter == epubManager.chapters.last)
                    }
                    .padding(8)
                    .background(.thinMaterial)
                    .cornerRadius(8)
                }
                .padding()
                .opacity(0.8)
            }

            if let word = selectedWord {
                WordCard(word: word, isInLearningList: learningWords.contains(word.term)) {
                    isAdded in
                    if isAdded {
                        learningWords.insert(word.term)
                    } else {
                        learningWords.remove(word.term)
                    }
                }
                .frame(width: 300)
                .background(.thinMaterial)
            }
        }
        .navigationTitle(book.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showChapters.toggle()
                } label: {
                    Label("Chapters", systemImage: "list.bullet")
                }
                .help("Chapters")

                Button {
                    showSettings.toggle()
                } label: {
                    Label("Appearance", systemImage: "textformat.size")
                }
                .help("Appearance")
            }
        }
        .sheet(isPresented: $showSettings) {
            ReaderSettingsView(settings: settings)
        }
        .sheet(isPresented: $showChapters) {
            ChaptersView(
                chapters: epubManager.chapters, currentChapter: $epubManager.currentChapter)
        }
        .task {
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

    var body: some View {
        TextView(
            text: content,
            font: NSFont(name: settings.fontName, size: settings.fontSize)
                ?? .systemFont(ofSize: settings.fontSize),
            textColor: NSColor(cgColor: settings.theme.textColor.cgColor!)!,
            lineSpacing: settings.lineSpacing,
            onWordSelected: onWordSelected
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(settings.theme.backgroundColor)
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

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct TextView: NSViewRepresentable {
    typealias NSViewType = NSScrollView
    let text: String
    let font: NSFont
    let textColor: NSColor
    let lineSpacing: CGFloat
    let onWordSelected: (String) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false

        let textView = NSTextView(frame: .zero)
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator

        // Set up text container
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = true

        // Configure text view
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        // Set up scroll view
        scrollView.documentView = textView
        scrollView.drawsBackground = false

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)
        textView.textStorage?.setAttributedString(attributedString)

        // Update layout
        textView.layoutManager?.ensureLayout(for: textView.textContainer!)

        // Set frame to fit content
        if let layoutManager = textView.layoutManager,
            let container = textView.textContainer
        {
            let size = layoutManager.usedRect(for: container).size
            textView.frame.size = size
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onWordSelected: onWordSelected)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        let onWordSelected: (String) -> Void

        init(onWordSelected: @escaping (String) -> Void) {
            self.onWordSelected = onWordSelected
        }

        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            if let selectedText = textView.selectedText, !selectedText.isEmpty {
                onWordSelected(selectedText)
                return true
            }
            return false
        }
    }
}

extension NSColor {
    convenience init(_ color: Color) {
        self.init(cgColor: color.cgColor ?? .black)!
    }
}

extension NSTextView {
    var selectedText: String? {
        guard let range = selectedRanges.first as? NSRange,
            let text = textStorage?.string
        else { return nil }
        return (text as NSString).substring(with: range)
    }
}

struct ThemePickerView: View {
    @Binding var selectedTheme: ReaderTheme

    var body: some View {
        HStack(spacing: 12) {
            ForEach(ReaderTheme.defaults) { theme in
                ThemeButton(theme: theme, isSelected: theme.id == selectedTheme.id) {
                    selectedTheme = theme
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct ThemeButton: View {
    let theme: ReaderTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.backgroundColor)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isSelected ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

struct ThemeRow: View {
    let theme: ReaderTheme
    let isSelected: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(theme.backgroundColor)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(theme.textColor, lineWidth: 1))

            Text(theme.name)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
    }
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
