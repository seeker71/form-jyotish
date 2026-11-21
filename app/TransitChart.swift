import SwiftUI

/// The sky by itself, in the houses of the birth lagna: no birth position stands in it, so it reads cleanly
/// beside the Rasi chart. It shows the moment the time bar stands at; while the bar stands at the birth, it
/// shows the sky of now and reads it again every five minutes.
struct TransitChart: View {
    @EnvironmentObject var store: Store
    let natal: Chart
    @State private var now: Chart?
    @State private var readAt: Date?
    @State private var problem: String?

    /// what the reading of now depends on: a change in any of it reads the sky again
    private var key: String { "\(natal.jd) \(store.node) \(store.ayanamsa) \(store.here?.place ?? "") \(store.moment == nil)" }

    private func readNow() async {
        guard store.moment == nil, let birth = store.birth else { return }
        let engine = store.engine, node = store.node, ayanamsa = store.ayanamsa, at = Date()
        let zoneHours = Double(store.skyZone.secondsFromGMT(for: at)) / 3600, day = at.timeIntervalSince1970 / 86400 + 2440587.5
        let latitude = store.here?.latitude ?? birth.latitude, longitude = store.here?.longitude ?? birth.longitude
        let result = await Task.detached { Result { try engine.chart(julianDay: day, latitude: latitude, longitude: longitude, node: node, ayanamsa: ayanamsa, zoneHours: zoneHours) } }.value
        switch result {
        case .success(let chart): now = chart; readAt = at; problem = nil
        case .failure(let error): problem = error.localizedDescription
        }
    }

    private func marks(_ sky: Chart) -> [Int: [ChartMark]] {
        var bySign: [Int: [ChartMark]] = [natal.asc.sign: [ChartMark(code: "As", label: "As")]]
        for g in sky.grahas {
            let back = g.retro && g.id != "Ra" && g.id != "Ke"
            bySign[g.sign, default: []].append(ChartMark(code: g.id, label: "\(g.id)\(back ? "℞" : "") \(ChartMark.degrees(g.deg, minutes: store.chartMinutes))", retro: back,
                                                         note: "\(Names.lords[g.id] ?? g.id) in the sky of this moment, in \(Names.signs[g.sign])\(back ? ". Retrograde." : ".")"))
        }
        return bySign
    }

    var body: some View {
        // the time bar's moment when it stands away from the birth, else the sky of now
        let sky = store.moment == nil ? now : store.sky, at = store.moment ?? readAt
        VStack(alignment: .leading, spacing: 6) {
            if let sky {
                ChartView(style: store.style, title: "Transit", ascSign: natal.asc.sign, marks: marks(sky))
            } else {
                Text(problem ?? "Reading the sky…").foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 120)
            }
            if let at {
                Text("\(store.moment == nil ? "Now" : "The time bar's moment"): \(at.formatted(Date.FormatStyle(date: .abbreviated, time: .shortened, timeZone: store.skyZone))) · houses from the birth lagna")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task(id: key) {
            while !Task.isCancelled {
                await readNow()
                try? await Task.sleep(nanoseconds: 300_000_000_000)
            }
        }
    }
}
