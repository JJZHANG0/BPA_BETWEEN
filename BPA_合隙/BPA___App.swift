import SwiftUI

@main
struct BetweenApp: App {
    @State private var store: ConnectionStore

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-between-ui-testing") {
            let defaults = UserDefaults(suiteName: "between.ui-tests")!
            defaults.removePersistentDomain(forName: "between.ui-tests")
            _store = State(initialValue: ConnectionStore(defaults: defaults))
            return
        }
        #endif
        _store = State(initialValue: ConnectionStore())
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .tint(Palette.text)
                .preferredColorScheme(.dark)
        }
    }
}
