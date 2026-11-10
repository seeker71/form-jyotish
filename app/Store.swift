import CoreLocation
import Foundation

/// The saved births and the chart read for the selected one.
@MainActor
final class Store: ObservableObject {
    @Published var births: [Birth] = [] { didSet { save() } }
    @Published var selection: Birth.ID?
    @Published var chart: Chart?
    @Published var chartOf: Birth.ID?
    @Published var problem: String?
    @Published var busy = false

    private let file: URL

    init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("FormJyotish")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        file = folder.appendingPathComponent("charts.json")
        if let data = try? Data(contentsOf: file), let saved = try? JSONDecoder().decode([Birth].self, from: data) {
            births = saved
        } else {
            // a first run opens on one example, so the window shows a chart rather than an empty list
            births = [Birth(name: "Example: New Delhi", date: "2000-01-01", time: "17:30:00", zone: "Asia/Kolkata", place: "New Delhi, India", latitude: 28.6139, longitude: 77.209)]
        }
        selection = births.first?.id
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(births) else { return }
        try? data.write(to: file, options: .atomic)
    }

    var index: Int? { births.firstIndex { $0.id == selection } }

    func add() {
        let birth = Birth()
        births.append(birth)
        selection = birth.id
    }

    func remove(_ id: Birth.ID) {
        births.removeAll { $0.id == id }
        if selection == id { selection = births.first?.id }
    }

    func calculate(engine: Engine, node: String, ayanamsa: String) {
        guard let index else { return }
        let birth = births[index]
        busy = true
        problem = nil
        Task.detached {
            let result = Result { try engine.chart(for: birth, node: node, ayanamsa: ayanamsa) }
            await MainActor.run {
                self.busy = false
                switch result {
                case .success(let chart):
                    self.chart = chart
                    self.chartOf = birth.id
                case .failure(let error):
                    self.problem = error.localizedDescription
                }
            }
        }
    }

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
