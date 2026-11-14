import XCTest
@testable import CashCount

final class CountTests: XCTestCase {
    func testLooseAndRolls() {
        var count = MoneyCount()
        count.set("12", denomination: 100, roll: false)
        count.set("3", denomination: 100, roll: true)
        XCTAssertEqual(count.total, 16200)
    }

    func testAllCoinRollsContainFiftyCoins() {
        for coin in [500, 100, 50, 10, 5, 1] {
            var count = MoneyCount()
            count.set("1", denomination: coin, roll: true)
            XCTAssertEqual(count.total, coin * 50)
        }
    }

    func testBanknotesAndInvalidRolls() {
        var count = MoneyCount()
        for note in [10000, 5000, 2000, 1000] {
            count.set("2", denomination: note, roll: false)
            count.set("1", denomination: note, roll: true)
        }
        XCTAssertEqual(count.total, 36000)
    }

    func testInputNormalization() {
        XCTAssertEqual(MoneyCount.normalized(""), 0)
        XCTAssertEqual(MoneyCount.normalized("１２３"), 123)
        XCTAssertEqual(MoneyCount.normalized("abc"), 0)
        XCTAssertEqual(MoneyCount.normalized("123456789"), 123456)
    }

    func testPersistenceAndSeparateReset() throws {
        let suite = "CashCountTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = CountStore(defaults: defaults)
        store.set("3", account: 0, denomination: 500, roll: true)
        store.set("2", account: 1, denomination: 10000, roll: false)
        let restored = CountStore(defaults: defaults)
        XCTAssertEqual(restored.accounts[0].total, 75000)
        XCTAssertEqual(restored.accounts[1].total, 20000)
        restored.reset(account: 0)
        let reset = CountStore(defaults: defaults)
        XCTAssertEqual(reset.accounts[0].total, 0)
        XCTAssertEqual(reset.accounts[1].total, 20000)
    }
}
