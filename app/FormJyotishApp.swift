import AppKit
import SwiftUI

@main
struct FormJyotishApp: App {
    @StateObject private var store = Store()

    init() {
        // Run from `swift run` there is no bundle, so the process asks to be a regular app with a window.
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    var body: some Scene {
        WindowGroup("Form Jyotish") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 980, minHeight: 720)
        }
        Settings { SettingsView() }
    }
}
