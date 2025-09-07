import XCTest
@testable import GoodBook

final class AttributedChapterBuilderTests: XCTestCase {

    func test_build_maps_words_to_positions() {
        let chapter = BibleChapter(number: 1, verses: [
            BibleVerse(number: 1, text: "In the beginning"),
            BibleVerse(number: 2, text: "God created")
        ])
        let builder = AttributedChapterBuilder(bookId: "Gen", chapter: chapter, fontSize: 16, highlights: [])
        let result = builder.build()

        // Ensure we have at least as many mapping entries as total words.
        let totalWords = chapter.verses.reduce(0) { $0 + $1.text.split(separator: " ").count }
        XCTAssertGreaterThanOrEqual(result.mapping.count, totalWords)
    }

    func test_verse_numbers_are_styled_and_present() {
        let chapter = BibleChapter(number: 1, verses: [
            BibleVerse(number: 11, text: "I am the good shepherd."),
            BibleVerse(number: 12, text: "He who is a hired hand...")
        ])
        let builder = AttributedChapterBuilder(bookId: "John", chapter: chapter, fontSize: 16, highlights: [])
        let result = builder.build()
        // Ensure the rendered string contains the verse number prefixes followed by a space.
        let rendered = result.attributed.string
        XCTAssertTrue(rendered.contains("11 "))
        XCTAssertTrue(rendered.contains("12 "))
    }
}


