import SwiftUI

extension Lore {
    /// natural friendship among the seven, row toward column: 1 friend, 0 neutral, -1 enemy
    static let natural: [String: [String: Int]] = {
        let order = ["Su", "Mo", "Ma", "Me", "Ju", "Ve", "Sa"]
        let rows = [[0, 1, 1, 0, 1, -1, -1], [1, 0, 0, 1, 0, 0, 0], [1, 1, 0, -1, 1, 0, 0], [1, -1, 0, 0, 0, 1, 0], [1, 1, 1, -1, 0, -1, 0], [-1, -1, 0, 1, 0, 0, 1], [-1, -1, -1, 1, 0, 1, 0]]
        var table: [String: [String: Int]] = [:]
        for (i, a) in order.enumerated() { for (j, b) in order.enumerated() where i != j { table[a, default: [:]][b] = rows[i][j] } }
        return table
    }()

    /// how two grahas regard each other by nature, said both ways
    static func regard(_ a: String, _ b: String) -> String? {
        guard let ab = natural[a]?[b], let ba = natural[b]?[a] else { return nil }
        let word = { (n: Int) in n > 0 ? "a friend" : n < 0 ? "an enemy" : "neutral" }
        let (x, y) = (Names.lords[a] ?? a, Names.lords[b] ?? b)
        return ab == ba ? "By nature \(x) and \(y) hold each other as \(ab > 0 ? "friends" : ab < 0 ? "enemies" : "neutral")."
                        : "By nature \(x) holds \(y) as \(word(ab)), and \(y) holds \(x) as \(word(ba))."
    }

    /// how the second stands counted from the first: the mutual position a reader checks between period lords
    static func mutual(_ count: Int) -> String {
        switch count {
        case 1: return "together in one sign, which joins their matters"
        case 7: return "opposite each other, which sets their matters face to face"
        case 6, 8: return "6th and 8th from each other, a placing that asks the two periods to adjust to each other"
        case 2, 12: return "2nd and 12th from each other, a placing of give and take between the two"
        case 5, 9: return "in trine to each other, a placing read as easy cooperation"
        case 3, 11: return "3rd and 11th from each other, a placing read as effort that brings gain"
        default: return "4th and 10th from each other, a placing read as action that builds"
        }
    }
}

/// The period running at the moment under view, with what its lords are in this chart and what is passing.
struct DashaContext: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    private func name(_ code: String) -> String { Names.lords[code] ?? code }
    private func chip(_ code: String) -> some View {
        Button(name(code)) { store.pick = .graha(code) }.buttonStyle(.bordered).controlSize(.small).tint(Tint.graha(code)).help(Help.graha(code))
    }
    private func houseChip(_ house: Int) -> some View {
        Button("\(house) · \(Lore.houseNames[house - 1])") { store.pick = .sign(chart.sign(ofHouse: house)) }
            .buttonStyle(.bordered).controlSize(.small).help("The \(Chart.ordinal(house)) house covers \(Lore.houses[house - 1]).")
    }
    private func heading(_ words: String) -> some View { Text(words).font(.subheadline).fontWeight(.semibold).padding(.top, 2) }
    private func words(_ text: String) -> some View { Text(text).fixedSize(horizontal: false, vertical: true) }

    /// one level of the running period: its name, its dates and how far through it the moment stands
    private func level(_ title: String, _ lords: [String], _ p: Period, _ day: Double) -> some View {
        let format = Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: store.zone)
        let done = min(1, max(0, (day - p.start) / (p.end - p.start)))
        return HStack(spacing: 10) {
            Text(title).foregroundStyle(.secondary).frame(width: 118, alignment: .leading).help(Help.term(title) ?? "")
            Text(name(p.lord)).fontWeight(.semibold).foregroundStyle(Tint.graha(p.lord)).frame(width: 70, alignment: .leading)
            ProgressView(value: done).frame(width: 110).help("\(Int(done * 100)) percent of this period has passed")
            Text("\(Names.date(julianDay: max(p.start, chart.jd)).formatted(format)) – \(Names.date(julianDay: p.end).formatted(format))").foregroundStyle(.secondary).monospacedDigit()
        }
        .contentShape(Rectangle())
        .onTapGesture { store.pick = .period(lords: lords, start: p.start, end: p.end) }
    }

    /// what a period's lord is in this chart: what it rules, where it stands, and what speaks for and against it
    @ViewBuilder private func lord(_ code: String, role: String) -> some View {
        if let g = chart.graha(code) {
            let ruled = chart.housesRuled(by: code), house = chart.house(ofSign: g.sign), weighed = chart.factors(for: g)
            let node = code == "Ra" || code == "Ke", host = Chart.signLords[g.sign]
            let with = chart.grahas.filter { $0.sign == g.sign && $0.id != code }
            VStack(alignment: .leading, spacing: 4) {
                HStack { heading("\(name(code)), lord of the \(role)"); chip(code) }
                words(Help.graha(code))
                if node {
                    words("\(name(code)) rules no sign. It gives through \(name(host)), the lord of the sign it stands in\(with.isEmpty ? "" : ", and through \(with.map { name($0.id) }.joined(separator: " and ")), which it stands with"). It stands in the \(Chart.ordinal(house)) house.")
                    HStack { chip(host); ForEach(with) { chip($0.id) }; houseChip(house) }
                } else {
                    words("It rules the \(ruled.map(Chart.ordinal).joined(separator: " and ")) and stands in the \(Chart.ordinal(house)), in \(Names.signs[g.sign]). In its periods the matters of these houses come forward.")
                    HStack { ForEach(Array(Set(ruled + [house])).sorted(), id: \.self) { houseChip($0) } }
                }
                ForEach(weighed.supports, id: \.self) { Label($0, systemImage: "plus.circle").font(.callout).foregroundStyle(.green).labelStyle(FactLabel()) }
                ForEach(weighed.strains, id: \.self) { Label($0, systemImage: "minus.circle").font(.callout).foregroundStyle(.orange).labelStyle(FactLabel()) }
            }
        }
    }

    /// where a slow graha is passing at the moment, against the birth chart
    private func passing(_ code: String, _ sky: Chart) -> String? {
        guard let g = sky.graha(code), let moon = chart.graha("Mo") else { return nil }
        let fromMoon = (g.sign - moon.sign + 12) % 12 + 1, bindus = chart.sarva[g.sign]
        var text = "\(name(code)) is passing through \(Names.signs[g.sign])\(g.retro && code != "Ra" ? ", retrograde" : ""): the \(Chart.ordinal(chart.house(ofSign: g.sign))) from the lagna and the \(Chart.ordinal(fromMoon)) from the Moon, a sign holding \(bindus) bindus (\(bindus >= 30 ? "well supported" : bindus <= 24 ? "lightly supported" : "about average"))."
        if code == "Ju" || code == "Sa" {
            let reached = (code == "Ju" ? [5, 7, 9] : [3, 7, 10]).map { Chart.ordinal(chart.house(ofSign: (g.sign + $0 - 1) % 12)) }
            let reach = "\(reached[0]), \(reached[1]) and \(reached[2])"
            let natal = chart.graha(code).flatMap { chart.weakness($0) }
            text += " From there it aspects the \(reach) houses. \(code == "Ju" ? "Jupiter's passage is read as easing the houses it touches" : "Saturn's passage is read as asking for work and patience in the houses it touches")\(natal.map { ", in the measure of its place at birth, where it is \($0)" } ?? "")."
        }
        if code == "Sa", [12, 1, 2].contains(fromMoon) { text += " This is Sade Sati, Saturn's passage over the Moon: a season for maturing and consolidating." }
        if code == "Sa", [4, 8].contains(fromMoon) { text += " Saturn in the \(Chart.ordinal(fromMoon)) from the Moon is a passage traditionally read as a time to simplify and build resilience." }
        return text
    }

    /// a period lord in transit, read as Phaladipika's chapter on dashas has it: by the sign it passes, against its strength at birth
    private func lordPassing(_ code: String, role: String, _ sky: Chart) -> String? {
        guard !(["Ra", "Ke"].contains(code)), let now = sky.graha(code), let natal = chart.graha(code) else { return nil }
        let house = Chart.ordinal(chart.house(ofSign: now.sign)), status = now.status ?? ""
        var text = "\(name(code)), lord of the \(role), is passing through \(Names.signs[now.sign]), the \(house) house from the lagna."
        let hard = ["Debil.", "Enemy", "Grt.En."].contains(status) || now.combust == true
        let good = ["Exalt.", "Own", "Grt.Fr.", "Friend"].contains(status) || (now.retro && !["Su", "Mo"].contains(code))
        if hard { text += " It is \(sky.weakness(now) ?? "under strain") there: a period lord so placed in transit is read as a stretch that asks more in the matters of the \(house) house." }
        else if good {
            let how = status == "Exalt." ? "exalted" : status == "Own" ? "in its own sign" : ["Grt.Fr.", "Friend"].contains(status) ? "in a friend's sign" : "retrograde"
            text += " It is \(how) there, which is read as bringing the \(house) house forward"
            text += chart.weakness(natal).map { "; the verse adds that the graha be strong at birth as well, and at birth it is \($0), so the help comes in smaller measure." } ?? ", the more so as it is not weakened at birth."
        }
        if now.sign == natal.sign { text += " It is passing over its own place in the birth chart, which is read as waking what it promises there." }
        return text
    }

    var body: some View {
        let day = store.viewDay ?? chart.jd
        let running = Vimshottari.running(at: day, in: chart.dasha, depth: 3)
        let titles = ["Mahadasha", "Antardasha", "Pratyantardasha"], roles = ["mahadasha", "antardasha", "pratyantardasha"]
        VStack(alignment: .leading, spacing: 10) {
            if running.isEmpty {
                Text("This moment lies outside the 120 years of the Vimshottari cycle.").foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(running.indices, id: \.self) { index in level(titles[index], running.prefix(index + 1).map(\.lord), running[index], day) }
                }
                if running.count > 1 {
                    let format = Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: store.zone)
                    let next = Vimshottari.parts(of: running[0]).first { $0.start >= running[1].end - 0.0001 }
                    HStack(spacing: 8) {
                        Text("The antardasha ends on \(Names.date(julianDay: running[1].end).formatted(format))\(next.map { ", and \(name($0.lord))'s begins" } ?? ", with the mahadasha").").foregroundStyle(.secondary)
                        Button("Go there") { store.go(to: running[1].end + 0.001) }.controlSize(.small).help("Move the whole desk to that day")
                    }
                }
                Divider()
                lord(running[0].lord, role: roles[0])
                if running.count > 1, running[1].lord != running[0].lord {
                    Divider()
                    lord(running[1].lord, role: roles[1])
                    if let a = chart.graha(running[0].lord), let b = chart.graha(running[1].lord) {
                        heading("The two lords together")
                        words("\(name(b.id)) stands \(Chart.ordinal((b.sign - a.sign + 12) % 12 + 1)) from \(name(a.id)): they are \(Lore.mutual((b.sign - a.sign + 12) % 12 + 1)). \(Lore.regard(a.id, b.id) ?? "")")
                    }
                }
                Divider()
                heading(store.sky == nil ? "What is passing" : "What is passing at this moment")
                if let sky = store.sky {
                    if let text = lordPassing(running[0].lord, role: roles[0], sky) { words(text) }
                    if running.count > 1, running[1].lord != running[0].lord, let text = lordPassing(running[1].lord, role: roles[1], sky) { words(text) }
                    ForEach(["Sa", "Ju", "Ra"], id: \.self) { code in if let text = passing(code, sky) { words(text) } }
                    GoLink(title: "Open Transits", workspace: "Transits")
                } else {
                    HStack {
                        Text("The desk stands at the birth, so there is no later sky to show.").foregroundStyle(.secondary)
                        Button("Go to now") { store.goNow() }.controlSize(.small)
                    }
                }
                Text("A period brings forward what its lord holds in the chart; transits act within what the period allows. " + Lore.balance).font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
