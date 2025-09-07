import SwiftUI

/// Root container view that hosts the reading screen and global toolbar.
struct ContentView: View {
	@EnvironmentObject private var env: AppEnvironment
	@EnvironmentObject private var settings: SettingsStore
	@EnvironmentObject private var highlights: HighlightStore

	// For now we demo a single book. Navigation can expand to a selector later.
	@State private var selectedBookId: String = "John"
	@State private var showSettings = false
	@State private var showHighlights = false

	var body: some View {
		NavigationStack {
			ReadingView(bookId: selectedBookId)
				.accessibilityIdentifier("reading.root")
				.navigationTitle(selectedBookId)
				.toolbar {
					ToolbarItemGroup(placement: .topBarTrailing) {
						translationMenu
						Button {
							showHighlights = true
						} label: { Image(systemName: "highlighter") }
						Button {
							showSettings = true
						} label: { Image(systemName: "gear") }
					}
				}
		}
		.sheet(isPresented: $showSettings) { SettingsView() }
		.sheet(isPresented: $showHighlights) { HighlightsListView() }
		.environmentObject(env)
	}

	/// Translation picker displayed in the toolbar.
	private var translationMenu: some View {
		Menu {
			Picker("Translation", selection: $settings.selectedTranslation) {
				ForEach(Translation.allCases) { t in
					Text(t.displayName).tag(t)
				}
			}
		} label: {
			Text(settings.selectedTranslation.displayName)
		}
	}
}

#Preview {
	ContentView()
		.environmentObject(SettingsStore())
		.environmentObject(HighlightStore())
		.environmentObject(AppEnvironment(bibleProvider: LocalJSONBibleProvider()))
}
