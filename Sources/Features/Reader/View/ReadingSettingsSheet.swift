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
                    Picker("テーマ", selection: $settings.theme) {
                        ForEach(ReadingTheme.allCases, id: \.self) { theme in
                            Text(theme.label).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("読書HUD") {
                    Toggle("残りページ・推定読了時間を表示", isOn: $settings.showReadingHUD)
                }

                Section("プレビュー") {
                    Text("吾輩は猫である。名前はまだ無い。")
                        .font(settings.fontSize.font)
                        .lineSpacing(settings.lineSpacing.value)
                        .foregroundStyle(settings.theme.textColor)
                        .padding(settings.padding.value)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(settings.theme.backgroundColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .navigationTitle("読書設定")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}
