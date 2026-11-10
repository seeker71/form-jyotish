import AppKit
import SwiftUI

@main
struct FormJyotishApp: App {
    @StateObject private var store = Store()

    init() {
        let arguments = CommandLine.arguments
        if let flag = arguments.firstIndex(of: "--report"), arguments.count > flag + 1 {
            Self.writeReport(to: arguments[flag + 1], arguments: arguments)
        }
        // Run from `swift run` there is no bundle, so the process asks to be a regular app with a window.
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    /// `FormJyotish --report out.pdf [--ayanamsa lahiri|truecitra] [--node mean|true]`:
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
            let chart = try engine.chart(for: birth, node: option("node") ?? "mean", ayanamsa: option("ayanamsa") ?? "lahiri")
            guard Report(birth: birth, chart: chart).write(to: URL(fileURLWithPath: path)) else { print("the report could not be written to \(path)"); exit(1) }
            print("report written to \(path)")
            exit(0)
        } catch {
            print(error.localizedDescription)
            exit(1)
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
