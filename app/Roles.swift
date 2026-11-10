import SwiftUI

/// What published readings draw on beyond a graha's sign and house: how it stands in the navamsa, whether it is
/// hemmed in, the roles its houses give it, and what it signifies by nature.
extension Lore {
    static let exalted: [String: Int] = ["Su": 0, "Mo": 1, "Ma": 9, "Me": 5, "Ju": 3, "Ve": 11, "Sa": 6]

    /// what each graha signifies by nature, whatever houses it rules
    static let signifies: [String: String] = [
        "Su": "the self and vitality, the father, authority, government, the eyes and the heart",
        "Mo": "the mind and feeling, the mother, the public, nourishment, travel over water",
        "Ma": "courage and energy, younger siblings, land and property, surgery, engineering",
        "Me": "speech and intellect, learning, trade, writing, friends, the nervous system",
        "Ju": "wisdom and teachers, children, wealth, law, dharma, the husband in a woman's chart",
        "Ve": "love and marriage, the arts and music, comfort, vehicles, the wife in a man's chart",
        "Sa": "discipline and endurance, service, labour, longevity, elders, what is built slowly",
        "Ra": "ambition, the foreign and the unconventional, technology, sudden turns",
        "Ke": "detachment and insight, liberation, the past, the occult, what is let go",
    ]
}

extension Chart {
    /// how a graha stands in its navamsa sign: exalted, in its own sign, debilitated, or nothing marked
    func navamsaStanding(_ g: Graha) -> (word: String, helps: Bool)? {
        guard let high = Lore.exalted[g.id] else { return nil }
        if g.navamsa == high { return ("exalted", true) }
        if g.navamsa == (high + 6) % 12 { return ("debilitated", false) }
        if Chart.signLords[g.navamsa] == g.id { return ("its own sign", true) }
        return nil
    }

    /// the grahas in the signs on either side of a sign, as the kartari yogas read them
    func hemming(of sign: Int, except code: String) -> (word: String, who: [String], helps: Bool)? {
        let fair = ["Mo", "Me", "Ju", "Ve"], harsh = ["Su", "Ma", "Sa", "Ra", "Ke"]
        let before = grahas.filter { $0.sign == (sign + 11) % 12 && $0.id != code }.map(\.id), after = grahas.filter { $0.sign == (sign + 1) % 12 && $0.id != code }.map(\.id)
        let harshBoth = before.contains(where: harsh.contains) && after.contains(where: harsh.contains)
        let fairBoth = before.contains(where: fair.contains) && after.contains(where: fair.contains)
        if harshBoth && !fairBoth { return ("Papa-kartari", (before + after).filter(harsh.contains), false) }
        if fairBoth && !harshBoth { return ("Shubha-kartari", (before + after).filter(fair.contains), true) }
        return nil
    }

    /// the roles a graha takes from the houses it rules in this chart
    func roles(of code: String) -> [String] {
        let ruled = housesRuled(by: code)
        var list: [String] = []
        if ruled.contains(1) { list.append("lagna lord") }
        if !ruled.contains(1), ruled.contains(where: [4, 7, 10].contains), ruled.contains(where: [5, 9].contains) { list.append("yogakaraka") }
        if ruled.contains(where: [5, 9].contains) { list.append("trikona lord") }
        if ruled.contains(where: [4, 7, 10].contains) { list.append("kendra lord") }
        if ruled.contains(11) { list.append("lord of gains") }
        if ruled.contains(where: [6, 8, 12].contains) { list.append("dusthana lord") }
        if ruled.contains(where: [2, 7].contains) { list.append("maraka") }
        return list
    }

    func explainNavamsa(_ g: Graha) -> Explanation {
        let who = Names.lords[g.id] ?? g.name, standing = navamsaStanding(g)
        var lines = ["The navamsa (D9) divides each sign into nine parts. \(who) falls in \(Names.signs[g.navamsa]) there. Readers look at the navamsa to see how a graha holds up in depth: what it delivers in the long run, and in partnership."]
        if g.navamsa == g.sign { lines.append("Vargottama: \(who) is in the same sign in the birth chart and the navamsa, which is read as steadiness and strength.") }
        switch standing?.word {
        case "exalted": lines.append("\(who) is exalted in the navamsa: whatever its place in the birth chart, it carries inner strength that shows more with time.")
        case "its own sign": lines.append("\(who) is in its own sign in the navamsa: it stands on its own ground beneath the surface.")
        case "debilitated": lines.append("\(who) is debilitated in the navamsa. Readers take this as a graha whose outer promise asks for inner work: its results come as what is learned, and grow with effort.")
        default: lines.append("\(who) is neither exalted, in its own sign, nor debilitated in the navamsa.")
        }
        return Explanation(title: "\(who) in the navamsa: \(Names.signs[g.navamsa])", group: "Navamsa (D9)", lines: lines, workspace: "Vargas", term: "Navamsa")
    }

    func explainHemming(_ g: Graha) -> Explanation? {
        guard let hem = hemming(of: g.sign, except: g.id) else { return nil }
        let who = Names.lords[g.id] ?? g.name, names = hem.who.map { Names.lords[$0] ?? $0 }.joined(separator: ", ")
        return Explanation(title: "\(who): \(hem.word)", group: "Kartari yoga", lines: [
            "Kartari means scissors: a graha with others in the signs on both sides of it is read as held between them.",
            hem.helps ? "\(who) stands between benefics (\(names)). Shubha-kartari is read as support and protection for what \(who) carries."
                      : "\(who) stands between malefics (\(names)). Papa-kartari is read as pressure on what \(who) carries: its matters ask for clear boundaries, and build resilience.",
        ], workspace: "Yogas")
    }

    func explainRoles(_ code: String) -> Explanation {
        let who = Names.lords[code] ?? code, ruled = housesRuled(by: code), roles = self.roles(of: code)
        let words: [String: String] = [
            "lagna lord": "Lagna lord: it stands for the person as a whole, and its condition colours everything.",
            "yogakaraka": "Yogakaraka: it rules both an angle and a trine, and so joins action with fortune. Its periods are read as the chart's most productive.",
            "trikona lord": "Trikona lord (5th or 9th): it carries merit, intelligence and fortune, and is read as helpful wherever it stands.",
            "kendra lord": "Kendra lord (4th, 7th or 10th): it carries the weight of home, partnership or work.",
            "lord of gains": "Lord of gains (11th): it brings income and fulfilment of aims, and asks that desire be kept in measure.",
            "dusthana lord": "Dusthana lord (6th, 8th or 12th): it carries effort, change or release. Its periods ask more, and are where capacity is built.",
            "maraka": "Maraka (lord of the 2nd or 7th): the tradition reads its periods for endings and turning points, and late in life for care of health. In most of life it simply acts as the lord of family and resources, or of partnership.",
        ]
        var lines = [ruled.isEmpty ? "\(who) rules no sign, so it takes its role from the lord of the sign it stands in and from the grahas it stands with."
                                   : "\(who) rules the \(ruled.map { "\(Chart.ordinal($0)) (\(Lore.houseNames[$0 - 1].lowercased()))" }.joined(separator: " and ")) in this chart. A graha acts for the houses it rules as well as by its own nature."]
        lines += roles.compactMap { words[$0] }
        return Explanation(title: "\(who): the roles its houses give it", group: "Functional nature", lines: lines)
    }

    func explainSignifies(_ code: String) -> Explanation {
        let who = Names.lords[code] ?? code
        return Explanation(title: "What \(who) signifies", group: "Karaka", lines: [
            "By nature, in every chart, \(who) signifies \(Lore.signifies[code] ?? "").",
            "A karaka is a natural significator. Readers judge a matter twice: from the house and its lord, and from the karaka. Marriage, for instance, is read from the 7th house and from Venus.",
        ])
    }
}

/// A dated event of a life, kept with the chart.
struct LifeEvent: Codable, Identifiable, Hashable {
    var id = UUID()
    var date = ""
    var note = ""
}

/// Dated events of the life, each set against the periods that were running: how published readings test a
/// chart against what happened, and how a birth time is checked.
struct EventsCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart
    /// the slow grahas' places on each event's day, read from the engine once per date
    @State private var skies: [String: String] = [:]

    /// Where Saturn, Jupiter and Rahu stood that day, counted from the birth lagna and the birth Moon.
    private func readSky(_ date: String, _ day: Double) {
        guard skies[date] == nil, let birth = store.birth, let moon = chart.graha("Mo") else { return }
        let engine = store.engine, node = store.node, ayanamsa = store.ayanamsa, natal = chart
        let hours = Double(store.zone.secondsFromGMT(for: Names.date(julianDay: day))) / 3600
        Task.detached {
            guard let sky = try? engine.chart(julianDay: day, latitude: birth.latitude, longitude: birth.longitude, node: node, ayanamsa: ayanamsa, zoneHours: hours) else { return }
            let words = ["Sa", "Ju", "Ra"].compactMap { code -> String? in
                guard let g = sky.graha(code) else { return nil }
                let fromMoon = (g.sign - moon.sign + 12) % 12 + 1
                var text = "\(Names.lords[code] ?? code) in \(Names.signs[g.sign]), the \(Chart.ordinal(natal.house(ofSign: g.sign))) from the lagna and the \(Chart.ordinal(fromMoon)) from the Moon"
                if code == "Sa", [12, 1, 2].contains(fromMoon) { text += " (Sade Sati)" }
                return text
            }.joined(separator: "; ")
            await MainActor.run { skies[date] = "In the sky that day: " + words + "." }
        }
    }
    private func julianDay(_ text: String) -> Double? {
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, (1...12).contains(parts[1]), (1...31).contains(parts[2]) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = store.zone
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12)).map { $0.timeIntervalSince1970 / 86400 + 2440587.5 }
    }

    private func name(_ code: String) -> String { Names.lords[code] ?? code }

    var body: some View {
        if let index = store.index {
            let events = Binding(get: { store.births[index].events ?? [] }, set: { store.births[index].events = $0 })
            VStack(alignment: .leading, spacing: 8) {
                ForEach(events) { $event in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            TextField("YYYY-MM-DD", text: $event.date).frame(width: 104)
                            TextField("What happened", text: $event.note)
                            Button { events.wrappedValue.removeAll { $0.id == event.id } } label: { Image(systemName: "minus.circle") }
                                .buttonStyle(.plain).foregroundStyle(.secondary).help("Remove this event")
                        }
                        .textFieldStyle(.roundedBorder)
                        if let day = julianDay(event.date) {
                            let running = Vimshottari.running(at: day, in: chart.dasha, depth: 3)
                            if running.isEmpty || day < chart.jd {
                                Text("This date lies outside the life the chart covers.").font(.callout).foregroundStyle(.secondary)
                            } else {
                                HStack(spacing: 6) {
                                    ForEach(Array(running.enumerated()), id: \.offset) { level, period in
                                        if level > 0 { Text("–").foregroundStyle(.secondary) }
                                        Button(name(period.lord)) { store.pick = .graha(period.lord) }.buttonStyle(.bordered).controlSize(.small).tint(Tint.graha(period.lord)).help(Help.graha(period.lord))
                                    }
                                    Text("age \(Vimshottari.span(days: day - chart.jd))").foregroundStyle(.secondary)
                                    Button("Go there") { store.go(to: day) }.controlSize(.small).help("Move the whole desk to this day")
                                }
                                // the antardasha's lord is said once when it is the mahadasha's own
                                Text(running.prefix(2).enumerated().filter { $0.offset == 0 || $0.element.lord != running[0].lord }.map(\.element).map { p in
                                    let ruled = chart.housesRuled(by: p.lord), at = chart.graha(p.lord).map { chart.house(ofSign: $0.sign) }
                                    return "\(name(p.lord)) \(ruled.isEmpty ? "rules no house" : "rules the " + ruled.map(Chart.ordinal).joined(separator: " and "))\(at.map { ", stands in the \(Chart.ordinal($0))" } ?? "")"
                                }.joined(separator: ". ") + ".")
                                .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                                if let sky = skies[event.date] { Text(sky).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
                                Color.clear.frame(height: 0).onAppear { readSky(event.date, day) }.onChanged(of: event.date) { readSky(event.date, day) }
                            }
                        } else if !event.date.isEmpty {
                            Text("The date reads as year-month-day, such as 1999-06-21.").font(.callout).foregroundStyle(.orange)
                        }
                    }
                }
                Button { events.wrappedValue.append(LifeEvent()) } label: { Label("Add an event", systemImage: "plus") }
                Text("Enter dates you know: a marriage, a move, a new work, a loss. Each shows the mahadasha, antardasha and pratyantardasha running that day, and what their lords rule. Events that fall under fitting lords speak for the birth time; a run of misfits is a reason to try Rectify. " + Lore.balance)
                    .font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
