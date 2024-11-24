import SwiftUI

struct ChapterRow: View {
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
        .padding(.vertical, 4)
    }
}

#Preview {
    ChapterRow(
        chapter: EPUBChapter(id: "1", title: "Test Chapter", content: "", index: 0),
        isSelected: true
    )
    .padding()
}
