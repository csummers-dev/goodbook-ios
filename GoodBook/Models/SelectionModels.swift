import Foundation

/// Word position inside a verse. `wordIndex` is 0-based.
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

/// Precise word-level span across verses within a single chapter.
/// - Why: Enables true word-by-word and multi-verse fidelity for highlights and actions,
///   while remaining compatible with existing verse-range persistence.
/// - How: Tracks `(verse, wordIndex)` for start and end, and provides helpers to
///   normalize bounds and collapse to a `VerseRange` for storage and list display.
struct WordSpan: Codable, Hashable {
	let bookId: String
	let chapter: Int
	var start: VerseWordPosition
	var end: VerseWordPosition

	/// Returns start and end ordered so that `start <= end` by verse then word index.
	var normalized: (start: VerseWordPosition, end: VerseWordPosition) {
		if (start.verse < end.verse) || (start.verse == end.verse && start.wordIndex <= end.wordIndex) {
			return (start, end)
		} else {
			return (end, start)
		}
	}

	/// Collapses to a contiguous verse range for compatibility with
	/// persistence and list display.
	func toVerseRange() -> VerseRange {
		let s = normalized.start
		let e = normalized.end
		return VerseRange(bookId: bookId, chapter: chapter, startVerse: s.verse, endVerse: e.verse)
	}
}
