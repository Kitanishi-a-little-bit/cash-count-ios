import SwiftUI

@main
struct CashCountApp: App {
    #if DEBUG
    init() {
        if let sample = ProcessInfo.processInfo.environment["CASHCOUNT_TEST_PASTEBOARD"] {
            UIPasteboard.general.string = sample
        }
    }
    #endif

    var body: some Scene {
        WindowGroup { NavigationStack { ContentView() } }
    }
}
