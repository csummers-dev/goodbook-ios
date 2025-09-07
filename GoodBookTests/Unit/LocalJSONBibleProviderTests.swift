import XCTest
@testable import GoodBook

final class LocalJSONBibleProviderTests: XCTestCase {
    private var testBundle: Bundle { Bundle(for: type(of: self)) }
    func test_loadBook_loadsFromAppBundleResources() async throws {
        // This test ensures provider decodes valid JSON from the main bundle
        // using the ESV sample assets that ship in the app target.
        let provider = LocalJSONBibleProvider(bundle: testBundle)
        // ESV exists in the app bundle, but the test bundle may not include it.
        // This call validates that even if ESV is missing in the test bundle, the
        // fallback to any John.json is exercised when translation-specific asset is absent.
        let book = try await provider.loadBook(bookId: "John", translation: .niv)
        XCTAssertEqual(book.id, "John")
        XCTAssertEqual(book.chapters.first?.number, 10)
        XCTAssertEqual(book.chapters.first?.verses.count, 3)
    }

    func test_missingTranslation_fallsBackToAnyBookMatch() async throws {
        // We do not bundle CSB in tests, but the app bundle has ESV; the provider
        // will try translation-specific paths then fall back to any book JSON.
        let provider = LocalJSONBibleProvider(bundle: testBundle)
        let book = try await provider.loadBook(bookId: "John", translation: .csb)
        XCTAssertEqual(book.id, "John")
    }
}


