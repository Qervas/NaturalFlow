import SwiftUI

struct ThemePickerView: View {
    @Binding var selectedTheme: ReaderTheme
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60, maximum: 80))], spacing: 12) {
            ThemeButton(
                theme: ReaderTheme.systemTheme(for: colorScheme),
                isSelected: selectedTheme.id == "system",
                colorScheme: colorScheme
            ) {
                selectedTheme = ReaderTheme.systemTheme(for: colorScheme)
            }

            ForEach(ReaderTheme.defaults.dropFirst()) { theme in
                ThemeButton(
                    theme: theme,
                    isSelected: theme.id == selectedTheme.id,
                    colorScheme: colorScheme
                ) {
                    selectedTheme = theme
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ThemeButton: View {
    let theme: ReaderTheme
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.backgroundColor)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text("Aa")
                            .foregroundColor(theme.textColor)
                            .font(.system(size: 14, weight: .medium))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                                lineWidth: 2
                            )
                    )
                    .environment(\.colorScheme, theme.id == "system" ? colorScheme : .light)

                Text(theme.name)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ThemePickerView(selectedTheme: .constant(ReaderTheme.defaults[0]))
        .padding()
}
