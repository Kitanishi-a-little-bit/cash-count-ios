import Foundation
import Combine

struct MoneyCount: Codable, Equatable {
    static let denominations = [10000, 5000, 2000, 1000, 500, 100, 50, 10, 5, 1]
    var loose: [String: Int] = [:]
    var rolls: [String: Int] = [:]

    static func normalized(_ text: String) -> Int {
        let digits = text.unicodeScalars.lazy.compactMap { scalar -> UInt32? in
            switch scalar.value {
            case 0x30...0x39: return scalar.value - 0x30       // 0–9
            case 0xFF10...0xFF19: return scalar.value - 0xFF10 // ０–９
            default: return nil
            }
        }
        return digits.prefix(6).reduce(0) { $0 * 10 + Int($1) }
    }

    func count(_ denomination: Int, roll: Bool) -> Int {
        let stored = (roll ? rolls : loose)[String(denomination), default: 0]
        return min(max(stored, 0), 999999)
    }

    mutating func set(_ text: String, denomination: Int, roll: Bool) {
        guard Self.denominations.contains(denomination), !roll || denomination <= 500 else { return }
        if roll { rolls[String(denomination)] = Self.normalized(text) }
        else { loose[String(denomination)] = Self.normalized(text) }
    }

    func subtotal(_ denomination: Int) -> Int {
        guard Self.denominations.contains(denomination) else { return 0 }
        let looseCount = count(denomination, roll: false)
        let rollCount = denomination <= 500 ? count(denomination, roll: true) : 0
        return denomination * (looseCount + rollCount * 50)
    }

    var total: Int {
        Self.denominations.reduce(0) { $0 + subtotal($1) }
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
