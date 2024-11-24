import SwiftUI

struct ReaderSidebar: View {
    let chapters: [EPUBChapter]
    @Binding var currentChapter: EPUBChapter?
    @ObservedObject var settings: ReaderSettings
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        List {
            // Appearance Section
            Section {
                // Themes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 60, maximum: 80))
                        ], spacing: 12
                    ) {
                        ForEach(ReaderTheme.defaults) { theme in
                            ThemeButton(
                                theme: theme,
                                isSelected: theme.id == settings.theme.id,
                                colorScheme: colorScheme
                            ) {
                                withAnimation {
                                    settings.theme = theme
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Typography
                VStack(alignment: .leading, spacing: 16) {
                    // Font Family
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Font")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Font Family", selection: $settings.fontName) {
                            ForEach(Array(ReaderSettings.availableFonts.keys.sorted()), id: \.self)
                            { name in
                                Text(name)
                                    .tag(name)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    // Font Size
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Size")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text("A")
                                .font(.system(size: 12))
                            Slider(
                                value: $settings.fontSize,
                                in: 12...24,
                                step: 1
                            )
                            Text("A")
                                .font(.system(size: 24))
                        }
                    }

                    // Line Spacing
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Line Spacing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $settings.lineSpacing) {
                            Text("Compact").tag(1.2)
                            Text("Normal").tag(1.4)
                            Text("Relaxed").tag(1.6)
                        }
                        .pickerStyle(.segmented)
                    }
                }
            } header: {
                Text("Appearance")
            }

            // Chapters Section
            Section {
                ForEach(chapters) { chapter in
                    ChapterRow(
                        chapter: chapter,
                        isSelected: chapter.id == currentChapter?.id
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            currentChapter = chapter
                        }
                    }
                }
            } header: {
                Text("Chapters")
            }
        }
        .listStyle(.sidebar)
    }
}

#Preview {
    ReaderSidebar(
        chapters: [
            EPUBChapter(id: "1", title: "Chapter 1", content: "", index: 0),
            EPUBChapter(id: "2", title: "Chapter 2", content: "", index: 1),
        ],
        currentChapter: .constant(nil),
        settings: ReaderSettings()
    )
    .frame(width: 300)
}
