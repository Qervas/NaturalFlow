import SwiftUI

struct ReaderSettingsView: View {
    @ObservedObject var settings: ReaderSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Themes
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(.headline)
                ThemePickerView(selectedTheme: $settings.theme)
            }

            Divider()

            // Typography
            VStack(alignment: .leading, spacing: 12) {
                Text("Typography")
                    .font(.headline)

                // Font size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text Size")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("A").font(.system(size: 14))
                        Slider(value: $settings.fontSize, in: 14...24)
                        Text("A").font(.system(size: 24))
                    }
                }

                // Font picker
                Picker("Font", selection: $settings.fontName) {
                    ForEach(Array(ReaderSettings.availableFonts), id: \.key) { font in
                        Text(font.key)
                            .font(.custom(font.value, size: 17))
                            .tag(font.value)
                    }
                }
                .pickerStyle(.menu)

                // Line spacing
                VStack(alignment: .leading, spacing: 8) {
                    Text("Line Spacing")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $settings.lineSpacing) {
                        Text("Compact").tag(1.2)
                        Text("Normal").tag(1.4)
                        Text("Relaxed").tag(1.6)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(.background)
    }
}

// Preview provider for development
#Preview {
    ReaderSettingsView(settings: ReaderSettings())
}
