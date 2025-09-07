import Foundation
@testable import GoodBook

final class FakeBibleDataProvider: BibleDataProvider {
	var result: Result<BibleBook, Error>

	init(result: Result<BibleBook, Error>) {
		self.result = result
	}

	func loadBook(bookId: String, translation: Translation) async throws -> BibleBook {
		return try result.get()
	}
}

