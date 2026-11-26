import XCTest
@testable import CashCount

final class LocalizationTests: XCTestCase {
    func testAppBundleSupportsJapanese() {
        let app = Bundle(for: CountStore.self)
        XCTAssertEqual(app.developmentLocalization, "ja")
        XCTAssertEqual(Set(app.localizations).subtracting(["Base"]), ["ja"])
    }
}
