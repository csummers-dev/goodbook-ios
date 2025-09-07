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
	@State private var isSidebarOpen = false

	var body: some View {
		ZStack(alignment: .leading) {
			NavigationStack {
				ReadingView(bookId: selectedBookId)
					.accessibilityIdentifier("reading.root")
					.navigationTitle(BibleCatalog.displayName(for: selectedBookId))
					.toolbar {
						ToolbarItem(placement: .topBarLeading) {
							Button(action: { withAnimation(.interactiveSpring()) { isSidebarOpen = true } }) {
								Image(systemName: "line.3.horizontal")
							}
							.accessibilityIdentifier("sidebar.button.open")
						}
						ToolbarItemGroup(placement: .topBarTrailing) {
							translationMenu
							Button { showHighlights = true } label: { Image(systemName: "highlighter") }
							Button { showSettings = true } label: { Image(systemName: "gear") }
						}
					}
			}

			// Left-edge swipe region to open the drawer.
			Color.clear
				.contentShape(Rectangle())
				.frame(width: 12)
				.gesture(DragGesture(minimumDistance: 10).onEnded { value in
					if value.translation.width > 40 { withAnimation(.interactiveSpring()) { isSidebarOpen = true } }
				})
				.allowsHitTesting(!isSidebarOpen)

			SidebarView(
				isOpen: $isSidebarOpen,
				selectedTranslation: settings.selectedTranslation,
				onSelectBook: { id in selectedBookId = id }
			)
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
