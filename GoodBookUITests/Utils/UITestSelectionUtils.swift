import XCTest
import CoreGraphics

/// UITest utilities for reliable, debuggable selection interactions.
/// - What: A small set of helpers to (1) wait for selection signals and (2) nudge a selection
///   with a tiny drag to force UIKit to emit selection state quickly.
/// - Why: System selection UIs can be timing-sensitive on cold simulators. Centralizing
///   logging and polling avoids duplicating fragile logic across test files and provides
///   consistent, high-signal debug output when timing is off.
/// - How: Polls for any of several selection indicators and attaches artifacts on timeout.
extension XCTestCase {
    /// All known indicators that a selection is active.
    /// We accept any of these to avoid flakiness across iOS versions and devices.
    /// - Includes: system Copy menu, our action bar, highlight button, and a hidden test flag.
    func selectionSignals(in app: XCUIApplication) -> [XCUIElement] {
        [
            app.menuItems["Copy"],
            app.otherElements["reading.actionbar"],
            app.buttons["reading.action.highlight"],
            app.otherElements["reading.selection.active"],
        ]
    }

    /// Waits until any selection signal appears, logging progress and capturing evidence on timeout.
    /// - Parameters:
    ///   - app: The test application
    ///   - timeout: Max seconds to wait for any selection signal
    ///   - poll: Poll interval in seconds (default 0.25s)
    ///   - logPrefix: A short label included in step logs
    /// - Returns: true if any selection signal appeared within the timeout; otherwise false
    @discardableResult
    func waitForAnySelectionSignal(app: XCUIApplication,
                                   timeout: TimeInterval,
                                   poll: TimeInterval = 0.25,
                                   logPrefix: String = "selection-wait") -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        var iteration = 0
        while Date() < deadline {
            iteration += 1
            if selectionSignals(in: app).contains(where: { $0.exists }) { return true }

            // Inline progress log for easier triage when timeouts happen.
            XCTContext.runActivity(named: "\(logPrefix)-iteration-\(iteration)") { _ in
                let actionBar = app.otherElements["reading.actionbar"].exists
                let highlight = app.buttons["reading.action.highlight"].exists
                let copy = app.menuItems["Copy"].exists
                let flag = app.otherElements["reading.selection.active"].exists
                let snapshot = "signals → copy=\(copy) actionBar=\(actionBar) highlightBtn=\(highlight) flag=\(flag)"
                let att = XCTAttachment(string: snapshot)
                att.lifetime = .keepAlways
                add(att)
            }

            RunLoop.current.run(until: Date().addingTimeInterval(poll))
        }

        // On timeout: attach screenshot and full hierarchy for offline debugging.
        XCTContext.runActivity(named: "\(logPrefix)-timeout-artifacts") { _ in
            let img = XCTAttachment(screenshot: app.screenshot())
            img.lifetime = .keepAlways
            add(img)
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
        }
        return false
    }

    /// Performs a tiny drag inside an element to ensure selection state updates fire.
    /// - Parameters:
    ///   - element: The UI element containing selectable text
    ///   - normalizedStart: Normalized starting point within the element (0..1 each axis)
    ///   - offset: Pixel offset to drag by (defaults to a small horizontal nudge)
    func nudgeSelection(in element: XCUIElement,
                        normalizedStart: CGVector = CGVector(dx: 0.5, dy: 0.5),
                        offset: CGVector = CGVector(dx: 16, dy: 0)) {
        let start = element.coordinate(withNormalizedOffset: normalizedStart)
        let end = start.withOffset(offset)
        start.press(forDuration: 0.01, thenDragTo: end)
    }
}


