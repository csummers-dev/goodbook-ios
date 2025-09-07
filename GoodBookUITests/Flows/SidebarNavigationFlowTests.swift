import XCTest

final class SidebarNavigationFlowTests: XCTestCase {
    func test_open_and_close_sidebar_with_gestures() {
        let app = XCUIApplication()
        app.launchArguments += [LaunchArguments.uiTestMode]
        app.launch()

        // Open via left-edge swipe for maximum reliability in CI
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5))
        start.press(forDuration: 0.01, thenDragTo: end)

        let sidebar = app.descendants(matching: .any)["sidebar.root"]
        XCTAssertTrue(sidebar.waitForExistence(timeout: 3))
        // Verify a known top-level book row is present (more robust than header matching across OS versions)
        XCTAssertTrue(app.descendants(matching: .any)["sidebar.book.Genesis"].exists)

        // Close by tapping outside (on the scrim). Coordinates avoid relying on scrim accessibility.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        let notHittable = NSPredicate(format: "isHittable == FALSE")
        expectation(for: notHittable, evaluatedWith: sidebar)
        waitForExpectations(timeout: 3)
    }
}


