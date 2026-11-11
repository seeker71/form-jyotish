import SwiftUI

/// What the sky does next, dated: ingresses, stations, and crossings of the birth points.
struct TransitDates: View {
    @EnvironmentObject var store: Store
    let natal: Chart

    @State private var days = 365.0
    @State private var events: [TransitEvent] = []
    @State private var from: Double?
    @State private var busy = false
    @State private var problem: String?
    @State private var ingresses = true
    @State private var stations = true
    @State private var contacts = true

    private static let spans: [(name: String, days: Double)] = [("1 month", 30), ("3 months", 91), ("1 year", 365), ("3 years", 1096)]

    private func read() {
        guard let start = store.viewDay else { return }
        busy = true
        let engine = store.engine, node = store.node, ayanamsa = store.ayanamsa, natal = natal, days = days
        Task.detached {
            let result = Result { try engine.transits(from: start, days: days, node: node, ayanamsa: ayanamsa, natal: natal) }
            await MainActor.run {
                busy = false
                switch result {
                case .success(let found): events = found; from = start; problem = nil
                case .failure(let error): problem = error.localizedDescription
                }
            }
        }
    }

    private func house(_ sign: Int, from: Int) -> Int { (sign - from + 12) % 12 + 1 }
    private func ordinal(_ n: Int) -> String { "\(n)" + (n == 1 ? "st" : n == 2 ? "nd" : n == 3 ? "rd" : "th") }
    private func name(_ code: String) -> String { Names.lords[code] ?? code }

    /// what happened, and what it means against the birth chart
    private func words(_ e: TransitEvent) -> (what: String, note: String) {
        let moon = natal.graha("Mo")?.sign ?? 0
        switch e.kind {
        case "ingress":
            let sign = e.sign ?? 0, fromMoon = house(sign, from: moon)
            var note = "\(ordinal(house(sign, from: natal.asc.sign))) from the lagna, \(ordinal(fromMoon)) from the Moon"
            if e.graha == "Sa" {
                // Saturn's seven and a half years over the Moon, and its passage through the 4th and 8th from it
                let saturn = [12: "Sade Sati: Saturn in the 12th from the Moon", 1: "Sade Sati: Saturn over the Moon", 2: "Sade Sati: Saturn in the 2nd from the Moon",
                              4: "Kantaka Shani: Saturn in the 4th from the Moon", 8: "Ashtama Shani: Saturn in the 8th from the Moon"]
                if let special = saturn[fromMoon] { note += " · " + special }
                if fromMoon == 3 && e.forward { note += " · Sade Sati has ended" }
            }
            let ketu = e.graha == "Ra" ? "; Ketu enters \(Names.signs[(sign + 6) % 12])" : ""
            return ("\(name(e.graha)) enters \(Names.signs[sign])\(e.forward || e.graha == "Ra" ? "" : ", moving backward")\(ketu)", note)
        case "station":
            return ("\(name(e.graha)) turns \(e.forward ? "direct" : "retrograde")", e.forward ? "It moves forward again from here" : "It appears to move backward from here")
        default:
            let point = e.natal == "As" ? "the lagna's degree" : "the birth \(name(e.natal ?? ""))"
            let node = e.graha == "Ra" || e.graha == "Ke"
            return ("\(name(e.graha)) crosses \(point)\(e.forward || node ? "" : ", moving backward")", "Exact conjunction with the birth position")
        }
    }

    var body: some View {
        let format = Date.FormatStyle(date: .abbreviated, time: .shortened, timeZone: store.zone)
        let shown = events.filter { ($0.kind == "ingress" && ingresses) || ($0.kind == "station" && stations) || ($0.kind == "contact" && contacts) }
        VStack(alignment: .leading, spacing: 8) {
            // the span and the three kinds stand on one line where the card has room, on two where it is narrow
            let span = Picker("Span", selection: $days) { ForEach(Self.spans, id: \.days) { Text($0.name).tag($0.days) } }
                    .pickerStyle(.segmented).labelsHidden().frame(width: 300)
                    .help("How far ahead of the time bar's moment to look")
            let kinds = HStack(spacing: 10) {
                Toggle("Ingresses", isOn: $ingresses).help("A graha entering a sign")
                Toggle("Stations", isOn: $stations).help("A graha turning retrograde or direct")
                Toggle("Crossings", isOn: $contacts).help("Mars, Jupiter, Saturn, Rahu or Ketu reaching the exact degree of a birth graha or the lagna")
                if busy { ProgressView().controlSize(.small) }
            }.fixedSize()
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { span; kinds }
                VStack(alignment: .leading, spacing: 6) { span; kinds }
            }
            .toggleStyle(.checkbox)
            HStack(spacing: 8) {
                if let from { Text("From \(Names.date(julianDay: from).formatted(format))").font(.footnote).foregroundStyle(.secondary) }
                if let from, let now = store.viewDay, abs(now - from) > 0.5 {
                    Button("Read from the time bar's moment") { read() }.controlSize(.small)
                }
            }
            if let problem { Label(problem, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            if shown.isEmpty && !busy { Text("Nothing of the chosen kinds falls in this span.").foregroundStyle(.secondary) }
            VStack(alignment: .leading, spacing: 1) {
                ForEach(shown) { event in
                    let said = words(event), chosen = store.pick?.graha == event.graha
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(Names.date(julianDay: event.jd).formatted(format)).monospacedDigit().foregroundStyle(.secondary).frame(width: 170, alignment: .leading)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(said.what).fontWeight(.medium).foregroundStyle(Tint.graha(event.graha))
                            Text(said.note).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2).padding(.horizontal, 6)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.accentColor.opacity(chosen ? 0.16 : 0)))
                    .contentShape(Rectangle())
                    .onTapGesture { store.pick = .graha(event.graha); store.go(to: event.jd) }
                    .help("Go to this moment")
                }
            }
        }
        .onAppear { if from == nil { read() } }
        .onChanged(of: days) { read() }
        .onChanged(of: natal.jd) { read() }
        .onChanged(of: store.node) { read() }
        .onChanged(of: store.ayanamsa) { read() }
    }
}
