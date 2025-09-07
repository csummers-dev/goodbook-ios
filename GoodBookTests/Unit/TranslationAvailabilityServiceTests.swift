import XCTest
@testable import GoodBook

final class TranslationAvailabilityServiceTests: XCTestCase {
    func test_isBookAvailable_true_when_seed_exists() {
        let service = TranslationAvailabilityService(bundle: .main)
        XCTAssertTrue(service.isBookAvailable(bookId: "Gen", translation: .esv))
    }

    func test_isBookAvailable_false_when_missing() {
        let service = TranslationAvailabilityService(bundle: .main)
        // Use a non-canonical fake id to ensure negative path remains valid
        XCTAssertFalse(service.isBookAvailable(bookId: "ZZZ_NONEXISTENT", translation: .niv))
    }
}


