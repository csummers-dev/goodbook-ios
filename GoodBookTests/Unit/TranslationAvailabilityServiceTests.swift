import XCTest
@testable import GoodBook

final class TranslationAvailabilityServiceTests: XCTestCase {
    func test_isBookAvailable_true_when_resource_exists() {
        let service = TranslationAvailabilityService(bundle: .main)
        // ESV/John.json exists in the app bundle resources.
        XCTAssertTrue(service.isBookAvailable(bookId: "John", translation: .esv))
    }

    func test_isBookAvailable_false_when_resource_missing() {
        let service = TranslationAvailabilityService(bundle: .main)
        // Use a book that we don't bundle at all to ensure false.
        XCTAssertFalse(service.isBookAvailable(bookId: "NonexistentBookXYZ", translation: .esv))
    }
}


