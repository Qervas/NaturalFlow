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

