import Foundation

/// Word position inside a verse. Index is 0-based.
struct VerseWordPosition: Codable, Hashable {
	let verse: Int
	let wordIndex: Int
}

/// Transient selection state used during highlighting. Converts to `VerseRange`.
struct TextSelection: Codable, Hashable {
	let bookId: String
	let chapter: Int
	var start: VerseWordPosition
	var end: VerseWordPosition
	var notesEnabled: Bool = false

	/// Collapse to a verse range (word-level selection will be refined later).
	func toVerseRange() -> VerseRange {
		let startVerse = min(start.verse, end.verse)
		let endVerse = max(start.verse, end.verse)
		return VerseRange(bookId: bookId, chapter: chapter, startVerse: startVerse, endVerse: endVerse)
	}
}

/// Helper type to identify editors presented as sheets.
struct EditorIdentifiable: Identifiable {
	let id = UUID()
}
