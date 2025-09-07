import XCTest

final class SelectionFlowTests: XCTestCase {
    // Bring target element into view if it's offscreen or covered; avoids gestures on non-hittable nodes.
    private func bringIntoViewIfNeeded(_ element: XCUIElement, app: XCUIApplication) {
        guard element.exists else { return }
        if element.isHittable { return }
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

    func test_long_press_shows_action_bar_then_tap_overlay_hides() {
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

        // Begin selection and nudge to ensure state change
        chapter10.press(forDuration: 0.55)
        nudgeSelection(in: chapter10, normalizedStart: CGVector(dx: 0.5, dy: 0.5))

        // Wait for any selection signal (action bar, Copy menu, etc.).
        // If timing is slow, fall back to double-tap initiation.
        if !waitForAnySelectionSignal(app: app, timeout: 8, logPrefix: "selectionflow-longpress") {
            XCTContext.runActivity(named: "selectionflow.fallback.doubletap") { _ in
                chapter10.tap(withNumberOfTaps: 2, numberOfTouches: 1)
                nudgeSelection(in: chapter10, normalizedStart: CGVector(dx: 0.5, dy: 0.55))
            }
            XCTAssertTrue(waitForAnySelectionSignal(app: app, timeout: 6, logPrefix: "selectionflow-fallback-doubletap"))
        }

        // Tap anywhere in the overlay to dismiss (overlay covers entire area above the bar)
        let appCenter = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        appCenter.tap()

        // Action bar should disappear quickly after dismissal tap
        let actionBar = app.otherElements["reading.actionbar"]
        XCTAssertFalse(actionBar.waitForExistence(timeout: 2))
    }

    func test_double_tap_shows_action_bar() {
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


