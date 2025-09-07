import XCTest
@testable import GoodBook

final class HighlightCodingTests: XCTestCase {

    func test_encode_decode_roundtrip_with_wordSpan() throws {
        let range = VerseRange(bookId: "John", chapter: 5, startVerse: 3, endVerse: 6)
        let span = WordSpan(bookId: "John", chapter: 5, start: .init(verse: 3, wordIndex: 1), end: .init(verse: 6, wordIndex: 2))
        let original = Highlight(range: range, wordSpan: span, color: .yellow, note: "Test")

        let data = try JSONEncoder().encode([original])
        let decoded = try JSONDecoder().decode([Highlight].self, from: data)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].range.startVerse, 3)
        XCTAssertEqual(decoded[0].range.endVerse, 6)
        XCTAssertEqual(decoded[0].wordSpan?.normalized.start.verse, 3)
        XCTAssertEqual(decoded[0].wordSpan?.normalized.end.verse, 6)
        XCTAssertEqual(decoded[0].color, .yellow)
        XCTAssertEqual(decoded[0].note, "Test")
    }
}


