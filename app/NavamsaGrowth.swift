import SwiftUI

extension Chart {
    /// How a graha stands in a sign, on one scale for the Rasi and the Navamsa alike so the two can be compared:
    /// 5 exalted, 4 its own sign, 3 a natural friend's sign, 2 a neutral's, 1 an enemy's, 0 debilitated.
    /// The nodes have no such standing.
    static func standing(of code: String, in sign: Int) -> (grade: Int, word: String)? {
        guard let high = Lore.exalted[code] else { return nil }
        if sign == high { return (5, "exalted") }
        if sign == (high + 6) % 12 { return (0, "debilitated") }
        let lord = Chart.signLords[sign]
        if lord == code { return (4, "its own sign") }
        let host = Names.lords[lord] ?? lord
        switch Lore.natural[code]?[lord] ?? 0 {
        case 1: return (3, "a friend's sign (\(host))")
        case -1: return (1, "an enemy's sign (\(host))")
        default: return (2, "a neutral's sign (\(host))")
        }
    }

    /// A graha from the Rasi to the Navamsa: where it stands in each, and whether it grows stronger, holds or
    /// grows weaker between them. `turn` is +1, 0 or -1; nil for the nodes.
    struct Ripening {
        let rasi: (grade: Int, word: String), navamsa: (grade: Int, word: String)
        let vargottama: Bool
        var turn: Int { vargottama ? 0 : (navamsa.grade - rasi.grade).signum() }
        /// "in a friend's sign (Jupiter)", but "exalted" and "debilitated" as they are
        private static func placed(_ standing: (grade: Int, word: String)) -> String { standing.grade == 5 || standing.grade == 0 ? standing.word : "in " + standing.word }
        var words: String {
            if vargottama { return "Holds firm. It is vargottama, in the same sign in both: the fruit matches the tree, and what it shows it keeps." }
            switch navamsa.grade - rasi.grade {
            case 1...: return navamsa.grade == 5 ? "Grows stronger, to its full height: it begins \(Self.placed(rasi)) and ripens exalted." : "Grows stronger: it begins \(Self.placed(rasi)) and ripens \(Self.placed(navamsa))."
            case ..<0: return navamsa.grade == 0 ? "Grows weaker, to its fall: it begins \(Self.placed(rasi)) and ripens debilitated, and asks care to keep." : "Grows weaker: it begins \(Self.placed(rasi)) and ripens \(Self.placed(navamsa))."
            default: return "Holds steady: it stands alike in both, in different signs."
            }
        }
    }

    func ripening(_ g: Graha) -> Ripening? {
        guard let rasi = Chart.standing(of: g.id, in: g.sign), let navamsa = Chart.standing(of: g.id, in: g.navamsa) else { return nil }
        return Ripening(rasi: rasi, navamsa: navamsa, vargottama: g.sign == g.navamsa)
    }

    /// For the life's timeline a node is read through the lord of the sign it stands in.
    func turn(ofPeriodLord code: String) -> Int? {
        guard let g = graha(code) else { return nil }
        if let own = ripening(g) { return own.turn }
        return graha(Chart.signLords[g.sign]).flatMap { ripening($0) }?.turn
    }
}

/// The Rasi is the tree and the Navamsa its fruit: for each graha, where it stands in both, whether it grows
/// stronger or weaker from the one to the other, and when in the life its own periods bring that out.
struct NavamsaGrowthCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart
    private let widths: [CGFloat] = [66, 170, 190, 300, 170]

    private static func year(_ jd: Double) -> Int { Calendar(identifier: .gregorian).component(.year, from: Names.date(julianDay: jd)) }
    private func age(_ jd: Double) -> Int { max(0, Int((jd - chart.jd) / 365.25)) }
    private static func colour(_ turn: Int?) -> Color { turn == nil ? .gray : turn! > 0 ? .green : turn! < 0 ? .orange : .blue }
    private static func mark(_ turn: Int) -> String { turn > 0 ? "↑" : turn < 0 ? "↓" : "→" }

    /// the mahadashas of the first hundred years, each cut to the life it falls in
    private var periods: [Period] {
        let end = chart.jd + 100 * 365.25
        return chart.dasha.filter { $0.end > chart.jd && $0.start < end }
            .map { Period(lord: $0.lord, start: max($0.start, chart.jd), end: min($0.end, end), antar: nil) }
    }

    private func own(_ code: String) -> String {
        let mine = periods.filter { $0.lord == code }
        return mine.isEmpty ? "none within a hundred years" : mine.map { "\(Self.year($0.start))–\(Self.year($0.end)) · age \(age($0.start))–\(age($0.end))" }.joined(separator: "\n")
    }

    private var timeline: some View {
        let all = periods, span = max(1, (all.last?.end ?? chart.jd + 1) - chart.jd)
        let today = Date().timeIntervalSince1970 / 86400 + 2440587.5
        return VStack(alignment: .leading, spacing: 4) {
            Text("Over the life: each mahadasha coloured by how its lord develops into the Navamsa").font(.callout).fontWeight(.semibold)
            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 1) {
                        ForEach(all) { p in
                            let turn = chart.turn(ofPeriodLord: p.lord), share = (p.end - p.start) / span
                            VStack(spacing: 1) {
                                // a sliver of a period (the one the birth fell in) has no room for words
                                if geo.size.width * share > 34 {
                                    Text(verbatim: "\(p.lord) \(turn.map(Self.mark) ?? "")").font(.caption).fontWeight(.semibold).lineLimit(1)
                                    Text(verbatim: String(Self.year(p.start))).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                            .frame(width: max(0, geo.size.width * share - 1), height: 38)
                            .background(Self.colour(turn).opacity(p.holds(today) ? 0.45 : 0.22))
                            .contentShape(Rectangle())
                            .onTapGesture { store.pick = .period(lords: [p.lord], start: p.start, end: p.end) }
                            .help("\(Names.lords[p.lord] ?? p.lord) mahadasha, \(Self.year(p.start)) to \(Self.year(p.end)), age \(age(p.start)) to \(age(p.end)). Click to read the period.")
                        }
                    }
                    if today > chart.jd, today < chart.jd + span {
                        Rectangle().fill(Color.primary).frame(width: 2, height: 46).offset(x: geo.size.width * (today - chart.jd) / span - 1, y: -4)
                            .help("Today")
                    }
                }
            }
            .frame(height: 42)
            Text("Green: grows stronger. Blue: holds. Orange: grows weaker. Grey: not graded. The line marks today; Rahu and Ketu are read through the lord of their sign. Click a period to read it.")
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: widths.reduce(0, +), alignment: .leading).padding(.top, 10)
    }

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                SheetRow(graha: nil, cells: zip(["Graha", "In the Rasi (D1): the tree", "In the Navamsa (D9): the fruit", "How it develops", "Its own periods"], widths).map { SheetCell(text: $0, width: $1, header: true) })
                ForEach(chart.grahas.filter { Lore.exalted[$0.id] != nil }) { g in
                    if let r = chart.ripening(g) {
                        SheetRow(graha: g.id, cells: [
                            SheetCell(text: Names.lords[g.id] ?? g.id, width: widths[0], tint: Tint.graha(g.id)),
                            SheetCell(text: "\(Names.signs[g.sign])\n\(r.rasi.word)", width: widths[1], met: r.rasi.grade >= 4 || r.rasi.grade == 0, helps: r.rasi.grade != 0),
                            SheetCell(text: "\(Names.signs[g.navamsa])\(r.vargottama ? " · vargottama" : "")\n\(r.navamsa.word)", width: widths[2], met: r.navamsa.grade >= 4 || r.navamsa.grade == 0 || r.vargottama, helps: r.navamsa.grade != 0),
                            SheetCell(text: "\(Self.mark(r.turn)) \(r.words)", width: widths[3], met: r.turn != 0 || r.vargottama, helps: r.turn >= 0),
                            SheetCell(text: own(g.id), width: widths[4])])
                    }
                }
                timeline
                VStack(alignment: .leading, spacing: 2) {
                    Text("The Rasi shows what a graha promises; the Navamsa shows what that promise is worth as it is lived. A graha that stands better in the Navamsa gives more than the Rasi alone suggests; one that stands worse gives less, or gives and does not keep. The turn is felt most in the graha's own periods, and more as the life goes on.")
                    Text("Both charts are graded on one scale: exalted, own sign, a natural friend's sign, a neutral's, an enemy's, debilitated. The Dignity column elsewhere also counts where the grahas stand to each other in this chart, so its word for the Rasi can differ.")
                }
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                .frame(width: widths.reduce(0, +), alignment: .leading).padding(.top, 8)
            }
        }
    }
}
