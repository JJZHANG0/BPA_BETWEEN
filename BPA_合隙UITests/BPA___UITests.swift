import XCTest

final class BetweenUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func launchDemo() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-between-ui-testing"]
        app.launch()
        let next = app.buttons["onboarding.continue"]
        XCTAssertTrue(next.waitForExistence(timeout: 8))
        for _ in 0..<3 { next.tap() }
        XCTAssertTrue(app.buttons["tab.home"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor
    private func capture(_ name: String, app: XCUIApplication) {
        Thread.sleep(forTimeInterval: 0.5)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testSixSectionsAndEmotionSelection() throws {
        let app = launchDemo()
        capture("01-Home", app: app)
        app.buttons["tab.connect"].tap()
        XCTAssertTrue(app.staticTexts["Two people. One thread."].exists)
        capture("02-Connect", app: app)
        app.buttons["tab.insights"].tap()
        XCTAssertTrue(app.staticTexts["Listen a little closer."].exists)
        capture("03-Insights", app: app)
        app.buttons["tab.touch"].tap()
        XCTAssertTrue(app.otherElements["touch.pad"].exists || app.buttons["touch.pad"].exists)
        capture("04-Touch", app: app)
        app.buttons["tab.emotion"].tap()
        app.buttons["emotion.missing"].tap()
        XCTAssertTrue(app.staticTexts["You’re on my mind, wherever you are."].exists)
        capture("05-Emotion", app: app)
        app.buttons["tab.device"].tap()
        XCTAssertTrue(app.staticTexts["BETWEEN 01"].exists)
        capture("06-Device", app: app)
        app.buttons["tab.home"].tap()
        XCTAssertTrue(app.staticTexts["Missing you"].firstMatch.exists)
    }

    @MainActor
    func testQuickTouchReceiptAndPrivateByDefault() throws {
        let app = launchDemo()
        app.swipeUp()
        app.buttons["quick.thinking"].tap()
        XCTAssertTrue(app.staticTexts["Delivered in demo · no physical bracelet contacted"].waitForExistence(timeout: 5))
        app.buttons["tab.emotion"].tap()
        app.swipeUp()
        app.buttons["Keep private · manage sharing"].tap()
        let permission = app.switches["privacy.Selected emotions"]
        XCTAssertTrue(permission.waitForExistence(timeout: 3))
        XCTAssertEqual(permission.value as? String, "0")
        permission.tap()
        XCTAssertEqual(permission.value as? String, "1")
        capture("07-Privacy", app: app)
    }

    @MainActor
    func testDisconnectAndReconnect() throws {
        let app = launchDemo()
        app.buttons["tab.device"].tap()
        app.swipeUp()
        app.swipeUp()
        app.buttons["device.disconnect"].tap()
        app.buttons["tab.connect"].tap()
        app.swipeUp()
        let reconnect = app.buttons["connect.reconnect"]
        XCTAssertTrue(reconnect.exists)
        reconnect.tap()
        XCTAssertTrue(app.staticTexts["Closer, wherever you are."].waitForExistence(timeout: 6))
    }

    @MainActor
    func testTouchGesturesCreateDistinctMoments() throws {
        let app = launchDemo()
        app.buttons["tab.touch"].tap()
        let pad = app.buttons["touch.pad"]
        let delivered = app.staticTexts["Delivered in demo · no physical bracelet contacted"]
        pad.tap()
        app.buttons["tab.home"].tap()
        XCTAssertTrue(delivered.waitForExistence(timeout: 5))
        app.buttons["tab.touch"].tap()
        pad.doubleTap()
        XCTAssertTrue(delivered.waitForExistence(timeout: 5))
        pad.press(forDuration: 0.9)
        XCTAssertTrue(delivered.waitForExistence(timeout: 5))
        app.swipeUp()
        app.buttons["Your moments ↗"].tap()
        XCTAssertTrue(app.staticTexts["Thinking of you"].exists)
        XCTAssertTrue(app.staticTexts["I’m here"].exists)
        XCTAssertTrue(app.staticTexts["Good night"].exists)
        capture("08-History", app: app)
    }
}
