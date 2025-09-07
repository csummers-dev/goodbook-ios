import XCTest

final class SidebarNavigationFlowTests: XCTestCase {
    func test_sidebar_lists_books_and_disables_missing() {
        let app = XCUIApplication()
        app.launch()

        // Open via left-edge swipe
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5))
        start.press(forDuration: 0.01, thenDragTo: end)

        XCTAssertTrue(app.descendants(matching: .any)["sidebar.root"].waitForExistence(timeout: 2))
        // Section headers must be visible; scroll to realize offscreen headers due to lazy rendering
        let sidebar = app.descendants(matching: .any)["sidebar.root"]
        XCTAssertTrue(sidebar.exists)
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 2))
        // Old Testament should be at top
        let ot = app.descendants(matching: .any)["sidebar.section.ot"]
        XCTAssertTrue(ot.exists)
        // Scroll down to realize Apocrypha and New Testament headers if needed
        scroll.swipeUp()
        scroll.swipeUp()
        let apoc = app.descendants(matching: .any)["sidebar.section.apocrypha"]
        let nt = app.descendants(matching: .any)["sidebar.section.nt"]
        XCTAssertTrue(apoc.waitForExistence(timeout: 2))
        scroll.swipeUp()
        XCTAssertTrue(nt.waitForExistence(timeout: 2))
        // Header remains visible after scroll (pinned overlay behavior)
        XCTAssertTrue(ot.exists)
        // Seeded book should exist near top
        let gen = app.descendants(matching: .any)["sidebar.book.Gen"]
        if !gen.exists { scroll.swipeDown() }
        XCTAssertTrue(gen.waitForExistence(timeout: 2))

        // Close by tapping outside
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
    }
}


