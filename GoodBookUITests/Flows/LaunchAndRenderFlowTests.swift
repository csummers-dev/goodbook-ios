import XCTest

final class LaunchAndRenderFlowTests: XCTestCase {
	func test_launch_and_render_reading_view() {
		let app = XCUIApplication()
		app.launchArguments += [LaunchArguments.uiTestMode]
		app.launch()

		let screen = ReadingScreen(app: app)
		// Basic existence checks using accessibility identifiers
		XCTAssertTrue(screen.highlightToggle.exists)
	}

	func test_editor_buttons_not_visible_on_launch() {
		let app = XCUIApplication()
		app.launchArguments += [LaunchArguments.uiTestMode]
		app.launch()

		XCTAssertFalse(app.buttons["editor.save"].exists)
		XCTAssertFalse(app.buttons["editor.cancel"].exists)
	}
}

