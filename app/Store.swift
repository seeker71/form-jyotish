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
    static let workspaces = ["Overview", "Vargas", "Dasha", "Strength", "KP", "Transits"]
    static let standardLayout: [String: [String]] = [
        "Overview": ["birth", "chart:0", "chart:5", "grahas", "timeline"],
        "Vargas": (0..<16).map { "chart:\($0)" },
        "Dasha": ["timeline", "dashas"],
        "Strength": ["shadbala", "ashtakavarga"],
        "KP": ["kp-grahas", "kp-cusps", "kp-houses", "kp-planets"],
        "Transits": ["chart:0", "transits", "timeline"],
    ]

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
    @Published var problem: String?
    @Published var workspace: String { didSet { defaults.set(workspace, forKey: "workspace") } }
    @Published var layout: [String: [String]] { didSet { defaults.set(try? JSONEncoder().encode(layout), forKey: "layout") } }
    @Published var node: String { didSet { defaults.set(node, forKey: "node"); readNatal(); readSky() } }
    @Published var ayanamsa: String { didSet { defaults.set(ayanamsa, forKey: "ayanamsa"); readNatal(); readSky() } }
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
        workspace = defaults.string(forKey: "workspace").flatMap { Store.workspaces.contains($0) ? $0 : nil } ?? "Overview"
        layout = defaults.data(forKey: "layout").flatMap { try? JSONDecoder().decode([String: [String]].self, from: $0) } ?? Store.standardLayout
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
        guard let data = try? JSONEncoder().encode(births) else { return }
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

    func remove(_ id: Birth.ID) {
        births.removeAll { $0.id == id }
        if current == id { current = births.first?.id }
    }

    // MARK: readings

    func readNatal() {
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
