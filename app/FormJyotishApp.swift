import AppKit
import SwiftUI

@main
struct FormJyotishApp: App {
    @StateObject private var store = Store()
    @StateObject private var updater = Updater()

    init() {
        let arguments = CommandLine.arguments
        // a newer build fetched during the last run takes this one's place before anything else happens
        if arguments.contains("--update-helper") { UpdateHelper.run(); exit(0) }
        if !arguments.contains("--report") && !arguments.contains("--match-check") {
            Updater.installStagedAndRelaunch()
            // The last run did not end cleanly (a force quit, a window that stopped answering): before any
            // window opens, ask for a newer build and take it. A build that cannot show itself still heals.
            if UserDefaults.standard.bool(forKey: "running"), case .staged = UpdateHelper.run() { Updater.installStagedAndRelaunch() }
        }
        if arguments.contains("--match-check") { print("match check: \(Match.check()) (23.5 expected)"); exit(Match.check() == 23.5 ? 0 : 1) }
        if let flag = arguments.firstIndex(of: "--report"), arguments.count > flag + 1 {
            Self.writeReport(to: arguments[flag + 1], arguments: arguments)
        }
        // Run from `swift run` there is no bundle, so the process asks to be a regular app with a window.
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    /// `FormJyotish --report out.pdf [--ayanamsa lahiri|truecitra|raman] [--node mean|true]`:
    /// write the first saved chart's report without opening a window, then leave.
    private static func writeReport(to path: String, arguments: [String]) -> Never {
        func option(_ name: String) -> String? {
            arguments.firstIndex(of: "--" + name).flatMap { arguments.count > $0 + 1 ? arguments[$0 + 1] : nil } ?? UserDefaults.standard.string(forKey: name)
        }
        let defaults = UserDefaults.standard
        let engine = Engine(root: URL(fileURLWithPath: defaults.string(forKey: "enginePath") ?? Engine.defaultRoot),
                            kernel: URL(fileURLWithPath: defaults.string(forKey: "kernelPath") ?? Engine.defaultKernel))
        guard let birth = Store().births.first else { print("no saved chart"); exit(1) }
        do {
            let node = option("node") ?? "mean", ayanamsa = option("ayanamsa") ?? "lahiri"
            let chart = try engine.chart(for: birth, node: node, ayanamsa: ayanamsa)
            let transit = try? engine.chart(julianDay: Date().timeIntervalSince1970 / 86400 + 2440587.5, latitude: birth.latitude, longitude: birth.longitude,
                                            node: node, ayanamsa: ayanamsa, zoneHours: birth.zoneHours ?? 0)
            guard Report(birth: birth, chart: chart, transit: transit).write(to: URL(fileURLWithPath: path)) else { print("the report could not be written to \(path)"); exit(1) }
            print("report written to \(path)")
            exit(0)
        } catch {
            print(error.localizedDescription)
            exit(1)
        }
    }

    /// `FormJyotish --probe-tabs`: press each workspace tab with a real mouse event sent to the window, and say
    /// whether the workspace followed. A witness that the tabs answer clicks, not only accessibility presses.
    private func probeTabs() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }) else { print("probe: no window"); exit(1) }
            var held = 0
            let spots = WorkspaceTabs.spots
            func press(_ index: Int) {
                guard index < Store.workspaces.count else { print("probe: \(held) of \(Store.workspaces.count) tabs answered a click"); exit(held == Store.workspaces.count ? 0 : 1) }
                let name = Store.workspaces[index]
                guard let spot = spots[name] else { print("probe: \(name) reported no place"); press(index + 1); return }
                // SwiftUI counts from the top of the room below the title bar; the window counts from its bottom edge
                let point = NSPoint(x: spot.midX, y: window.contentLayoutRect.maxY - spot.midY)
                for kind in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
                    if let event = NSEvent.mouseEvent(with: kind, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1) { window.sendEvent(event) }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    let hit = window.contentView?.hitTest(point)
                    print("probe: \(name) at \(Int(spot.midX)),\(Int(spot.midY)) -> workspace \(store.workspace)\(store.workspace == name ? "" : "  MISSED, hit \(hit.map { String(describing: type(of: $0)) } ?? "nothing")")")
                    if store.workspace == name { held += 1 }
                    press(index + 1)
                }
            }
            press(0)
        }
    }

    var body: some Scene {
        WindowGroup("Form Jyotish") {
            MainView()
                .environmentObject(store)
                .environmentObject(updater)
                .onAppear { updater.check(); if CommandLine.arguments.contains("--probe-tabs") { probeTabs() } }
                .frame(minWidth: 1100, minHeight: 720)
        }
        .commands {
            CommandGroup(after: .appInfo) { Button("Check for Updates…") { updater.check(byHand: true) } }
        }
        Settings { SettingsView() }
    }
}
