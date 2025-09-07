import XCTest

final class SidebarNavigationFlowTests: XCTestCase {
    func test_open_and_close_sidebar_with_gestures() {
        let app = XCUIApplication()
        app.launchArguments += [LaunchArguments.uiTestMode]
        app.launch()

        // Open via toolbar button (line.3.horizontal)
        app.buttons.matching(identifier: "line.3.horizontal").firstMatch.tap()
        XCTAssertTrue(app.otherElements["sidebar.root"].exists)

        // Verify sections exist
        XCTAssertTrue(app.staticTexts["sidebar.section.ot"].exists)
        XCTAssertTrue(app.staticTexts["sidebar.section.apocrypha"].exists)
        XCTAssertTrue(app.staticTexts["sidebar.section.nt"].exists)

        // Close by tapping scrim
        app.otherElements["sidebar.scrim"].tap()
        XCTAssertFalse(app.otherElements["sidebar.scrim"].exists)
    }
}


