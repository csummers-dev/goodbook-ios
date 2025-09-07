import Foundation

/// Abstraction for loading Bible content.
protocol BibleDataProvider {
	/// Load a full book for a given translation.
	func loadBook(bookId: String, translation: Translation) async throws -> BibleBook
}

/// Loads Bible data from bundled JSON. We support multiple bundle layouts.
final class LocalJSONBibleProvider: BibleDataProvider {
    private let bundle: Bundle

    /// Initialize with a specific bundle for resource lookup. Defaults to the app's main bundle.
    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }
	private struct ProviderError: LocalizedError {
		let message: String
		var errorDescription: String? { message }
	}

	/// Loads and decodes a book JSON for the selected translation.
	/// - Throws: a descriptive error if the resource cannot be located or decoded.
	func loadBook(bookId: String, translation: Translation) async throws -> BibleBook {
		guard let url = resolveBookURL(bookId: bookId, translation: translation) else {
			throw ProviderError(message: "Missing resource for \(bookId) [\(translation.rawValue)] in bundle")
		}
		let data = try Data(contentsOf: url)
		let decoder = JSONDecoder()
		decoder.keyDecodingStrategy = .useDefaultKeys
		return try decoder.decode(BibleBook.self, from: data)
	}

	/// Try several bundle layouts to find the JSON for the given book/translation.
	/// Supports both file references and folder references copied into the app bundle.
	private func resolveBookURL(bookId: String, translation: Translation) -> URL? {
		let fileName = bookId
		let candidateSubdirs = [
			"Bibles/\(translation.rawValue)",
			"Resources/Bibles/\(translation.rawValue)",
			"AppResources/Bibles/\(translation.rawValue)",
			"Contents/Resources/Bibles/\(translation.rawValue)",
			"Contents/AppResources/Bibles/\(translation.rawValue)",
		]
		for subdir in candidateSubdirs {
			if let url = bundle.url(forResource: fileName, withExtension: "json", subdirectory: subdir) {
				return url
			}
		}

		// Fallback: scan all JSON files if subdirectory lookups fail.
		if let all = bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) {
			let match = all.first { url in
				let path = url.path
				return path.contains("/Bibles/\(translation.rawValue)/\(bookId).json")
			}
			if let match { return match }
		}
		// Last resort: if the selected translation has no data, try any translation for the same book
		if let all = bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) {
			let match = all.first { url in url.lastPathComponent == "\(bookId).json" }
			if let match { return match }
		}
		return nil
	}
}
