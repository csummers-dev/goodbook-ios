import Foundation
import Combine

/// Persists user highlights locally as JSON in the app's documents directory.
/// Stores translation-agnostic verse ranges for portability across translations.
final class HighlightStore: ObservableObject {
	@Published private(set) var highlights: [Highlight] = []
	private let fileName = "highlights.json"

	// MARK: - Lifecycle
	init() {
		load()
	}

	// MARK: - Querying
	/// Return highlights for a specific book/chapter.
	func highlights(for bookId: String, chapter: Int) -> [Highlight] {
		highlights.filter { $0.range.bookId == bookId && $0.range.chapter == chapter }
	}

	// MARK: - Mutations
	/// Insert or update a highlight by identity.
	func upsert(_ highlight: Highlight) {
		if let idx = highlights.firstIndex(where: { $0.id == highlight.id }) {
			highlights[idx] = highlight
		} else {
			highlights.append(highlight)
		}
		save()
	}

	/// Delete a highlight.
	func delete(_ highlight: Highlight) {
		highlights.removeAll { $0.id == highlight.id }
		save()
	}

	#if DEBUG
	/// Clear persisted highlights for deterministic UI tests.
	func resetForUITests() {
		highlights = []
		save()
	}
	#endif

	// MARK: - Persistence
	private func save() {
		guard let url = storageURL() else { return }
		do {
			let data = try JSONEncoder().encode(highlights)
			try data.write(to: url, options: .atomic)
		} catch {
			// For now, we fail silently. Consider surfacing via telemetry.
		}
	}

	private func load() {
		guard let url = storageURL(), FileManager.default.fileExists(atPath: url.path) else { return }
		do {
			let data = try Data(contentsOf: url)
			highlights = try JSONDecoder().decode([Highlight].self, from: data)
		} catch {
			// If corrupt, reset to empty to avoid blocking the UI
			highlights = []
		}
	}

	private func storageURL() -> URL? {
		FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(fileName)
	}
}
