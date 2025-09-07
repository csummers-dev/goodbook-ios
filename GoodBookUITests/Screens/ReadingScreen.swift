import XCTest

struct ReadingScreen {
	let app: XCUIApplication

	var root: XCUIElement { app.otherElements["reading.root"] }
	var highlightToggle: XCUIElement { app.descendants(matching: .any)["reading.toggle.highlights"] }

	func verseCell(chapter: Int, verse: Int) -> XCUIElement {
		app.staticTexts["reading.verse.\(chapter)-\(verse)"]
	}
}

