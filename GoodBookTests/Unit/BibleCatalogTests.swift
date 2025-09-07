import XCTest
@testable import GoodBook

final class BibleCatalogTests: XCTestCase {
    func test_displayName_returns_full_name_for_known_id() {
        XCTAssertEqual(BibleCatalog.displayName(for: "Gen"), "Genesis")
        XCTAssertEqual(BibleCatalog.displayName(for: "John"), "John")
    }

    func test_displayName_falls_back_to_id_for_unknown() {
        XCTAssertEqual(BibleCatalog.displayName(for: "ZZZ"), "ZZZ")
    }
}


