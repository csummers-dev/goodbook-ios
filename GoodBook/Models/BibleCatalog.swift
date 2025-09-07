import Foundation

/// Defines the canonical list and grouping of Bible books.
/// - What: Single source of truth for names, ids, and display order.
/// - Why: UI and availability logic render from this list so all books are
///   always visible; availability only affects enabled state.
struct BibleCatalog {
    enum Group: String, CaseIterable, Identifiable {
        case oldTestament = "Old Testament"
        case apocrypha = "Apocrypha"
        case newTestament = "New Testament"
        var id: String { rawValue }
    }

    struct BookMeta: Identifiable, Equatable {
        let id: String   // Stable id used for file lookup, e.g., "Gen", "John"
        let name: String // User-facing name, e.g., "Genesis"
        let group: Group
    }

    /// Finds the user-facing name for a given book id. Returns the id if unknown.
    static func displayName(for bookId: String) -> String {
        for section in allGroupsInOrder {
            if let match = section.books.first(where: { $0.id == bookId }) {
                return match.name
            }
        }
        return bookId
    }

    /// Ordered list of all books, grouped for sidebar sections.
    static let allGroupsInOrder: [(group: Group, books: [BookMeta])] = [
        (.oldTestament, [
            BookMeta(id: "Gen", name: "Genesis", group: .oldTestament),
            BookMeta(id: "Exo", name: "Exodus", group: .oldTestament),
            BookMeta(id: "Lev", name: "Leviticus", group: .oldTestament),
            BookMeta(id: "Num", name: "Numbers", group: .oldTestament),
            BookMeta(id: "Deu", name: "Deuteronomy", group: .oldTestament),
            BookMeta(id: "Jos", name: "Joshua", group: .oldTestament),
            BookMeta(id: "Jdg", name: "Judges", group: .oldTestament),
            BookMeta(id: "Rth", name: "Ruth", group: .oldTestament),
            BookMeta(id: "1Sa", name: "1 Samuel", group: .oldTestament),
            BookMeta(id: "2Sa", name: "2 Samuel", group: .oldTestament),
            BookMeta(id: "1Ki", name: "1 Kings", group: .oldTestament),
            BookMeta(id: "2Ki", name: "2 Kings", group: .oldTestament),
            BookMeta(id: "1Ch", name: "1 Chronicles", group: .oldTestament),
            BookMeta(id: "2Ch", name: "2 Chronicles", group: .oldTestament),
            BookMeta(id: "Ezr", name: "Ezra", group: .oldTestament),
            BookMeta(id: "Neh", name: "Nehemiah", group: .oldTestament),
            BookMeta(id: "Est", name: "Esther", group: .oldTestament),
            BookMeta(id: "Job", name: "Job", group: .oldTestament),
            BookMeta(id: "Psa", name: "Psalms", group: .oldTestament),
            BookMeta(id: "Pro", name: "Proverbs", group: .oldTestament),
            BookMeta(id: "Ecc", name: "Ecclesiastes", group: .oldTestament),
            BookMeta(id: "Sng", name: "Song of Solomon", group: .oldTestament),
            BookMeta(id: "Isa", name: "Isaiah", group: .oldTestament),
            BookMeta(id: "Jer", name: "Jeremiah", group: .oldTestament),
            BookMeta(id: "Lam", name: "Lamentations", group: .oldTestament),
            BookMeta(id: "Eze", name: "Ezekiel", group: .oldTestament),
            BookMeta(id: "Dan", name: "Daniel", group: .oldTestament),
            BookMeta(id: "Hos", name: "Hosea", group: .oldTestament),
            BookMeta(id: "Joe", name: "Joel", group: .oldTestament),
            BookMeta(id: "Amo", name: "Amos", group: .oldTestament),
            BookMeta(id: "Oba", name: "Obadiah", group: .oldTestament),
            BookMeta(id: "Jon", name: "Jonah", group: .oldTestament),
            BookMeta(id: "Mic", name: "Micah", group: .oldTestament),
            BookMeta(id: "Nah", name: "Nahum", group: .oldTestament),
            BookMeta(id: "Hab", name: "Habakkuk", group: .oldTestament),
            BookMeta(id: "Zep", name: "Zephaniah", group: .oldTestament),
            BookMeta(id: "Hag", name: "Haggai", group: .oldTestament),
            BookMeta(id: "Zec", name: "Zechariah", group: .oldTestament),
            BookMeta(id: "Mal", name: "Malachi", group: .oldTestament)
        ]),
        (.apocrypha, [
            BookMeta(id: "Tob", name: "Tobit", group: .apocrypha)
        ]),
        (.newTestament, [
            BookMeta(id: "Mat", name: "Matthew", group: .newTestament),
            BookMeta(id: "Mar", name: "Mark", group: .newTestament),
            BookMeta(id: "Luk", name: "Luke", group: .newTestament),
            BookMeta(id: "John", name: "John", group: .newTestament),
            BookMeta(id: "Act", name: "Acts", group: .newTestament),
            BookMeta(id: "Rom", name: "Romans", group: .newTestament),
            BookMeta(id: "1Co", name: "1 Corinthians", group: .newTestament),
            BookMeta(id: "2Co", name: "2 Corinthians", group: .newTestament),
            BookMeta(id: "Gal", name: "Galatians", group: .newTestament),
            BookMeta(id: "Eph", name: "Ephesians", group: .newTestament),
            BookMeta(id: "Php", name: "Philippians", group: .newTestament),
            BookMeta(id: "Col", name: "Colossians", group: .newTestament),
            BookMeta(id: "1Th", name: "1 Thessalonians", group: .newTestament),
            BookMeta(id: "2Th", name: "2 Thessalonians", group: .newTestament),
            BookMeta(id: "1Ti", name: "1 Timothy", group: .newTestament),
            BookMeta(id: "2Ti", name: "2 Timothy", group: .newTestament),
            BookMeta(id: "Tit", name: "Titus", group: .newTestament),
            BookMeta(id: "Phm", name: "Philemon", group: .newTestament),
            BookMeta(id: "Heb", name: "Hebrews", group: .newTestament),
            BookMeta(id: "Jas", name: "James", group: .newTestament),
            BookMeta(id: "1Pe", name: "1 Peter", group: .newTestament),
            BookMeta(id: "2Pe", name: "2 Peter", group: .newTestament),
            BookMeta(id: "1Jo", name: "1 John", group: .newTestament),
            BookMeta(id: "2Jo", name: "2 John", group: .newTestament),
            BookMeta(id: "3Jo", name: "3 John", group: .newTestament),
            BookMeta(id: "Jud", name: "Jude", group: .newTestament),
            BookMeta(id: "Rev", name: "Revelation", group: .newTestament)
        ])
    ]
}


