import Foundation

/// Answers whether a given book resource exists for a translation in the app bundle.
/// - Purpose: Allow UI to disable navigation targets that lack assets for the selected translation.
/// - Rationale: Mirrors the `LocalJSONBibleProvider` lookup paths without decoding data.
struct TranslationAvailabilityService {
	private let bundle: Bundle

	/// Initialize with a bundle (defaults to main). Tests can inject a custom bundle.
	init(bundle: Bundle = .main) { self.bundle = bundle }

	/// Return true if a JSON resource for the book exists under any supported path for the translation.
	func isBookAvailable(bookId: String, translation: Translation) -> Bool {
		let fileName = bookId
		let candidateSubdirs = [
			"Bibles/\(translation.rawValue)",
			"Resources/Bibles/\(translation.rawValue)",
			"AppResources/Bibles/\(translation.rawValue)",
			"Contents/Resources/Bibles/\(translation.rawValue)",
			"Contents/AppResources/Bibles/\(translation.rawValue)",
		]
		for subdir in candidateSubdirs {
			if bundle.url(forResource: fileName, withExtension: "json", subdirectory: subdir) != nil {
				return true
			}
		}
		return false
	}
}


