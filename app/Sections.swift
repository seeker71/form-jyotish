import SwiftUI

/// The sixteen divisional charts, side by side.
struct VargaGrid: View {
    let chart: Chart
    let style: ChartStyle

    private func labels(_ index: Int) -> [Int: [String]] {
        var bySign: [Int: [String]] = [chart.asc.vargas[index]: ["As"]]
        for graha in chart.grahas { bySign[graha.vargas[index], default: []].append(graha.id) }
        return bySign
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 16)], spacing: 16) {
            ForEach(0..<16, id: \.self) { index in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Names.vargaCodes[index]) · \(Names.vargas[index])").font(.callout)
                    ChartDiagram(style: style, title: Names.vargaCodes[index], ascSign: chart.asc.vargas[index], bySign: labels(index))
                }
            }
        }
    }
}

/// One Vimshottari period that opens into its nine parts, down to the sookshma dasha.
struct DashaNode: View {
    let period: Period
    let trail: String
    let depth: Int
    let birth: Double
    let format: Date.FormatStyle
    @State private var open = false

    private var now: Double { Date().timeIntervalSince1970 / 86400 + 2440587.5 }
    private var name: String { trail.isEmpty ? (Names.lords[period.lord] ?? period.lord) : "\(trail)–\(Names.lordsThree[period.lord] ?? period.lord)" }
    private var span: String {
        "\(Names.date(julianDay: max(period.start, birth)).formatted(format)) – \(Names.date(julianDay: period.end).formatted(format))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                if depth < 4 {
                    Button { open.toggle() } label: { Image(systemName: open ? "chevron.down" : "chevron.right").frame(width: 12) }
                        .buttonStyle(.plain)
                        .accessibilityLabel(open ? "Collapse \(name)" : "Expand \(name)")
                } else {
                    Color.clear.frame(width: 12, height: 1)
                }
                Text(name).frame(width: 190, alignment: .leading)
                Text(span).foregroundStyle(.secondary)
            }
            .fontWeight(period.holds(now) ? .bold : .regular)
            if open {
                ForEach(Vimshottari.parts(of: period).filter { $0.end > birth }) { part in
                    DashaNode(period: part, trail: trail.isEmpty ? (Names.lordsThree[period.lord] ?? period.lord) : name, depth: depth + 1, birth: birth, format: format)
                        .padding(.leading, 18)
                }
            }
        }
    }
}

struct DashaTree: View {
    let chart: Chart
    let zone: TimeZone

    var body: some View {
        let format = Date.FormatStyle(date: .abbreviated, time: .shortened, timeZone: zone)
        VStack(alignment: .leading, spacing: 4) {
            Text("Vimshottari: mahadasha, antardasha, pratyantardasha, sookshma dasha").font(.headline)
            ForEach(chart.dasha.filter { $0.end > chart.jd }) { maha in
                DashaNode(period: maha, trail: "", depth: 1, birth: chart.jd, format: format)
            }
        }
        .monospacedDigit()
    }
}

/// Krishnamurti Paddhati: positions under the KP ayanamsa, Placidus cusps and the significators.
struct KPSection: View {
    let chart: Chart

    private func header(_ titles: [String]) -> some View {
        GridRow { ForEach(titles, id: \.self) { Text($0).font(.caption).foregroundStyle(.secondary) } }
    }

    var body: some View {
        let kp = chart.kp, reading = KPReading(kp: kp)
        VStack(alignment: .leading, spacing: 18) {
            Text("KP ayanamsa \(Names.dms(kp.ayanamsa)) · Placidus cusps · Fortuna \(Names.signs[kp.fortuna.sign]) \(Names.dms(kp.fortuna.deg))")
                .font(.footnote).foregroundStyle(.secondary)
            Paired {
                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 4) {
                    header(["Graha", "Rasi", "Longitude", "Rasi lord", "Star lord", "Sub lord", "Sub-sub"])
                    Divider()
                    ForEach(kp.grahas + kp.outer) { g in
                        GridRow {
                            Text(g.name).fontWeight(.medium); Text(Names.signs[g.sign]); Text(Names.dms(g.deg))
                            Text(g.rasi_lord); Text(g.nak_lord); Text(g.sub_lord); Text(g.sub_sub)
                        }
                    }
                }
                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 4) {
                    header(["Cusp", "Rasi", "Longitude", "Rasi lord", "Star lord", "Sub lord", "Sub-sub"])
                    Divider()
                    ForEach(kp.cusps.indices, id: \.self) { index in
                        let cusp = kp.cusps[index]
                        GridRow {
                            Text("\(index + 1)").fontWeight(.medium); Text(Names.signs[cusp.sign]); Text(Names.dms(cusp.deg))
                            Text(cusp.rasi_lord); Text(cusp.nak_lord); Text(cusp.sub_lord); Text(cusp.sub_sub)
                        }
                    }
                }
            }
            Paired {
                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 4) {
                    header(["House", "In stars of occupants", "Occupants", "In stars of cusp lord", "Cusp lord"])
                    Divider()
                    ForEach(0..<12, id: \.self) { house in
                        let row = reading.houseRow(house)
                        GridRow {
                            Text("\(house + 1)").fontWeight(.medium); Text(row.starsOfOccupants.joined(separator: ", "))
                            Text(row.occupants.joined(separator: ", ")); Text(row.starsOfLord.joined(separator: ", ")); Text(row.lord)
                        }
                    }
                }
                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 4) {
                    header(["Graha", "Very strong", "Strong", "Normal", "Weak"])
                    Divider()
                    ForEach(kp.grahas) { graha in
                        let s = reading.signified(by: graha), list = { (h: [Int]) in h.map(String.init).joined(separator: " ") }
                        GridRow {
                            Text(graha.name).fontWeight(.medium); Text(list(s.veryStrong)); Text(list(s.strong)); Text(list(s.normal)); Text(list(s.weak))
                        }
                    }
                }
            }
        }
        .monospacedDigit()
    }
}

/// The sky at a chosen moment, set against the birth chart.
struct TransitSection: View {
    let natal: Chart
    let style: ChartStyle
    let zone: TimeZone
    /// reads the sky for a moment at the birth place
    let load: (Date) throws -> Chart

    @State private var moment = Date()
    @State private var sky: Chart?
    @State private var problem: String?
    @State private var busy = false

    private func read() {
        busy = true
        let moment = moment, load = load
        Task.detached {
            let result = Result { try load(moment) }
            await MainActor.run {
                busy = false
                switch result {
                case .success(let chart): sky = chart; problem = nil
                case .failure(let error): problem = error.localizedDescription
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                DatePicker("Transit moment", selection: $moment).environment(\.timeZone, zone).frame(maxWidth: 320)
                Button("Read") { read() }
                Button("Now") { moment = Date(); read() }
                if busy { ProgressView().controlSize(.small) }
                Text("in \(zone.identifier) time").font(.footnote).foregroundStyle(.secondary)
            }
            if let problem { Label(problem, systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
            if let sky {
                Paired {
                    ChartDiagram(style: style, title: "Transit", ascSign: natal.asc.sign, bySign: labels(sky)).frame(width: 360, height: 360)
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 5) {
                        GridRow {
                            ForEach(["Graha", "Rasi", "Longitude", "Nakshatra", "Pada", "Motion °/day", "From lagna", "From Moon"], id: \.self) {
                                Text($0).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        Divider()
                        ForEach(sky.grahas + sky.outer) { g in
                            GridRow {
                                Text(g.name).fontWeight(.medium); Text(Names.signs[g.sign]); Text(Names.dms(g.deg)); Text(g.nak_name); Text("\(g.pada)")
                                Text(String(format: "%+.4f", g.speed) + (g.retro && g.id != "Ra" && g.id != "Ke" ? " ℞" : ""))
                                Text("\((g.sign - natal.asc.sign + 12) % 12 + 1)")
                                Text("\((g.sign - (natal.graha("Mo")?.sign ?? 0) + 12) % 12 + 1)")
                            }
                        }
                    }
                    .monospacedDigit()
                }
            }
        }
        .onAppear { if sky == nil { read() } }
    }

    private func labels(_ sky: Chart) -> [Int: [String]] {
        var bySign: [Int: [String]] = [natal.asc.sign: ["As"]]
        for g in sky.grahas { bySign[g.sign, default: []].append("\(g.id)\(g.retro && g.id != "Ra" && g.id != "Ke" ? "℞" : "") \(Int(g.deg))°") }
        return bySign
    }
}

/// Two views side by side when the width allows, one above the other when it does not; neither is squeezed.
struct Paired<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 36) { content }.fixedSize()
            VStack(alignment: .leading, spacing: 20) { content }.fixedSize()
        }
    }
}
