import SwiftUI

import SwiftUI

struct ChaptersView: View {
    let chapters: [EPUBChapter]
    @Binding var currentChapter: EPUBChapter?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ChaptersContent(
            chapters: chapters,
            currentChapter: $currentChapter,
            onDismiss: dismiss
        )
    }
}

private struct ChaptersContent: View {
    let chapters: [EPUBChapter]
    @Binding var currentChapter: EPUBChapter?
    let onDismiss: DismissAction

    var body: some View {
        NavigationView {
            ChaptersList(
                chapters: chapters,
                currentChapter: $currentChapter,
                onDismiss: onDismiss
            )
            .navigationTitle("Chapters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDismiss() }
                }
            }
        }
    }
}

private struct ChaptersList: View {
    let chapters: [EPUBChapter]
    @Binding var currentChapter: EPUBChapter?
    let onDismiss: DismissAction

    var body: some View {
        List(chapters) { chapter in
            ChapterRow(
                chapter: chapter,
                isSelected: chapter.id == currentChapter?.id
            )
            .contentShape(Rectangle())
            .onTapGesture {
                currentChapter = chapter
                onDismiss()
            }
        }
    }
}

private struct ChapterRow: View {
    let chapter: EPUBChapter
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Chapter \(chapter.index + 1)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(chapter.title)
                    .font(.body)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
    }
}

#Preview {
    ChaptersView(
        chapters: [
            EPUBChapter(id: "1", title: "Chapter 1", content: "", index: 0),
            EPUBChapter(id: "2", title: "Chapter 2", content: "", index: 1),
        ],
        currentChapter: .constant(nil)
    )
}
