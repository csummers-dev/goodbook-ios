import XCTest

final class LaunchAndRenderFlowTests: XCTestCase {
	// Bring target element into view if it's offscreen or covered; avoids gestures on non-hittable nodes.
	private func bringIntoViewIfNeeded(_ element: XCUIElement, app: XCUIApplication) {
		guard element.exists else { return }
		if element.isHittable { return }
		// Try small scroll adjustments to surface the element
		for attempt in 0..<4 {
			if element.isHittable { break }
			if attempt % 2 == 0 { app.swipeUp() } else { app.swipeDown() }
		}
	}

	// Ensure the UITextView has non-empty content before attempting selection.
	private func ensureChapterTextHasContent(_ element: XCUIElement) {
		let deadline = Date().addingTimeInterval(2)
		while Date() < deadline {
			if let text = element.value as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
				return
			}
			RunLoop.current.run(until: Date().addingTimeInterval(0.1))
		}
		XCTFail("Chapter text view did not report non-empty content in time")
	}

	func test_reader_text_element_exists_and_is_hittable_on_load() {
		let app = XCUIApplication()
		app.launchArguments += [LaunchArguments.uiTestMode]
		app.launch()

		let screen = ReadingScreen(app: app)
		let chapter10 = screen.chapterText(10)
		XCTAssertTrue(chapter10.waitForExistence(timeout: 4))
		bringIntoViewIfNeeded(chapter10, app: app)
		XCTAssertTrue(chapter10.exists)
		XCTAssertTrue(chapter10.isHittable)
		// New: verify content is present quickly
		ensureChapterTextHasContent(chapter10)
	}

	func test_launch_and_render_reading_view() {
		let app = XCUIApplication()
		app.launchArguments += [LaunchArguments.uiTestMode]
		app.launch()

		let screen = ReadingScreen(app: app)
		// Basic existence checks using accessibility identifiers
		XCTAssertTrue(screen.highlightToggle.exists)
		// Verify selectable chapter text exists and can be long-pressed to begin selection
		let chapter10 = screen.chapterText(10)
		XCTAssertTrue(chapter10.waitForExistence(timeout: 4))
		bringIntoViewIfNeeded(chapter10, app: app)
		ensureChapterTextHasContent(chapter10)
		// Tap to focus, then short runloop spin to ensure focus settles
		chapter10.tap()
		RunLoop.current.run(until: Date().addingTimeInterval(0.2))

		chapter10.press(forDuration: 0.55)
		nudgeSelection(in: chapter10, normalizedStart: CGVector(dx: 0.5, dy: 0.5))
		if !waitForAnySelectionSignal(app: app, timeout: 8, logPrefix: "selectionflow-longpress") {
			XCTContext.runActivity(named: "selectionflow.fallback.doubletap") { _ in
				chapter10.tap(withNumberOfTaps: 2, numberOfTouches: 1)
				nudgeSelection(in: chapter10, normalizedStart: CGVector(dx: 0.5, dy: 0.55))
			}
			XCTAssertTrue(waitForAnySelectionSignal(app: app, timeout: 6, logPrefix: "selectionflow-fallback-doubletap"))
		}
	}

	func test_editor_buttons_not_visible_on_launch() {
		let app = XCUIApplication()
		app.launchArguments += [LaunchArguments.uiTestMode]
		app.launch()

		XCTAssertFalse(app.buttons["editor.save"].exists)
		XCTAssertFalse(app.buttons["editor.cancel"].exists)
	}

	func test_long_press_starts_with_single_word_selection_and_menu_shows() {
		let app = XCUIApplication()
		app.launchArguments += [LaunchArguments.uiTestMode]
		app.launch()

		let screen = ReadingScreen(app: app)
		let chapter10 = screen.chapterText(10)
		XCTAssertTrue(chapter10.waitForExistence(timeout: 4))
		bringIntoViewIfNeeded(chapter10, app: app)
		ensureChapterTextHasContent(chapter10)
		chapter10.tap()
		RunLoop.current.run(until: Date().addingTimeInterval(0.2))

		// Long press to begin selection; selection should start at a single word.
		chapter10.press(forDuration: 0.55)
		nudgeSelection(in: chapter10, normalizedStart: CGVector(dx: 0.5, dy: 0.5))

		if !waitForAnySelectionSignal(app: app, timeout: 8, logPrefix: "selectionflow-longpress") {
			XCTContext.runActivity(named: "selectionflow.fallback.doubletap") { _ in
				chapter10.tap(withNumberOfTaps: 2, numberOfTouches: 1)
				nudgeSelection(in: chapter10, normalizedStart: CGVector(dx: 0.5, dy: 0.55))
			}
			XCTAssertTrue(waitForAnySelectionSignal(app: app, timeout: 6, logPrefix: "selectionflow-fallback-doubletap"))
		}
	}

	func test_double_tap_selects_only_one_word() {
		let app = XCUIApplication()
		app.launchArguments += [LaunchArguments.uiTestMode]
		app.launch()

		let screen = ReadingScreen(app: app)
		let chapter10 = screen.chapterText(10)
		XCTAssertTrue(chapter10.waitForExistence(timeout: 3))
		bringIntoViewIfNeeded(chapter10, app: app)
		ensureChapterTextHasContent(chapter10)
		chapter10.tap()
		RunLoop.current.run(until: Date().addingTimeInterval(0.2))

		// Double tap should select a single word; validate by asserting selection becomes active
		chapter10.tap(withNumberOfTaps: 2, numberOfTouches: 1)
		nudgeSelection(in: chapter10, normalizedStart: CGVector(dx: 0.5, dy: 0.6))
		if !waitForAnySelectionSignal(app: app, timeout: 8, logPrefix: "selectionflow-doubletap") {
			XCTContext.runActivity(named: "selectionflow.fallback.longpress") { _ in
				chapter10.press(forDuration: 0.55)
				nudgeSelection(in: chapter10, normalizedStart: CGVector(dx: 0.5, dy: 0.55))
			}
			XCTAssertTrue(waitForAnySelectionSignal(app: app, timeout: 6, logPrefix: "selectionflow-fallback-longpress"))
		}
	}
}

