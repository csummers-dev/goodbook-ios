import Foundation
import Combine

/// ViewModel for the reading screen. Loads a book for the selected translation
/// and exposes state to render verses and error messages.
@MainActor
final class ReadingViewModel: ObservableObject {
	@Published private(set) var book: BibleBook?
	@Published var isShowingHighlights: Bool = true
	@Published var errorMessage: String?

	let bookId: String
	private var provider: BibleDataProvider?
	private weak var settings: SettingsStore?

	init(bookId: String, provider: BibleDataProvider? = nil, settings: SettingsStore? = nil) {
		self.bookId = bookId
		self.provider = provider
		self.settings = settings
	}

	/// Configure dependencies after object initialization to satisfy SwiftUI's
	/// `@StateObject` lifecycle.
	func configure(provider: BibleDataProvider, settings: SettingsStore) {
		self.provider = provider
		self.settings = settings
	}

	/// Load the current book for the active translation.
	func load() async {
		guard let provider, let settings else { return }
		do {
			book = try await provider.loadBook(bookId: bookId, translation: settings.selectedTranslation)
			errorMessage = nil
		} catch {
			errorMessage = String(describing: error)
		}
	}

	/// Reload when the translation changes.
	func reloadForTranslationChange() async {
		await load()
	}
}
