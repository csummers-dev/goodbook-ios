import Foundation

/// Canonical catalog of Bible books grouped into Old Testament, Apocrypha, and New Testament.
/// - Purpose: Provide a single source of truth for rendering navigation lists in order.
/// - Rationale: Keeps ordering and group definitions centralized and testable.
struct BibleCatalog {
	/// High-level groupings used to render section headers in the sidebar.
	enum Group: String, CaseIterable, Identifiable {
		case oldTestament = "Old Testament"
		case apocrypha = "Apocrypha"
		case newTestament = "New Testament"

		var id: String { rawValue }
	}

	/// Minimal metadata describing a book for navigation.
	struct BookMeta: Identifiable, Hashable {
		/// Stable identifier used in lookups and filenames (e.g., "Genesis", "John").
		let id: String
		/// User-visible name. For now, we align name with id.
		let name: String
		/// Which catalog group this book belongs to.
		let group: Group
	}

	/// Ordered lists of books per group.
	/// NOTE: This list is intentionally explicit to preserve canonical ordering.
	static let oldTestament: [BookMeta] = [
		.init(id: "Genesis", name: "Genesis", group: .oldTestament),
		.init(id: "Exodus", name: "Exodus", group: .oldTestament),
		.init(id: "Leviticus", name: "Leviticus", group: .oldTestament),
		.init(id: "Numbers", name: "Numbers", group: .oldTestament),
		.init(id: "Deuteronomy", name: "Deuteronomy", group: .oldTestament),
		.init(id: "Joshua", name: "Joshua", group: .oldTestament),
		.init(id: "Judges", name: "Judges", group: .oldTestament),
		.init(id: "Ruth", name: "Ruth", group: .oldTestament),
		.init(id: "1 Samuel", name: "1 Samuel", group: .oldTestament),
		.init(id: "2 Samuel", name: "2 Samuel", group: .oldTestament),
		.init(id: "1 Kings", name: "1 Kings", group: .oldTestament),
		.init(id: "2 Kings", name: "2 Kings", group: .oldTestament),
		.init(id: "1 Chronicles", name: "1 Chronicles", group: .oldTestament),
		.init(id: "2 Chronicles", name: "2 Chronicles", group: .oldTestament),
		.init(id: "Ezra", name: "Ezra", group: .oldTestament),
		.init(id: "Nehemiah", name: "Nehemiah", group: .oldTestament),
		.init(id: "Esther", name: "Esther", group: .oldTestament),
		.init(id: "Job", name: "Job", group: .oldTestament),
		.init(id: "Psalms", name: "Psalms", group: .oldTestament),
		.init(id: "Proverbs", name: "Proverbs", group: .oldTestament),
		.init(id: "Ecclesiastes", name: "Ecclesiastes", group: .oldTestament),
		.init(id: "Song of Solomon", name: "Song of Solomon", group: .oldTestament),
		.init(id: "Isaiah", name: "Isaiah", group: .oldTestament),
		.init(id: "Jeremiah", name: "Jeremiah", group: .oldTestament),
		.init(id: "Lamentations", name: "Lamentations", group: .oldTestament),
		.init(id: "Ezekiel", name: "Ezekiel", group: .oldTestament),
		.init(id: "Daniel", name: "Daniel", group: .oldTestament),
		.init(id: "Hosea", name: "Hosea", group: .oldTestament),
		.init(id: "Joel", name: "Joel", group: .oldTestament),
		.init(id: "Amos", name: "Amos", group: .oldTestament),
		.init(id: "Obadiah", name: "Obadiah", group: .oldTestament),
		.init(id: "Jonah", name: "Jonah", group: .oldTestament),
		.init(id: "Micah", name: "Micah", group: .oldTestament),
		.init(id: "Nahum", name: "Nahum", group: .oldTestament),
		.init(id: "Habakkuk", name: "Habakkuk", group: .oldTestament),
		.init(id: "Zephaniah", name: "Zephaniah", group: .oldTestament),
		.init(id: "Haggai", name: "Haggai", group: .oldTestament),
		.init(id: "Zechariah", name: "Zechariah", group: .oldTestament),
		.init(id: "Malachi", name: "Malachi", group: .oldTestament),
	]

	/// Common Apocrypha set. Presence varies by tradition and translation licenses.
	static let apocrypha: [BookMeta] = [
		.init(id: "Tobit", name: "Tobit", group: .apocrypha),
		.init(id: "Judith", name: "Judith", group: .apocrypha),
		.init(id: "Additions to Esther", name: "Additions to Esther", group: .apocrypha),
		.init(id: "Wisdom", name: "Wisdom", group: .apocrypha),
		.init(id: "Sirach", name: "Sirach", group: .apocrypha),
		.init(id: "Baruch", name: "Baruch", group: .apocrypha),
		.init(id: "Letter of Jeremiah", name: "Letter of Jeremiah", group: .apocrypha),
		.init(id: "Prayer of Azariah", name: "Prayer of Azariah", group: .apocrypha),
		.init(id: "Susanna", name: "Susanna", group: .apocrypha),
		.init(id: "Bel and the Dragon", name: "Bel and the Dragon", group: .apocrypha),
		.init(id: "1 Maccabees", name: "1 Maccabees", group: .apocrypha),
		.init(id: "2 Maccabees", name: "2 Maccabees", group: .apocrypha),
	]

	static let newTestament: [BookMeta] = [
		.init(id: "Matthew", name: "Matthew", group: .newTestament),
		.init(id: "Mark", name: "Mark", group: .newTestament),
		.init(id: "Luke", name: "Luke", group: .newTestament),
		.init(id: "John", name: "John", group: .newTestament),
		.init(id: "Acts", name: "Acts", group: .newTestament),
		.init(id: "Romans", name: "Romans", group: .newTestament),
		.init(id: "1 Corinthians", name: "1 Corinthians", group: .newTestament),
		.init(id: "2 Corinthians", name: "2 Corinthians", group: .newTestament),
		.init(id: "Galatians", name: "Galatians", group: .newTestament),
		.init(id: "Ephesians", name: "Ephesians", group: .newTestament),
		.init(id: "Philippians", name: "Philippians", group: .newTestament),
		.init(id: "Colossians", name: "Colossians", group: .newTestament),
		.init(id: "1 Thessalonians", name: "1 Thessalonians", group: .newTestament),
		.init(id: "2 Thessalonians", name: "2 Thessalonians", group: .newTestament),
		.init(id: "1 Timothy", name: "1 Timothy", group: .newTestament),
		.init(id: "2 Timothy", name: "2 Timothy", group: .newTestament),
		.init(id: "Titus", name: "Titus", group: .newTestament),
		.init(id: "Philemon", name: "Philemon", group: .newTestament),
		.init(id: "Hebrews", name: "Hebrews", group: .newTestament),
		.init(id: "James", name: "James", group: .newTestament),
		.init(id: "1 Peter", name: "1 Peter", group: .newTestament),
		.init(id: "2 Peter", name: "2 Peter", group: .newTestament),
		.init(id: "1 John", name: "1 John", group: .newTestament),
		.init(id: "2 John", name: "2 John", group: .newTestament),
		.init(id: "3 John", name: "3 John", group: .newTestament),
		.init(id: "Jude", name: "Jude", group: .newTestament),
		.init(id: "Revelation", name: "Revelation", group: .newTestament),
	]

	/// All groups in the canonical rendering order.
	static let allGroupsInOrder: [(group: Group, books: [BookMeta])] = [
		(.oldTestament, oldTestament),
		(.apocrypha, apocrypha),
		(.newTestament, newTestament),
	]
}


