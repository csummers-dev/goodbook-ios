import XCTest
@testable import GoodBook

@MainActor
final class ReadingViewModelTests: XCTestCase {
	func test_load_success_sets_book_and_clears_error() async throws {
		let book = BibleBook(id: "John", name: "John", chapters: [
			BibleChapter(number: 10, verses: [BibleVerse(number: 10, text: "x")])
		])
		let fake = FakeBibleDataProvider(result: .success(book))
		let settings = SettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
		let vm = ReadingViewModel(bookId: "John")
		vm.configure(provider: fake, settings: settings)

		await vm.load()

		XCTAssertNotNil(vm.book)
		XCTAssertNil(vm.errorMessage)
	}

	func test_load_failure_sets_error() async throws {
		struct E: Error {}
		let fake = FakeBibleDataProvider(result: .failure(E()))
		let settings = SettingsStore(userDefaults: UserDefaults(suiteName: UUID().uuidString)!)
		let vm = ReadingViewModel(bookId: "John")
		vm.configure(provider: fake, settings: settings)

		await vm.load()

		XCTAssertNotNil(vm.errorMessage)
	}
}

