import SwiftUI

/// Root container that hosts the reading screen, global toolbar, and sidebar integration.
/// - What: Presents `ReadingView` and overlays a left drawer (`SidebarView`).
/// - Why: Centralizes navigation and global UI controls at a single composition point.
/// - How: Uses a `ZStack` to layer a `NavigationStack` under a swipeable drawer and scrim.
struct ContentView: View {
	@EnvironmentObject private var env: AppEnvironment
	@EnvironmentObject private var settings: SettingsStore
	@EnvironmentObject private var highlights: HighlightStore

	// For now we demo a single book. Navigation can expand to a selector later.
	@State private var selectedBookId: String = "John"
	@State private var showSettings = false
	@State private var showHighlights = false
	/// Sidebar open state. Toggled via toolbar button, left-edge drag, scrim tap, or drawer drag.
	@State private var isSidebarOpen = false

	var body: some View {
		ZStack(alignment: .leading) {
			NavigationStack {
				ReadingView(bookId: selectedBookId)
					.accessibilityIdentifier("reading.root")
					.navigationTitle(selectedBookId)
					.toolbar {
						ToolbarItem(placement: .topBarLeading) {
							Button(action: { withAnimation(.interactiveSpring()) { isSidebarOpen = true } }) {
								Image(systemName: "line.3.horizontal")
							}
						}
						ToolbarItem(placement: .topBarTrailing) {
							translationMenu
						}
						ToolbarItem(placement: .topBarTrailing) {
							Button { showHighlights = true } label: { Image(systemName: "highlighter") }
						}
						ToolbarItem(placement: .topBarTrailing) {
							Button { showSettings = true } label: { Image(systemName: "gear") }
						}
					}
			}

			// Left-edge swipe region to open the drawer.
			// Using a thin, transparent view keeps normal content interactions intact when the sidebar is closed.
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
	/// - Presents all `Translation` cases and binds to `SettingsStore.selectedTranslation`.
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
