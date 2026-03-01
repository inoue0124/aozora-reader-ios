import SwiftUI

struct ReadingSettingsSheet: View {
    @Bindable var settings: ReadingSettings

    var body: some View {
        NavigationStack {
            Form {
                Section("表示モード") {
                    Picker("表示", selection: $settings.layoutMode) {
                        ForEach(ReadingLayoutMode.allCases, id: \.self) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("フォントサイズ") {
                    Picker("サイズ", selection: $settings.fontSize) {
                        ForEach(FontSizeLevel.allCases, id: \.self) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("フォント") {
                    ForEach(FontFamily.allCases, id: \.self) { family in
                        Button {
                            settings.fontFamily = family
                        } label: {
                            HStack {
                                Text(family.label)
                                    .font(.custom(family.uiFontName, size: 16))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if settings.fontFamily == family {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppColors.accent)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .accessibilityLabel(family.label)
                        .accessibilityAddTraits(settings.fontFamily == family ? .isSelected : [])
                    }
                }

                Section("行間") {
                    Picker("行間", selection: $settings.lineSpacing) {
                        ForEach(LineSpacingLevel.allCases, id: \.self) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("余白") {
                    Picker("余白", selection: $settings.padding) {
                        ForEach(PaddingLevel.allCases, id: \.self) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("テーマ") {
                    themeSelector
                }

                Section("読書HUD") {
                    Toggle("残りページ・推定読了時間を表示", isOn: $settings.showReadingHUD)
                }

                Section("プレビュー") {
                    Text("吾輩は猫である。名前はまだ無い。")
                        .font(.custom(settings.fontFamily.uiFontName, size: CGFloat(settings.fontSize.rawValue)))
                        .lineSpacing(settings.lineSpacing.value)
                        .foregroundStyle(settings.theme.textColor)
                        .padding(settings.padding.value)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(settings.theme.backgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .animation(.easeInOut(duration: 0.25), value: settings.fontSize)
                        .animation(.easeInOut(duration: 0.25), value: settings.theme)
                        .animation(.easeInOut(duration: 0.25), value: settings.lineSpacing)
                        .animation(.easeInOut(duration: 0.25), value: settings.padding)
                        .animation(.easeInOut(duration: 0.25), value: settings.fontFamily)
                }
            }
            .navigationTitle("読書設定")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
    }

    private var themeSelector: some View {
        HStack(spacing: 12) {
            ForEach(ReadingTheme.allCases, id: \.self) { theme in
                ThemeCircle(
                    theme: theme,
                    isSelected: settings.theme == theme
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        settings.theme = theme
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

private struct ThemeCircle: View {
    let theme: ReadingTheme
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(theme.backgroundColor)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected ? AppColors.accent : Color.secondary.opacity(0.3),
                                    lineWidth: isSelected ? 2.5 : 1
                                )
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

                    Text("あ")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(theme.textColor)
                }

                Text(theme.label)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? AppColors.accent : .secondary)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.label)テーマ")
        .accessibilityValue(isSelected ? "選択中" : "")
    }
}
