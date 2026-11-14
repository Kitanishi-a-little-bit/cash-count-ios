import Foundation
import Combine

struct MoneyCount: Codable, Equatable {
    static let denominations = [10000, 5000, 2000, 1000, 500, 100, 50, 10, 5, 1]
    var loose: [String: Int] = [:]
    var rolls: [String: Int] = [:]

    static func normalized(_ text: String) -> Int {
        let digits = text.compactMap { $0.wholeNumberValue }.prefix(6)
        return digits.reduce(0) { $0 * 10 + $1 }
    }

    func count(_ denomination: Int, roll: Bool) -> Int {
        (roll ? rolls : loose)[String(denomination), default: 0]
    }

    mutating func set(_ text: String, denomination: Int, roll: Bool) {
        guard Self.denominations.contains(denomination), !roll || denomination <= 500 else { return }
        if roll { rolls[String(denomination)] = Self.normalized(text) }
        else { loose[String(denomination)] = Self.normalized(text) }
    }

    var total: Int {
        Self.denominations.reduce(0) { sum, denomination in
            let looseCount = min(max(count(denomination, roll: false), 0), 999999)
            let rollCount = denomination <= 500 ? min(max(count(denomination, roll: true), 0), 999999) : 0
            return sum + denomination * (looseCount + rollCount * 50)
        }
    }
}

final class CountStore: ObservableObject {
    @Published private(set) var accounts: [MoneyCount]
    private let defaults: UserDefaults
    private let key = "cash-count.accounts.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let saved = try? JSONDecoder().decode([MoneyCount].self, from: data), saved.count == 2 {
            accounts = saved
        } else { accounts = [MoneyCount(), MoneyCount()] }
    }

    func set(_ text: String, account: Int, denomination: Int, roll: Bool) {
        accounts[account].set(text, denomination: denomination, roll: roll)
        save()
    }

    func reset(account: Int) {
        accounts[account] = MoneyCount()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(accounts) { defaults.set(data, forKey: key) }
    }
}
