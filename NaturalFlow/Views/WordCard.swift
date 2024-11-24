import SwiftUI

struct WordCard: View {
    let word: Word
    let isInLearningList: Bool
    let onToggleLearning: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Word header
            HStack {
                Text(word.term)
                    .font(.system(size: 24, weight: .medium))
                Spacer()
                Button {
                    onToggleLearning(!isInLearningList)
                } label: {
                    Image(systemName: isInLearningList ? "star.fill" : "star")
                        .foregroundStyle(isInLearningList ? .yellow : .gray)
                }
                .buttonStyle(.plain)
            }

            // Pronunciation
            Text(word.pronunciation)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.secondary)

            Divider()

            // Translation
            VStack(alignment: .leading, spacing: 8) {
                Text("Translation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(word.translation)
                    .font(.body)
            }

            if let context = word.context {
                Divider()

                // Context
                VStack(alignment: .leading, spacing: 8) {
                    Text("Context")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(context)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
    }
}
