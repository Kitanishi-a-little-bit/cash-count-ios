import XCTest
import UIKit

final class CountPasteTests: XCTestCase {
    @MainActor
    func testPastingCircledNumbersIntoOneYenField() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let field = app.textFields["1円 枚数"]
        if !field.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(field.isHittable)
        field.tap()
        field.typeText("7")
        XCTAssertTrue(app.staticTexts["1円の小計 7円"].exists)
        UIPasteboard.general.string = "⑫⑫⑫⑫⑫⑫"
        field.doubleTap()
        let paste = app.buttons["Paste"].firstMatch
        XCTAssertTrue(paste.waitForExistence(timeout: 5))
        paste.tap()

        let allowPaste = app.alerts.buttons["Allow Paste"]
        if allowPaste.waitForExistence(timeout: 2) { allowPaste.tap() }

        // An empty accessibility value can also be reported as the placeholder.
        let empty = NSPredicate(format: "value == nil OR value == '' OR value == '0'")
        expectation(for: empty, evaluatedWith: field)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.staticTexts["1円の小計 0円"].exists)
        XCTAssertTrue(app.keyboards.firstMatch.exists)
    }
}
