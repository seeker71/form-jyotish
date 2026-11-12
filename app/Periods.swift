import SwiftUI

/// What a period brings forward, read as Light on Life reads it from Parashara (BPHS 47) and Phaladipika 20: in a
/// graha's dasha everything it is in the chart is activated; a bhukti is read by whether its lord and the dasha
/// lord touch the same matters in the same way (confluence) or in opposite ways (conflict).
extension Chart {
    /// a graha's name as it reads inside a sentence: the Sun, the Moon, Mars
    private func called(_ code: String) -> String { (["Su", "Mo"].contains(code) ? "the " : "") + (Names.lords[code] ?? code) }
    private func listed(_ houses: [Int]) -> String {
        let names = houses.map(Chart.ordinal)
        return names.count < 2 ? names.joined() : names.dropLast().joined(separator: ", ") + " and " + (names.last ?? "")
    }
    private func lordship(_ code: String) -> String {
        let ruled = housesRuled(by: code)
        return ruled.isEmpty ? called(code) : "\(called(code)), lord of the \(listed(ruled))"
    }

    /// how a weighing stands, in words: 3 factors support it and 1 asks more of it
    static func weighed(_ supports: Int, _ strains: Int) -> String {
        "\(supports) factor\(supports == 1 ? " supports" : "s support") it and \(strains) ask\(strains == 1 ? "s" : "") more of it."
    }

    /// the houses a graha touches: those it rules, the one it stands in, those it aspects
    func touched(by code: String) -> [Int] {
        guard let g = graha(code) else { return [] }
        return Array(Set(housesRuled(by: code) + [house(ofSign: g.sign)] + aspectedSigns(by: code).map { house(ofSign: $0) })).sorted()
    }

    /// whether a graha eases a house it touches: as its lord, as a trine lord free of the 6th, 8th and 12th, or as a natural benefic
    func eases(_ code: String, house: Int) -> Bool {
        let ruled = housesRuled(by: code)
        return ruled.contains(house) || (ruled.contains(where: [5, 9].contains) && !ruled.contains(where: [6, 8, 12].contains)) || benefic(code)
    }

    /// the stronger of two grahas by shadbala; nil when a node is one of them
    func stronger(_ a: String, _ b: String) -> String? {
        let seven = grahas.prefix(7).map(\.id)
        guard let i = seven.firstIndex(of: a), let j = seven.firstIndex(of: b) else { return nil }
        return strengthRatio(i) >= strengthRatio(j) ? a : b
    }

    /// what a graha's period activates beyond the houses it rules and stands in
    func activation(of code: String) -> [String] {
        guard let g = graha(code) else { return [] }
        var lines: [String] = []
        let node = code == "Ra" || code == "Ke"
        let with = grahas.filter { $0.sign == g.sign && $0.id != code }.map(\.id), seenBy = aspecting(sign: g.sign).filter { $0 != code && !with.contains($0) }
        if node {
            let host = Chart.signLords[g.sign], around = Array(Set(with + seenBy + [host])).filter { $0 != "Ra" && $0 != "Ke" }
            let strongest = around.dropFirst().reduce(around.first) { best, next in best.flatMap { stronger($0, next) } ?? next }
            lines.append("\(called(code)) rules no sign: it gives the results of the house it stands in, of the grahas it stands with\(with.isEmpty ? " (none here)" : " (\(with.map(called).joined(separator: ", ")))") or is aspected by\(seenBy.isEmpty ? " (none here)" : " (\(seenBy.map(called).joined(separator: ", ")))"), and of its sign lord \(called(host)).\(strongest.map { " The strongest of these, \(called($0)), colours its period most." } ?? "")")
        } else {
            let roles = roles(of: code)
            lines.append("By nature \(called(code)) is a \(benefic(code) ? "benefic" : "malefic")\(code == "Mo" ? (moonWaxing ? ", the Moon being waxing" : ", the Moon being waning") : code == "Me" ? (benefic(code) ? "" : ", standing with malefics") : "")\(roles.isEmpty ? "" : "; by the houses it rules it acts as \(roles.joined(separator: ", "))").")
        }
        let formed = yogas.filter { $0.grahas.contains(code) }.map(\.name)
        var seen: [String] = []
        for name in formed where !seen.contains(name) { seen.append(name) }
        lines.append(seen.isEmpty ? "It takes part in none of the chart's yogas." : "It takes part in \(seen.count == 1 ? "one yoga" : "\(seen.count) yogas"), which give in its periods: \(seen.prefix(4).joined(separator: ", "))\(seen.count > 4 ? " and others" : "").")
        if !node, !with.isEmpty { lines.append("It stands with \(with.map(lordship).joined(separator: "; ")): their matters come forward with it.") }
        let reach = aspectedSigns(by: code)
        if !reach.isEmpty {
            let there = grahas.filter { reach.contains($0.sign) }.map(\.id)
            lines.append("It aspects the \(listed(reach.map { house(ofSign: $0) }.sorted())) house\(reach.count == 1 ? "" : "s")\(there.isEmpty ? "" : " and \(there.map(called).joined(separator: " and ")) there"), \(benefic(code) ? "easing" : "asking more of") what it looks at, except a house it rules, which it looks after.")
        }
        if !node, !seenBy.isEmpty { lines.append("It is aspected by \(seenBy.map(lordship).joined(separator: "; ")).") }
        if !node, let host = dispositor(of: g) {
            lines.append("Its dispositor \(called(host.id)) stands in the \(Chart.ordinal(house(ofSign: host.sign))) house, which is drawn into the period.")
        }
        let karakaOf = (1...12).filter { Lore.bhavaKarakas[$0 - 1].code == code }
        if let signifies = Lore.signifies[code] { lines.append("As a karaka it signifies \(signifies)\(karakaOf.isEmpty ? "" : "; it is the bhava karaka of the \(listed(karakaOf))").") }
        return lines
    }

    /// the dasha lord and the bhukti lord read together
    func joint(_ a: String, _ b: String) -> [String] {
        guard let ga = graha(a), let gb = graha(b), a != b else { return [] }
        var lines: [String] = []
        let shared = touched(by: a).filter { touched(by: b).contains($0) }
        if shared.isEmpty { lines.append("The two lords touch no house in common, so each gives its own matters in turn.") }
        var agree: [String] = [], ask: [String] = [], differ: [String] = []
        for house in shared {
            let ea = eases(a, house: house), eb = eases(b, house: house), name = "\(Chart.ordinal(house)) (\(Lore.houseNames[house - 1].lowercased()))"
            if ea && eb { agree.append(name) } else if !ea && !eb { ask.append(name) } else { differ.append(name + ", where \(called(ea ? a : b)) eases and \(called(ea ? b : a)) asks more") }
        }
        if !agree.isEmpty { lines.append("Confluence: both lords ease the \(agree.joined(separator: ", ")).") }
        if !ask.isEmpty { lines.append("Confluence: both lords ask more of the \(ask.joined(separator: ", ")).") }
        if !differ.isEmpty { lines.append("Conflict: the \(differ.joined(separator: "; the ")). \(stronger(a, b).map { "The stronger of the two by shadbala, \(called($0)), prevails." } ?? "The stronger of the two prevails.")") }
        let count = (gb.sign - ga.sign + 12) % 12 + 1
        var turn = "Counted from \(called(a)), \(called(b)) stands in the \(Chart.ordinal(count)): the matters of the \(Chart.ordinal(count)) house (\(Lore.houseNames[count - 1].lowercased())) come forward in this sub-period."
        if [6, 8, 12].contains(count) {
            let harsh = (grahas.filter { $0.sign == gb.sign && $0.id != b }.map(\.id) + aspecting(sign: gb.sign).filter { $0 != b }).filter { !benefic($0) }
            turn += harsh.isEmpty ? " That is a dusthana from the dasha lord; Light on Life finds this weighs only when the sub-period lord is with or aspected by a malefic, which is not so here."
                                  : " That is a dusthana from the dasha lord, and \(called(b)) is with or aspected by a malefic (\(Array(Set(harsh)).sorted().map(called).joined(separator: ", "))): the two periods ask to be adjusted to each other."
        }
        lines.append(turn)
        return lines
    }

    /// a mahadasha in a few sentences: what its lord rules, where it stands, its yogas, and how the weighing leans
    func brief(of code: String) -> String {
        guard let g = graha(code) else { return "" }
        let ruled = housesRuled(by: code), house = house(ofSign: g.sign), w = factors(for: g)
        var text = ruled.isEmpty ? "Rules no sign; stands in the \(Chart.ordinal(house)) and gives through \(called(Chart.signLords[g.sign]))." : "Rules the \(listed(ruled)), stands in the \(Chart.ordinal(house))."
        var seen: [String] = []
        for name in yogas.filter({ $0.grahas.contains(code) }).map(\.name) where !seen.contains(name) { seen.append(name) }
        if !seen.isEmpty { text += " Yogas: \(seen.prefix(3).joined(separator: ", "))\(seen.count > 3 ? " and \(seen.count - 3) more" : "")." }
        let touch = touched(by: code)
        text += " It touches the \(listed(touch)) house\(touch.count == 1 ? "" : "s")."
        text += " " + Chart.weighed(w.supports.count, w.strains.count)
        return text
    }
}

extension Lore {
    static let periodPrinciple = "In a graha's period everything it is in the chart comes forward: its nature, its yogas, the houses it rules, stands in and aspects, the grahas with it, its dispositor, and what it signifies. What speaks for a matter and what speaks against it are cumulative: both show, and neither cancels the other. A lord that is weak gives its good in smaller measure."
}

extension Report {
    private func periodHead(_ words: String) -> some View { Text(words).font(Ink.times(12)).bold().foregroundColor(Ink.maroon) }
    private func periodProse(_ words: String, size: CGFloat = 10.3) -> some View { Text(words).font(Ink.times(size)).fixedSize(horizontal: false, vertical: true) }

    /// The period running on the day of the report, read by the ten things a dasha activates, and the two lords together.
    func runningPage(_ sky: Chart) -> ((Int) -> AnyView)? {
        let running = Vimshottari.running(at: sky.jd, in: chart.dasha, depth: 2)
        guard let maha = running.first else { return nil }
        let antar = running.count > 1 && running[1].lord != maha.lord ? running[1] : nil
        let name = { (code: String) in Names.lords[code] ?? code }
        return { number in
            self.page(number, title: "The Running Period") {
                self.title("The Period Running Now, Read", y: 76)
                self.rule(x: 65, y: 95, width: 468)
                VStack(alignment: .leading, spacing: 5) {
                    self.periodProse("On \(self.text(Names.date(julianDay: sky.jd), "d MMMM yyyy")) the mahadasha of \(name(maha.lord)) runs until \(self.text(Names.date(julianDay: maha.end), "d MMMM yyyy"))\(running.count > 1 ? ", with the antardasha of \(name(running[1].lord)) until \(self.text(Names.date(julianDay: running[1].end), "d MMMM yyyy"))" : "").")
                    self.periodHead("\(name(maha.lord)), lord of the mahadasha").padding(.top, 2)
                    self.periodProse(self.chart.brief(of: maha.lord))
                    ForEach(self.chart.activation(of: maha.lord), id: \.self) { self.periodProse("· " + $0, size: 10) }
                    if let antar {
                        self.periodHead("\(name(antar.lord)), lord of the antardasha").padding(.top, 2)
                        self.periodProse(self.chart.brief(of: antar.lord))
                        ForEach(self.chart.activation(of: antar.lord), id: \.self) { self.periodProse("· " + $0, size: 10) }
                        self.periodHead("The two lords together").padding(.top, 2)
                        ForEach(self.chart.joint(maha.lord, antar.lord), id: \.self) { self.periodProse("· " + $0, size: 10) }
                    }
                    Text(Lore.periodPrinciple + " " + Lore.balance).font(Ink.times(9.6)).italic().fixedSize(horizontal: false, vertical: true).padding(.top, 3)
                }
                .frame(width: 452, alignment: .leading).at(74, 106)
            }
        }
    }

    /// Every mahadasha of the life in a few sentences.
    func mahasReadPage(_ number: Int) -> AnyView {
        page(number, title: "The Mahadashas Read") {
            title("What Each Mahadasha Brings Forward", y: 76)
            rule(x: 65, y: 95, width: 468)
            VStack(alignment: .leading, spacing: 7) {
                periodProse(Lore.periodPrinciple, size: 10)
                ForEach(chart.dasha) { period in
                    (Text("\(Names.lords[period.lord] ?? period.lord)").bold().foregroundColor(Ink.graha(period.lord))
                        + Text("  \(self.text(Names.date(julianDay: max(period.start, chart.jd)), "MMM yyyy")) – \(self.text(Names.date(julianDay: period.end), "MMM yyyy")).  ").italic()
                        + Text(chart.brief(of: period.lord)))
                        .font(Ink.times(10.2)).fixedSize(horizontal: false, vertical: true)
                }
                Text("The pages on each graha weighed and on the twelve houses give the detail behind each line. " + Lore.balance).font(Ink.times(9.6)).italic().fixedSize(horizontal: false, vertical: true).padding(.top, 2)
            }
            .frame(width: 452, alignment: .leading).at(74, 106)
        }
    }
}
