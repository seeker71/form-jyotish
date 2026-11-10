import SwiftUI

/// Placements that stand close to a boundary, with what lies across it and what would carry them there.
/// A reading that leans on such a placement leans on the birth time and on the ayanamsa chosen.
struct EdgesCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    struct Edge: Identifiable {
        let id: String
        let code: String
        let words: String
    }

    /// how far ayanamsas in common use stand apart: Lahiri and B.V. Raman differ by about 1 degree 27 minutes
    static let spread = 1.45

    private func span(_ minutes: Double) -> String {
        minutes < 90 ? "\(max(1, Int(minutes.rounded()))) minutes" : minutes < 2880 ? String(format: "%.1f hours", minutes / 60) : "\(Int((minutes / 1440).rounded())) days"
    }

    /// what would carry a point across an edge `gap` degrees away: a change of birth time, or of ayanamsa
    private func carried(_ gap: Double, ahead: Bool, speed: Double?) -> String {
        var ways: [String] = []
        if let speed, abs(speed) > 0.0001 {
            let later = ahead == (speed > 0)
            ways.append("a birth \(span(gap / abs(speed) * 1440)) \(later ? "later" : "earlier")")
        }
        ways.append("an ayanamsa \(Names.dms(gap)) \(ahead ? "smaller" : "larger")")
        return ways.joined(separator: ", or ")
    }

    private var edges: [Edge] {
        // the lagna crosses a degree in about four minutes; the grahas carry their own speeds
        var points: [(code: String, name: String, lon: Double, speed: Double?)] = [("As", "The lagna", chart.asc.lon, 360.0)]
        points += chart.grahas.map { ($0.id, Names.lords[$0.id] ?? $0.name, $0.lon, $0.speed) }
        var found: [Edge] = []
        for p in points {
            let inSign = p.lon.truncatingRemainder(dividingBy: 30), sign = Int(p.lon / 30) % 12
            let ahead = inSign > 15, gap = ahead ? 30 - inSign : inSign
            if gap <= EdgesCard.spread {
                let across = (sign + (ahead ? 1 : 11)) % 12
                let raman = ahead && gap < EdgesCard.spread && store.ayanamsa != "raman" ? " B.V. Raman's ayanamsa places it there." : ""
                found.append(Edge(id: p.code + "-sign", code: p.code,
                                  words: "\(p.name) stands at \(Names.dms(inSign)) \(Names.signs[sign]), \(Names.dms(gap)) \(ahead ? "before" : "past") the edge of \(Names.signs[across]). It would stand in \(Names.signs[across]), the \(Chart.ordinal(chart.house(ofSign: across))) house, with \(carried(gap, ahead: ahead, speed: p.speed)).\(raman)"))
            }
            // the Moon's nakshatra opens the dashas, the lagna's colours the person: their edges matter most
            guard p.code == "Mo" || p.code == "As" else { continue }
            let width = 360.0 / 27, inNak = p.lon.truncatingRemainder(dividingBy: width), nak = Int(p.lon / width) % 27
            let nakAhead = inNak > width / 2, nakGap = nakAhead ? width - inNak : inNak
            if nakGap <= 1.0 {
                let across = (nak + (nakAhead ? 1 : 26)) % 27, lord = Vimshottari.order[across % 9]
                let dasha = p.code == "Mo" ? " The dashas would then open with \(Names.lords[lord] ?? lord), though their dates would move by months only: the count carries over the edge." : ""
                found.append(Edge(id: p.code + "-nak", code: p.code,
                                  words: "\(p.name) stands \(Names.dms(nakGap)) \(nakAhead ? "before" : "past") the edge of the nakshatra \(Glossary.nakshatraNames[across]). It would stand there with \(carried(nakGap, ahead: nakAhead, speed: p.speed)).\(dasha)"))
            }
        }
        return found
    }

    var body: some View {
        let lagna = chart.asc.deg, navamsa = lagna.truncatingRemainder(dividingBy: 30.0 / 9)
        VStack(alignment: .leading, spacing: 8) {
            if edges.isEmpty {
                Text("No graha and no lagna stands within \(Names.dms(EdgesCard.spread)) of a sign's edge. The signs of this chart hold under any ayanamsa in common use.")
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(edges) { edge in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Button(edge.code) { store.pick = edge.code == "As" ? .sign(chart.asc.sign) : .graha(edge.code) }
                        .buttonStyle(.bordered).controlSize(.small).tint(Tint.graha(edge.code)).frame(width: 44, alignment: .leading)
                    Text(edge.words).fixedSize(horizontal: false, vertical: true)
                }
            }
            Text("The lagna moves a degree in about four minutes. Its sign holds for a birth up to about \(span(lagna * 4)) earlier or \(span((30 - lagna) * 4)) later; its navamsa for about \(span(navamsa * 4)) earlier or \(span((30.0 / 9 - navamsa) * 4)) later.")
                .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Text("To test the birth time, open Rectify in the time bar. To test the ayanamsa, press ⌘K and type “ayanamsa”.").font(.footnote).foregroundStyle(.secondary)
            }
            Text("A placement near an edge is read with both sides in mind. Published charts of the same person can differ here, and each reading follows from its own positions.")
                .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The annual chart (Varshaphal): the sky at the moment the Sun returns to its birth longitude, for any year of life.
struct AnnualCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart
    @State private var age: Int? = nil
    @State private var year: Chart? = nil
    @State private var failure: String? = nil
    @State private var reading = false

    /// the year of life the moment under view falls in
    private var viewedAge: Int { max(0, Int(((store.viewDay ?? chart.jd) - chart.jd) / 365.2564)) }
    private var shownAge: Int { age ?? viewedAge }

    /// Find the Sun's return for a year of life: step from the sidereal year's estimate by the Sun's own speed.
    private func read() {
        guard let birth = store.birth, let sun = chart.graha("Su") else { return }
        let engine = store.engine, node = store.node, ayanamsa = store.ayanamsa, zone = store.zone, years = shownAge, target = sun.lon
        reading = true
        Task.detached {
            var day = chart.jd + Double(years) * 365.256363
            var found: Chart? = nil, problem: String? = nil
            do {
                for _ in 0..<5 {
                    let hours = Double(zone.secondsFromGMT(for: Names.date(julianDay: day))) / 3600
                    let sky = try engine.chart(julianDay: day, latitude: birth.latitude, longitude: birth.longitude, node: node, ayanamsa: ayanamsa, zoneHours: hours)
                    found = sky
                    guard let now = sky.graha("Su") else { break }
                    let off = (now.lon - target + 540).truncatingRemainder(dividingBy: 360) - 180
                    if abs(off) < 0.000003 { break }
                    day -= off / max(0.9, now.speed)
                }
            } catch { problem = error.localizedDescription }
            let result = found, said = problem
            await MainActor.run { if years == shownAge { year = result; failure = said; reading = false } }
        }
    }

    private func marks(_ sky: Chart, muntha: Int) -> [Int: [ChartMark]] {
        var bySign: [Int: [ChartMark]] = [sky.asc.sign: [ChartMark(code: "As", label: "As", sign: sky.asc.sign)]]
        for g in sky.grahas {
            let back = g.retro && g.id != "Ra" && g.id != "Ke"
            bySign[g.sign, default: []].append(ChartMark(code: g.id, label: "\(g.id)\(back ? "℞" : "") \(Int(g.deg))°", retro: back))
        }
        bySign[muntha, default: []].append(ChartMark(code: "Mu", label: "Mu", sign: muntha))
        return bySign
    }

    var body: some View {
        let muntha = (chart.asc.sign + shownAge) % 12
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Stepper("Year \(shownAge + 1) of life, from age \(shownAge)", value: Binding(get: { shownAge }, set: { age = max(0, min(119, $0)) }), in: 0...119)
                    .fixedSize()
                if age != nil { Button("Follow the time bar") { age = nil }.controlSize(.small).help("Show the year the moment in the time bar falls in") }
                if reading { ProgressView().controlSize(.small) }
            }
            if let failure { Text(failure).foregroundStyle(.red) }
            if let year {
                let format = Date.FormatStyle(date: .abbreviated, time: .shortened, timeZone: store.zone)
                let lord = Chart.signLords[muntha], house = year.house(ofSign: muntha)
                HStack(alignment: .top, spacing: 18) {
                    ChartView(style: store.style, title: "Varsha", ascSign: year.asc.sign, marks: marks(year, muntha: muntha)).frame(width: 240, height: 240)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("The Sun returns on \(Names.date(julianDay: year.jd).formatted(format)).").fontWeight(.medium)
                            Button("Go there") { store.go(to: year.jd) }.controlSize(.small).help("Move the whole desk to that moment")
                        }
                        Text("The year's lagna is \(Names.signs[year.asc.sign]) at \(Names.dms(year.asc.deg)), the \(Chart.ordinal(chart.house(ofSign: year.asc.sign))) house of the birth chart: \(Lore.houses[chart.house(ofSign: year.asc.sign) - 1]) colour the year.")
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 6) {
                            Text("Muntha is in")
                            Button(Names.signs[muntha]) { store.pick = .sign(muntha) }.buttonStyle(.bordered).controlSize(.small)
                            Text("the \(Chart.ordinal(house)) house of the year, the \(Chart.ordinal(chart.house(ofSign: muntha))) of the birth.")
                        }
                        HStack(spacing: 6) {
                            Text("Its lord is")
                            Button(Names.lords[lord] ?? lord) { store.pick = .graha(lord) }.buttonStyle(.bordered).controlSize(.small).tint(Tint.graha(lord)).help(Help.graha(lord))
                            Text(year.graha(lord).map { "in \(Names.signs[$0.sign]), the \(Chart.ordinal(year.house(ofSign: $0.sign))) house of the year." } ?? "")
                        }
                        Text("Muntha is the birth lagna carried forward one sign for each year of life. The house it falls in names where the year's attention gathers: \(Lore.houses[house - 1]). \([6, 8, 12].contains(house) ? "In the \(Chart.ordinal(house)) it is read as a year that works through \(house == 6 ? "service and effort" : house == 8 ? "depth and renewal" : "release and rest")." : "")")
                            .foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            Text("The annual chart belongs to the Tajika tradition. It is cast for the birth place and read beside the birth chart and the running dasha, never in their place. " + Lore.balance)
                .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .onAppear { read() }
        .onChanged(of: shownAge) { read() }
        .onChanged(of: chart.jd) { read() }
        .onChanged(of: store.ayanamsa) { read() }
    }
}
