import CoreLocation
import Foundation
import SwiftUI

/// What the person has pointed at. Every card and the inspector read the same pick.
enum Pick: Equatable {
    case graha(String)
    case sign(Int)
    /// a Vimshottari period by its lords from mahadasha down, with its span
    case period(lords: [String], start: Double, end: Double)

    /// the graha this pick speaks of, if any
    var graha: String? {
        switch self {
        case .graha(let code): return code
        case .period(let lords, _, _): return lords.last
        case .sign: return nil
        }
    }
}

/// Runs engine readings off the main thread, one at a time; while one runs only the newest request waits.
@MainActor
final class Feed {
    private let queue = DispatchQueue(label: "form-jyotish.engine", qos: .userInitiated)
    private var busy = false
    private var waiting: (work: () -> Result<Chart, Error>, done: (Result<Chart, Error>) -> Void)?

    func submit(_ work: @escaping () -> Result<Chart, Error>, done: @escaping (Result<Chart, Error>) -> Void) {
        if busy { waiting = (work, done); return }
        busy = true
        queue.async {
            let result = work()
            DispatchQueue.main.async {
                done(result)
                self.busy = false
                if let next = self.waiting { self.waiting = nil; self.submit(next.work, done: next.done) }
            }
        }
    }
}

/// The saved births, the chart on the desk, the moment under view, and what is picked.
@MainActor
final class Store: ObservableObject {
    static let workspaces = ["Guide", "Overview", "Vargas", "Dasha", "Strength", "Yogas", "Jaimini", "KP", "Transits", "Annual", "Match"]
    /// Cards that belong together stand next to each other: the workspace lays neighbours side by side
    /// where the window has room, so a chart sits beside the table that reads it.
    static let standardLayout: [String: [String]] = [
        "Guide": ["guide", "chart:0", "reading", "houses", "glossary", "sources"],
        "Jaimini": ["chart:0", "karakas", "arudhas", "chara-dasha"],
        "Match": ["match", "chart:0", "moon"],
        "Annual": ["annual", "chart:0", "dasha-context"],
        "Overview": ["chart:0", "chart:5", "moon", "grahas", "edges", "birth", "timeline"],
        "Vargas": (0..<16).map { "chart:\($0)" },
        "Dasha": ["chart:0", "dasha-context", "timeline", "dashas", "other-dashas", "events"],
        "Strength": ["chart:0", "ashtakavarga", "shadbala", "avasthas"],
        "Yogas": ["chart:0", "yogas", "aspects"],
        "KP": ["kp-grahas", "kp-cusps", "kp-houses", "kp-planets"],
        "Transits": ["chart:0", "transits", "transit-dates", "timeline"],
    ]
    /// the desk's arrangement was redrawn at this number; an earlier saved arrangement gives way to it once
    static let layoutVersion = 2

    @Published var births: [Birth] = [] { didSet { save(); if births.first(where: { $0.id == current }) != oldValue.first(where: { $0.id == current }) { readNatal() } } }
    @Published var current: Birth.ID? { didSet { if current != oldValue { moment = nil; rectify = 0; pick = nil; chart = nil; readNatal() } } }
    /// the birth chart, with any unapplied rectification
    @Published var chart: Chart?
    /// the sky at `moment`; nil while the desk stands at the birth
    @Published var sky: Chart?
    /// the moment under view; nil means the birth itself
    @Published var moment: Date? { didSet { readSky() } }
    /// seconds added to the birth time while rectifying, not yet written to the birth
    @Published var rectify: Double = 0 { didSet { if rectify != oldValue { readNatal() } } }
    @Published var rectifying = false
    @Published var pick: Pick?
    @Published var hover: Pick?
    /// the step of the walk-through that is open; nil when it is closed
    @Published var tourAt: Int? = nil
    /// guidance for a reader who knows the tradition: each card states its method in place of the plain words
    @Published var familiar: Bool = UserDefaults.standard.bool(forKey: "familiar") { didSet { defaults.set(familiar, forKey: "familiar") } }
    /// the guidance level as one choice: learning, familiar, off
    var guidance: String {
        get { !showHelp ? "off" : familiar ? "familiar" : "learning" }
        set { if showHelp != (newValue != "off") { showHelp = newValue != "off" }; if newValue != "off", familiar != (newValue == "familiar") { familiar = newValue == "familiar" } }
    }
    /// grahas lit together on every card while the pointer rests on something they form: a yoga, a period
    @Published var glow: [String] = []
    /// whether the inspector shows what the pointer rests on, or only what was clicked
    @Published var followPointer: Bool = UserDefaults.standard.object(forKey: "followPointer") as? Bool ?? true { didSet { defaults.set(followPointer, forKey: "followPointer") } }
    /// what the inspector and the charts speak of: the thing under the pointer, else the thing clicked
    var focus: Pick? { followPointer ? (hover ?? pick) : pick }
    @Published var problem: String?
    /// the type-to-do-anything panel is open
    @Published var paletteShown = false
    /// what is typed into the glossary's search
    @Published var glossary = ""
    /// charts drawn large, a row to themselves: the birth chart is, until told otherwise
    @Published var enlarged: Set<String> = {
        // the Rasi chart is at its largest by default; that default is laid over an earlier saved choice once
        let defaults = UserDefaults.standard
        var saved = Set(defaults.stringArray(forKey: "enlarged") ?? ["chart:0"])
        if !defaults.bool(forKey: "rasiLargeByDefault") { saved.insert("chart:0"); defaults.set(true, forKey: "rasiLargeByDefault"); defaults.set(Array(saved), forKey: "enlarged") }
        return saved
    }() { didSet { defaults.set(Array(enlarged), forKey: "enlarged") } }
    func toggleEnlarged(_ id: String) { if enlarged.contains(id) { enlarged.remove(id) } else { enlarged.insert(id) } }
    /// what the palette opens with typed in: used by the palette's click witness
    var paletteSeed = ""
    /// a word asked about from the command palette: explained in the inspector, wherever the desk stands
    @Published var lookedUp: String? = nil { didSet { if let lookedUp { explanation = Lore.explain(term: lookedUp, chart: chart) } } }
    /// what a clicked fact means: shown on a card over the desk until closed
    @Published var explanation: Explanation? = nil { didSet { if explanation == nil, lookedUp != nil { lookedUp = nil } } }
    /// a card the workspace is asked to bring into view
    @Published var showCard: String? = nil
    @Published var workspace: String { didSet { defaults.set(workspace, forKey: "workspace") } }
    @Published var layout: [String: [String]] { didSet { if !Store.trial { defaults.set(try? JSONEncoder().encode(layout), forKey: "layout") } } }
    /// a run that only pictures the window (`--snapshot`): it shows the standard desk and writes nothing of the desk's arrangement
    static let trial = CommandLine.arguments.contains("--snapshot")
    /// how large the desk is drawn: 1 is the system's own text size
    @Published var textScale: Double = UserDefaults.standard.object(forKey: "textScale") as? Double ?? 1.15 { didSet { defaults.set(textScale, forKey: "textScale") } }
    static let textScales: [(name: String, scale: Double)] = [("Small", 0.9), ("Standard", 1.0), ("Large", 1.15), ("Larger", 1.3), ("Largest", 1.5)]
    /// The node and the ayanamsa belong to the chart on the desk: choosing one writes it into that chart, and
    /// each chart comes up with its own. A chart that has never been given one follows the app's default.
    @Published var node: String { didSet { if node != oldValue { keep(\.node, node, key: "node"); readNatal(); readSky() } } }
    @Published var ayanamsa: String { didSet { if ayanamsa != oldValue { keep(\.ayanamsa, ayanamsa, key: "ayanamsa"); readNatal(); readSky() } } }
    private var applying = false
    private func keep(_ path: WritableKeyPath<Birth, String?>, _ value: String, key: String) {
        guard !applying else { return }
        if let index { births[index][keyPath: path] = value } else { defaults.set(value, forKey: key) }
    }
    /// bring the chart's own settings to the desk
    private func applySettings() {
        guard let birth else { return }
        applying = true
        let wantNode = birth.node ?? defaults.string(forKey: "node") ?? "mean", wantAyanamsa = birth.ayanamsa ?? defaults.string(forKey: "ayanamsa") ?? "lahiri"
        if node != wantNode { node = wantNode }
        if ayanamsa != wantAyanamsa { ayanamsa = wantAyanamsa }
        applying = false
    }
    @Published var style: ChartStyle { didSet { defaults.set(style.rawValue, forKey: "style") } }
    /// explanations shown in place on every card and in the inspector; on until the person turns it off
    @Published var showHelp: Bool { didSet { defaults.set(showHelp, forKey: "showHelp") } }

    private let defaults = UserDefaults.standard
    private let file: URL
    private let natalFeed = Feed(), skyFeed = Feed()

    init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("FormJyotish")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        file = folder.appendingPathComponent("charts.json")
        // A run that did not end cleanly (a force quit, a window that stopped answering) opens on the Guide,
        // so no page can hold the app closed to its own update.
        let endedCleanly = !defaults.bool(forKey: "running")
        workspace = endedCleanly ? defaults.string(forKey: "workspace").flatMap { Store.workspaces.contains($0) ? $0 : nil } ?? "Guide" : "Guide"
        defaults.set(true, forKey: "running")
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { _ in UserDefaults.standard.set(false, forKey: "running") }
        if !Store.trial, defaults.integer(forKey: "layoutVersion") < Store.layoutVersion { defaults.removeObject(forKey: "layout"); defaults.removeObject(forKey: "offeredCards"); defaults.set(Store.layoutVersion, forKey: "layoutVersion") }
        var saved = (Store.trial ? nil : defaults.data(forKey: "layout")).flatMap { try? JSONDecoder().decode([String: [String]].self, from: $0) } ?? Store.standardLayout
        // A saved layout gains each card that has since joined a workspace's standard set, once: the cards
        // already offered are remembered, so a card the person removed stays removed.
        let standard = Store.standardLayout.flatMap { name, cards in cards.map { name + "/" + $0 } }
        let offered = Set(defaults.stringArray(forKey: "offeredCards") ?? (defaults.data(forKey: "layout") == nil ? standard : []))
        for (name, cards) in Store.standardLayout {
            for (place, card) in cards.enumerated() where !offered.contains(name + "/" + card) && !(saved[name] ?? cards).contains(card) {
                var list = saved[name] ?? cards
                let before = cards[..<place].last { list.contains($0) }
                list.insert(card, at: before.flatMap { list.firstIndex(of: $0) }.map { $0 + 1 } ?? 0)
                saved[name] = list
            }
        }
        if !Store.trial { defaults.set(standard, forKey: "offeredCards") }
        if !Store.trial, defaults.data(forKey: "layout") != nil { defaults.set(try? JSONEncoder().encode(saved), forKey: "layout") }
        layout = saved
        node = defaults.string(forKey: "node") ?? "mean"
        ayanamsa = defaults.string(forKey: "ayanamsa") ?? "lahiri"
        style = ChartStyle(rawValue: defaults.string(forKey: "style") ?? "") ?? .south
        showHelp = defaults.object(forKey: "showHelp") as? Bool ?? true
        if let data = try? Data(contentsOf: file), let saved = try? JSONDecoder().decode([Birth].self, from: data) {
            births = saved
        } else {
            // a first run opens on one example, so the window shows a chart rather than an empty list
            births = [Birth(name: "Example: New Delhi", date: "2000-01-01", time: "17:30:00", zone: "Asia/Kolkata", place: "New Delhi, India", latitude: 28.6139, longitude: 77.209)]
        }
        current = births.first?.id
    }

    private func save() {
        guard !ephemeral, let data = try? JSONEncoder().encode(births) else { return }
        try? data.write(to: file, options: .atomic)
    }

    var engine: Engine {
        Engine(root: URL(fileURLWithPath: defaults.string(forKey: "enginePath") ?? Engine.defaultRoot),
               kernel: URL(fileURLWithPath: defaults.string(forKey: "kernelPath") ?? Engine.defaultKernel))
    }
    var index: Int? { births.firstIndex { $0.id == current } }
    var birth: Birth? { index.map { births[$0] } }
    var zone: TimeZone { birth?.timeZone ?? .current }
    /// the Julian day the desk stands at: the moment under view, or the birth
    var viewDay: Double? { moment.map { $0.timeIntervalSince1970 / 86400 + 2440587.5 } ?? chart?.jd }
    var atBirth: Bool { moment == nil }

    // MARK: births

    func add() {
        let birth = Birth()
        births.append(birth)
        current = birth.id
    }

    /// A chart to explore with: an arbitrary moment and place, not a real person's birth.
    func addSample(_ name: String, date: String, time: String, zone: String, place: String, latitude: Double, longitude: Double) {
        let birth = Birth(name: "Sample: " + name, date: date, time: time, zone: zone, place: place, latitude: latitude, longitude: longitude)
        births.append(birth)
        current = birth.id
    }

    /// Add a chart of a public figure as a published reading gives it, with the dated events of the life.
    /// It carries its own ayanamsa, so a reading's dates can be followed without changing other charts.
    func addPublic(_ key: String) {
        guard let entry = PublicCharts.all.first(where: { $0.key == key }) else { return }
        var birth = entry.birth
        birth.id = UUID()
        births.append(birth)
        current = birth.id
    }
    /// while set, nothing is written to the saved charts: used when a public chart is opened only to be looked at
    var ephemeral = false

    func remove(_ id: Birth.ID) {
        births.removeAll { $0.id == id }
        if current == id { current = births.first?.id }
    }

    // MARK: readings

    func readNatal() {
        applySettings()
        guard let birth else { chart = nil; return }
        guard let jd = birth.julianDay, let zoneHours = birth.zoneHours else {
            problem = "The date reads as YYYY-MM-DD, the time as HH:MM:SS, and the zone as a name like Asia/Kolkata."
            return
        }
        let engine = engine, node = node, ayanamsa = ayanamsa, day = jd + rectify / 86400, id = birth.id
        natalFeed.submit({ Result { try engine.chart(julianDay: day, latitude: birth.latitude, longitude: birth.longitude, node: node, ayanamsa: ayanamsa, zoneHours: zoneHours) } }) { result in
            guard id == self.current else { return }
            switch result {
            case .success(let chart): self.chart = chart; self.problem = nil
            case .failure(let error): self.problem = error.localizedDescription
            }
        }
    }

    func readSky() {
        guard let moment, let birth else { sky = nil; return }
        let engine = engine, node = node, ayanamsa = ayanamsa
        let zoneHours = Double(zone.secondsFromGMT(for: moment)) / 3600, day = moment.timeIntervalSince1970 / 86400 + 2440587.5
        skyFeed.submit({ Result { try engine.chart(julianDay: day, latitude: birth.latitude, longitude: birth.longitude, node: node, ayanamsa: ayanamsa, zoneHours: zoneHours) } }) { result in
            guard self.moment != nil else { return }
            switch result {
            case .success(let chart): self.sky = chart; self.problem = nil
            case .failure(let error): self.problem = error.localizedDescription
            }
        }
    }

    // MARK: time

    func go(to julianDay: Double) { moment = Names.date(julianDay: julianDay) }
    func goNow() { rectifying = false; moment = Date() }
    func goBirth() { moment = nil }

    /// Move the moment under view, or, while rectifying, the birth time itself.
    func step(seconds: Double) {
        if rectifying { rectify += seconds; return }
        guard let base = moment ?? birth?.moment else { return }
        moment = base.addingTimeInterval(seconds)
    }

    /// Write the rectified time into the birth.
    func applyRectify() {
        guard let index, let old = births[index].moment, let zone = births[index].timeZone else { return }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = zone
        let new = old.addingTimeInterval(rectify)
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.string(from: new)
        formatter.dateFormat = "HH:mm:ss"
        let time = formatter.string(from: new)
        rectify = 0
        births[index].date = date
        births[index].time = time
    }

    // MARK: cards

    var cards: [String] { layout[workspace] ?? Store.standardLayout[workspace] ?? [] }

    func addCard(_ id: String) {
        var list = cards
        if !list.contains(id) { list.append(id) }
        layout[workspace] = list
    }
    func removeCard(_ id: String) { layout[workspace] = cards.filter { $0 != id } }
    /// Put a card where another stands: after it when it came from before, before it when it came from after.
    func moveCard(_ id: String, onto other: String) {
        var list = cards
        guard id != other, let from = list.firstIndex(of: id), let to = list.firstIndex(of: other) else { return }
        list.remove(at: from)
        list.insert(id, at: to)
        layout[workspace] = list
    }
    func moveCard(_ id: String, by offset: Int) {
        var list = cards
        guard let at = list.firstIndex(of: id), list.indices.contains(at + offset) else { return }
        list.swapAt(at, at + offset)
        layout[workspace] = list
    }
    func resetLayout() { layout[workspace] = Store.standardLayout[workspace] ?? [] }

    // MARK: place

    /// Fill latitude, longitude and time zone from the place's name. The name is sent to Apple's geocoder.
    func lookUpPlace() {
        guard let index, !births[index].place.isEmpty else { return }
        let id = births[index].id
        CLGeocoder().geocodeAddressString(births[index].place) { marks, error in
            Task { @MainActor in
                guard let at = self.births.firstIndex(where: { $0.id == id }) else { return }
                guard let mark = marks?.first, let location = mark.location else {
                    self.problem = "The place was not found: \(error?.localizedDescription ?? "no match")"
                    return
                }
                self.births[at].latitude = (location.coordinate.latitude * 10000).rounded() / 10000
                self.births[at].longitude = (location.coordinate.longitude * 10000).rounded() / 10000
                if let zone = mark.timeZone { self.births[at].zone = zone.identifier }
                self.problem = nil
            }
        }
    }
}
