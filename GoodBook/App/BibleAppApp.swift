import SwiftUI

/// Application entry point that wires shared stores and environment objects.
@main
struct GoodBookApp: App {
	@StateObject private var settingsStore = SettingsStore()
	@StateObject private var highlightStore = HighlightStore()

	// Provider is kept outside environment objects to avoid reinitialization churn
	private let bibleProvider: BibleDataProvider = LocalJSONBibleProvider()

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environmentObject(settingsStore)
				.environmentObject(highlightStore)
				.environmentObject(AppEnvironment(bibleProvider: bibleProvider))
				.preferredColorScheme(settingsStore.preferredTheme.colorScheme)
				.onAppear {
					#if DEBUG
					let args = ProcessInfo.processInfo.arguments
					if args.contains("-uiTestMode") {
						// Deterministic state for UI tests
						highlightStore.resetForUITests()
					}
					#endif
				}
		}
	}
}

/// Shared environment for services that are not ObservableObjects.
final class AppEnvironment: ObservableObject {
	let bibleProvider: BibleDataProvider
	init(bibleProvider: BibleDataProvider) {
		self.bibleProvider = bibleProvider
	}
}
