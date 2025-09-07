import SwiftUI

/// Basic settings: theme and font size. Translation is controlled from the toolbar picker.
struct SettingsView: View {
	@EnvironmentObject private var settings: SettingsStore

	var body: some View {
		Form {
			Section("Theme") {
				Picker("Preferred", selection: $settings.preferredTheme) {
					ForEach(Theme.allCases) { theme in
						Text(theme.id.capitalized).tag(theme)
					}
				}
			}
			Section("Reader Font Size") {
				Slider(value: $settings.readerFontSize, in: 14...28, step: 1) {
					Text("Font Size")
				}
				Text("\(Int(settings.readerFontSize)) pt")
			}
		}
		.navigationTitle("Settings")
	}
}

#Preview { SettingsView().environmentObject(SettingsStore()) }
