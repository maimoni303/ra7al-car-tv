import XCTest

/// Walks through every screen and the main buttons, saving a screenshot of each step.
final class ScreenTourTests: XCTestCase {
    override func setUp() { continueAfterFailure = true }

    func testTourEnglishLight() { tour(lang: "en", appearance: "light") }
    func testTourArabicDark() { tour(lang: "ar", appearance: "dark") }

    private func tour(lang: String, appearance: String) {
        let app = XCUIApplication()
        app.launchArguments = ["-seedDemo", "-uiLang", lang, "-uiAppearance", appearance]
        app.launch()
        let p = "\(lang)-\(appearance)"

        // Home: categories and channel cards from the seeded source
        XCTAssertTrue(app.buttons["channel-Top Gear (720p)"].firstMatch.waitForExistence(timeout: 15), "Home shows channels")
        shot(app, "\(p)-01-home")

        // Source menu
        app.buttons["sourceMenu"].tap()
        sleep(1)
        shot(app, "\(p)-02-source-menu")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.97)).tap()   // dismiss menu
        sleep(1)

        // Search
        let search = app.textFields.firstMatch
        search.tap()
        search.typeText("Sports\n")
        XCTAssertTrue(app.buttons["channel-Sports One"].waitForExistence(timeout: 5), "Search finds channel")
        shot(app, "\(p)-03-search")
        app.buttons.matching(identifier: lang == "ar" ? "مسح" : "Clear").firstMatch.tap()
        sleep(1)

        // Open player
        app.buttons["channel-Top Gear (720p)"].firstMatch.tap()
        sleep(4)
        shot(app, "\(p)-04-player")
        app.buttons[lang == "ar" ? "إغلاق" : "Close"].firstMatch.tap()
        sleep(1)
        shot(app, "\(p)-05-mini-player")

        // Browser
        tab(app, 1)
        XCTAssertTrue(app.staticTexts[lang == "ar" ? "مواقع شائعة" : "Popular Sites"].waitForExistence(timeout: 5))
        shot(app, "\(p)-06-browser")

        // Cast
        tab(app, 2)
        XCTAssertTrue(app.staticTexts[lang == "ar" ? "CarPlay غير متصل" : "CarPlay not connected"].waitForExistence(timeout: 5))
        shot(app, "\(p)-07-cast")

        // Library + favorites segment
        tab(app, 3)
        XCTAssertTrue(app.staticTexts[lang == "ar" ? "لا توجد فيديوهات مستوردة" : "No videos imported"].waitForExistence(timeout: 5))
        shot(app, "\(p)-08-library")
        app.segmentedControls.buttons.element(boundBy: 1).tap()
        sleep(1)
        shot(app, "\(p)-09-library-favorites")

        // Settings
        tab(app, 4)
        XCTAssertTrue(app.staticTexts[lang == "ar" ? "إدارة المصادر" : "Manage Sources"].waitForExistence(timeout: 5))
        shot(app, "\(p)-10-settings")

        // Manage sources → detail
        app.staticTexts[lang == "ar" ? "إدارة المصادر" : "Manage Sources"].tap()
        XCTAssertTrue(app.staticTexts["demo"].waitForExistence(timeout: 5))
        shot(app, "\(p)-11-manage-sources")
        app.staticTexts["demo"].tap()
        sleep(1)
        shot(app, "\(p)-12-source-detail")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        sleep(1)

        // Add a Source → Find IPTV Links
        app.navigationBars.buttons.element(boundBy: app.navigationBars.buttons.count - 1).tap()
        XCTAssertTrue(app.staticTexts[lang == "ar" ? "إضافة مصدر" : "Add a Source"].waitForExistence(timeout: 5))
        sleep(1)
        shot(app, "\(p)-13-add-source")
        app.staticTexts[lang == "ar" ? "البحث عن روابط IPTV" : "Find IPTV Links"].tap()
        sleep(2)
        shot(app, "\(p)-14-find-links")
        app.swipeUp()
        shot(app, "\(p)-15-find-links-scrolled")
    }

    private func tab(_ app: XCUIApplication, _ index: Int) {
        app.buttons["tab-\(index)"].tap()
        sleep(1)
    }

    private func dismissKeyboard(_ app: XCUIApplication) {
        if app.keyboards.count > 0 { app.keyboards.buttons.element(boundBy: app.keyboards.buttons.count - 1).tap() }
        sleep(1)
    }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let s = app.screenshot()
        let a = XCTAttachment(screenshot: s)
        a.name = name
        a.lifetime = .keepAlways
        add(a)
        if let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            try? s.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
        }
    }
}
