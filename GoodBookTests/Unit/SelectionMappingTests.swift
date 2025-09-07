import XCTest
@testable import GoodBook

final class SelectionMappingTests: XCTestCase {

    func test_WordSpan_normalized_orders_positions() {
        let a = VerseWordPosition(verse: 3, wordIndex: 5)
        let b = VerseWordPosition(verse: 2, wordIndex: 10)
        let span = WordSpan(bookId: "John", chapter: 1, start: a, end: b)
        let n = span.normalized
        XCTAssertEqual(n.start.verse, 2)
        XCTAssertEqual(n.end.verse, 3)
    }

    func test_WordSpan_toVerseRange_collapses_to_inclusive_range() {
        let start = VerseWordPosition(verse: 2, wordIndex: 1)
        let end = VerseWordPosition(verse: 4, wordIndex: 0)
        let span = WordSpan(bookId: "John", chapter: 10, start: start, end: end)
        let range = span.toVerseRange()
        XCTAssertEqual(range.bookId, "John")
        XCTAssertEqual(range.chapter, 10)
        XCTAssertEqual(range.startVerse, 2)
        XCTAssertEqual(range.endVerse, 4)
    }
}


