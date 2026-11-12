import AppKit
import SwiftUI

@main
struct FormJyotishApp: App {
    @StateObject private var store = Store()
    @StateObject private var updater = Updater()

    init() {
        let arguments = CommandLine.arguments
        // a newer build fetched during the last run takes this one's place before anything else happens
        if arguments.contains("--save-public") { print("public charts added: \(PublicCharts.saveAll())"); exit(0) }
        if arguments.contains("--update-helper") { UpdateHelper.run(); exit(0) }
        // `FormJyotish --entry-check`: dates and times as people type them, each read to the one form the app writes
        if arguments.contains("--entry-check") {
            let dates: [(String, String?)] = [("1971-03-11", "1971-Mar-11"), ("1971-3-11", "1971-Mar-11"), ("11 Mar 1971", "1971-Mar-11"), ("March 11, 1971", "1971-Mar-11"), ("11.3.1971", "1971-Mar-11"),
                                             ("13/3/1971", "1971-Mar-13"), ("3/13/1971", "1971-Mar-13"), ("1971/03/11", "1971-Mar-11"), ("1971-Mar-11", "1971-Mar-11"), ("1971-dec-01", "1971-Dec-01"), ("31 Feb 1971", nil), ("11 Mar 71", nil), ("soon", nil)]
            let times: [(String, String?)] = [("02:50", "02:50:00"), ("2:50", "02:50:00"), ("2:50 am", "02:50:00"), ("2.50pm", "14:50:00"), ("0250", "02:50:00"), ("14", "14:00:00"), ("12 am", "00:00:00"),
                                             ("12:30 pm", "12:30:00"), ("09:15:30", "09:15:30"), ("25:00", nil), ("13 pm", nil), ("noonish", nil)]
            var held = 0
            for (typed, want) in dates { let got = Birth(date: typed).writtenDate; if got == want { held += 1 } else { print("date \(typed): read \(got ?? "nothing"), expected \(want ?? "nothing")") } }
            for (typed, want) in times { let got = Birth(time: typed).writtenTime; if got == want { held += 1 } else { print("time \(typed): read \(got ?? "nothing"), expected \(want ?? "nothing")") } }
            print("entry check: \(held) of \(dates.count + times.count) read as expected")
            exit(held == dates.count + times.count ? 0 : 1)
        }
        Updater.waitForPredecessor(arguments)
        if !arguments.contains("--report") && !arguments.contains("--match-check") {
            Updater.installStagedAndRelaunch()
            // The last run did not end cleanly (a force quit, a window that stopped answering): before any
            // window opens, ask for a newer build and take it. A build that cannot show itself still heals.
            if UserDefaults.standard.bool(forKey: "running"), case .staged = UpdateHelper.runApart(seconds: 200) { Updater.installStagedAndRelaunch() }
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

    /// `FormJyotish --report out.pdf [--public key] [--ayanamsa lahiri|truecitra|raman] [--node mean|true]`:
    /// write the report of a public chart, or of the first saved chart, without opening a window, then leave.
    private static func writeReport(to path: String, arguments: [String]) -> Never {
        func option(_ name: String) -> String? {
            arguments.firstIndex(of: "--" + name).flatMap { arguments.count > $0 + 1 ? arguments[$0 + 1] : nil } ?? UserDefaults.standard.string(forKey: name)
        }
        let defaults = UserDefaults.standard
        let engine = Engine(root: URL(fileURLWithPath: defaults.string(forKey: "enginePath") ?? Engine.defaultRoot),
                            kernel: URL(fileURLWithPath: defaults.string(forKey: "kernelPath") ?? Engine.defaultKernel))
        // with --public <key> the report is of that public chart, and no saved chart is read
        let known = arguments.firstIndex(of: "--public").flatMap { arguments.count > $0 + 1 ? arguments[$0 + 1] : nil }.flatMap { key in PublicCharts.all.first { $0.key == key }?.birth }
        guard let birth = known ?? Store().births.first else { print("no saved chart"); exit(1) }
        do {
            let node = birth.node ?? option("node") ?? "mean", ayanamsa = birth.ayanamsa ?? option("ayanamsa") ?? "lahiri"
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
        // with --probe-banner the update banner stands above the tabs, as it does after an update is fetched
        if CommandLine.arguments.contains("--probe-banner") { DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { updater.state = .ready(999) } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }) else { print("probe: no window"); exit(1) }
            var held = 0
            func press(_ index: Int) {
                guard index < Store.workspaces.count else { print("probe: \(held) of \(Store.workspaces.count) tabs answered a click"); exit(held == Store.workspaces.count ? 0 : 1) }
                let name = Store.workspaces[index]
                guard let spot = WorkspaceTabs.spots[name] else { print("probe: \(name) reported no place"); press(index + 1); return }
                // SwiftUI counts from the window's top edge once the window has settled; the window counts from its bottom
                let point = NSPoint(x: spot.midX, y: window.frame.height - spot.midY)
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

    /// `FormJyotish --snapshot out.png`: after the window has settled, write what it shows as a picture and
    /// leave. With `--public`, `--workspace`, `--look-up` it shows a new view without anyone clicking.
    private func snapshot(to path: String) {
        let arguments = CommandLine.arguments
        func value(_ name: String) -> String? { arguments.firstIndex(of: name).flatMap { arguments.count > $0 + 1 ? arguments[$0 + 1] : nil } }
        // --size 1600x900 sets the window's size; --focus Ju rests the pointer on a graha; --glow Ju,Mo lights several;
        // --tour 2 opens that step of the walk-through; --about yogas opens a card's explanation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if let size = value("--size")?.split(separator: "x").compactMap({ Double($0) }), size.count == 2, let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }) {
                window.setFrame(NSRect(x: window.frame.minX, y: window.frame.minY, width: size[0], height: size[1]), display: true)
            }
            if let level = value("--guidance") { store.guidance = level }
            if let step = value("--tour").flatMap({ Int($0) }) { store.tour(to: step - 1) }
            if value("--about") != nil { store.explanation = Help.about(card: value("--about") ?? "") }
            if let code = value("--focus") { store.hover = .graha(code) }
            if let codes = value("--glow") { store.glow = codes.split(separator: ",").map(String.init) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }), let view = window.contentView, let shot = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { print("snapshot: no window"); exit(1) }
            view.cacheDisplay(in: view.bounds, to: shot)
            guard let data = shot.representation(using: .png, properties: [:]), (try? data.write(to: URL(fileURLWithPath: path))) != nil else { print("snapshot: could not write \(path)"); exit(1) }
            print("snapshot written to \(path)")
            exit(0)
        }
    }

    /// `FormJyotish --probe-tour`: start the walk-through, press Next, Next, Back and End with real mouse events
    /// sent to the window, and say whether the step and the workspace followed each press.
    private func probeTour() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { store.tour(to: 0) }
        let presses: [(button: String, step: Int?)] = [("next", 1), ("next", 2), ("next", 3), ("next", 4), ("next", 5), ("next", 6), ("back", 5), ("end", nil)]
        var held = 0
        func press(_ index: Int) {
            guard index < presses.count else { print("probe: \(held) of \(presses.count) walk-through presses answered"); exit(held == presses.count ? 0 : 1) }
            let (button, step) = presses[index]
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }), let spot = TourPanel.spots[button] else { print("probe: \(button) reported no place"); exit(1) }
            let point = NSPoint(x: spot.midX, y: window.frame.height - spot.midY)
            func event(_ kind: NSEvent.EventType) -> NSEvent? {
                NSEvent.mouseEvent(with: kind, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
            }
            // a button follows the mouse in its own loop until the release arrives, so the release waits in the
            // queue before the press is sent
            if let up = event(.leftMouseUp), let down = event(.leftMouseDown) { NSApp.postEvent(up, atStart: false); window.sendEvent(down) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                let ok = store.tourAt == step && (step == nil || store.workspace == store.tourSteps[step!].workspace)
                print("probe: \(button) -> step \(store.tourAt.map { String($0 + 1) } ?? "none"), workspace \(store.workspace), picked \(store.pick.map { String(describing: $0) } ?? "nothing")\(ok ? "" : "  MISSED")")
                if ok { held += 1 }
                press(index + 1)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) { press(0) }
    }

    /// `FormJyotish --probe-table`: on Overview, click the Jupiter row and then the Nakshatra heading with real
    /// mouse events, and say whether the row was picked and the heading explained.
    private func probeTable() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { store.workspace = "Overview" }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { store.showCard = "grahas" }
        // a heading that carries an explanation and stands inside the window now
        func heading() -> String? {
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }) else { return nil }
            return PickRow.spots.filter { $0.key.hasPrefix("heading:") && $0.value.midY > 120 && $0.value.midY < window.frame.height - 120 && $0.value.midX > 300 }.keys.sorted().first
        }
        func click(_ key: String) -> Bool {
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }), let spot = PickRow.spots[key] else { print("probe: \(key) reported no place"); return false }
            let point = NSPoint(x: spot.midX, y: window.frame.height - spot.midY)
            print("probe: \(key) at \(Int(spot.midX)),\(Int(spot.midY)) of window \(Int(window.frame.width))x\(Int(window.frame.height)), scale \(store.textScale), hit \(window.contentView?.hitTest(point).map { String(describing: type(of: $0)) } ?? "nothing")")
            func event(_ kind: NSEvent.EventType) -> NSEvent? {
                NSEvent.mouseEvent(with: kind, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
            }
            // inside a scrolling desk a tap is told from a drag by its release, which follows a moment later
            if let down = event(.leftMouseDown) { window.sendEvent(down) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { if let up = event(.leftMouseUp) { window.sendEvent(up) } }
            return true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            guard click("row:Ju") else { exit(1) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                let picked = store.pick?.graha == "Ju"
                print("probe: clicked the Jupiter row at \(PickRow.spots["row:Ju"].map { "\(Int($0.midX)),\(Int($0.midY))" } ?? "?") -> picked \(store.pick.map { String(describing: $0) } ?? "nothing")\(picked ? "" : "  MISSED")")
                guard let key = heading(), click(key) else { print("probe: no heading with an explanation stands in the window; places \(PickRow.spots.mapValues { "\(Int($0.midX)),\(Int($0.midY))" })"); exit(1) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    let explained = store.explanation != nil
                    print("probe: clicked the \(key.dropFirst(8)) heading -> explained \(store.explanation?.title ?? "nothing")\(explained ? "" : "  MISSED")")
                    exit(picked && explained ? 0 : 1)
                }
            }
        }
    }

    /// `FormJyotish --probe-palette`: open the palette on "shad", click "What is Shadbala?" with a real mouse
    /// event, and say whether the explanation came up.
    private func probePalette() {
        store.paletteSeed = "shad"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { store.paletteShown = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }), let spot = Palette.spots["what-Shadbala"] else { print("probe: the palette lists no What is Shadbala?"); exit(1) }
            let point = NSPoint(x: spot.midX, y: window.frame.height - spot.midY)
            for kind in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
                if let event = NSEvent.mouseEvent(with: kind, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1) { window.sendEvent(event) }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                print("probe: clicked What is Shadbala? at \(Int(spot.midX)),\(Int(spot.midY)) -> explained \(store.lookedUp ?? "nothing"), palette \(store.paletteShown ? "still open" : "closed")")
                exit(store.explanation?.title == "Shadbala" ? 0 : 1)
            }
        }
    }

    var body: some Scene {
        WindowGroup("Form Jyotish") {
            MainView()
                .environmentObject(store)
                .environmentObject(updater)
                .onAppear { updater.check(); if let i = CommandLine.arguments.firstIndex(of: "--public"), CommandLine.arguments.count > i + 1 { store.ephemeral = true; store.addPublic(CommandLine.arguments[i + 1]) }; if let i = CommandLine.arguments.firstIndex(of: "--show-card"), CommandLine.arguments.count > i + 1 { let card = CommandLine.arguments[i + 1]; DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { store.showCard = card } }; if let i = CommandLine.arguments.firstIndex(of: "--look-up"), CommandLine.arguments.count > i + 1 { store.lookedUp = CommandLine.arguments[i + 1] }; if let i = CommandLine.arguments.firstIndex(of: "--workspace"), CommandLine.arguments.count > i + 1, Store.workspaces.contains(CommandLine.arguments[i + 1]) { store.workspace = CommandLine.arguments[i + 1] }; if let i = CommandLine.arguments.firstIndex(of: "--snapshot"), CommandLine.arguments.count > i + 1 { snapshot(to: CommandLine.arguments[i + 1]) }; if CommandLine.arguments.contains("--probe-tabs") { probeTabs() }; if CommandLine.arguments.contains("--probe-palette") { probePalette() }; if CommandLine.arguments.contains("--probe-tour") { probeTour() }; if CommandLine.arguments.contains("--probe-table") { probeTable() } }
                .frame(minWidth: 1100, minHeight: 720)
        }
        .commands {
            CommandGroup(after: .appInfo) { Button("Check for Updates…") { updater.check(byHand: true) } }
        }
        Settings { SettingsView() }
    }
}
