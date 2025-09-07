import Foundation

/// A Bible book consisting of chapters and verses. Loaded from JSON per translation.
struct BibleBook: Codable, Identifiable, Equatable {
	/// Stable identifier used in lookups and resource filenames (e.g., "John").
	let id: String
	/// Display name for the book (e.g., "John").
	let name: String
	/// Ordered chapters in this book.
	let chapters: [BibleChapter]
}

/// A chapter with a chapter number and list of verses.
struct BibleChapter: Codable, Identifiable, Equatable {
	let number: Int
	let verses: [BibleVerse]
	var id: Int { number }
}

/// A single verse represented by its number and text content.
struct BibleVerse: Codable, Identifiable, Equatable {
	let number: Int
	let text: String
	var id: Int { number }
}

/// A single verse reference like John 10:10
struct VerseReference: Codable, Hashable, Identifiable {
	let bookId: String
	let chapter: Int
	let verse: Int
	var id: String { "\(bookId)-\(chapter)-\(verse)" }
}

/// A contiguous verse range (inclusive) within one chapter.
struct VerseRange: Codable, Hashable {
	let bookId: String
	let chapter: Int
	let startVerse: Int
	let endVerse: Int
}
