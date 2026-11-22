import SwiftUI

/// Chart Prep Pro Forma A: the Level 1 chart preparation of Vedic Traditions (Steven Highburger), followed
/// heading by heading and in its order, each prompt answered from the chart on the desk.
///
///   Static analysis, potential:   1. Yoga vichara   2. Lagna vichara   3. Bhava vichara
///   Dynamic analysis, timing:     4. Dasha-bhukti vichara   5. Gochara vichara
///
/// The card adds no step of its own. Where a prompt names a judgement (a graha's condition, a house's three
/// limbs), it calls the same rules the other desks use, so the answers agree with them.
struct ProFormaCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart
    /// the matter step 3 looks at: a house, chosen by the reader
    @State private var matter = 1
    /// the sky of now, read here while the time bar stands at the birth
    @State private var now: Chart?
    @State private var readAt: Date?

    private let wide: CGFloat = 980
    private func name(_ code: String) -> String { Names.lords[code] ?? code }
    private func ord(_ n: Int) -> String { Chart.ordinal(n) }
    private func houses(_ list: [Int]) -> String { list.isEmpty ? "none" : list.map(ord).joined(separator: ", ") }

    // MARK: the moment the timing is read for

    /// the time bar's moment when it stands away from the birth, else today
    private var day: Double { store.moment.map { $0.timeIntervalSince1970 / 86400 + 2440587.5 } ?? Date().timeIntervalSince1970 / 86400 + 2440587.5 }
    private var sky: Chart? { store.moment == nil ? now : store.sky }
    private var key: String { "\(chart.jd) \(store.node) \(store.ayanamsa) \(store.here?.place ?? "") \(store.moment == nil)" }

    private func readNow() async {
        guard store.moment == nil, let birth = store.birth else { return }
        let engine = store.engine, node = store.node, ayanamsa = store.ayanamsa, at = Date()
        let zoneHours = Double(store.skyZone.secondsFromGMT(for: at)) / 3600, jd = at.timeIntervalSince1970 / 86400 + 2440587.5
        let latitude = store.here?.latitude ?? birth.latitude, longitude = store.here?.longitude ?? birth.longitude
        let result = await Task.detached { Result { try engine.chart(julianDay: jd, latitude: latitude, longitude: longitude, node: node, ayanamsa: ayanamsa, zoneHours: zoneHours) } }.value
        if case .success(let read) = result { now = read; readAt = at }
    }

    // MARK: the pieces every step is written with

    private func part(_ title: String) -> some View {
        Text(title).font(.title3).fontWeight(.bold).underline().padding(.top, 14)
    }
    private func step(_ number: Int, _ title: String) -> some View {
        Text("\(number). \(title)").font(.title3).fontWeight(.semibold).foregroundStyle(Color.orange).padding(.top, 10)
    }
    private func group(_ title: String) -> some View {
        Text(title).font(.headline).padding(.top, 4)
    }
    private func prompt(_ numeral: String, _ words: String) -> some View {
        Text("\(numeral)  \(words)").font(.callout).fontWeight(.semibold).padding(.top, 6).padding(.leading, 14)
    }
    private func answer(_ words: String) -> some View {
        Text(words).font(.callout).fixedSize(horizontal: false, vertical: true).frame(maxWidth: wide - 40, alignment: .leading).padding(.leading, 40)
    }
    private func answer(_ head: String, _ words: String) -> some View {
        (Text(head + " ").fontWeight(.semibold) + Text(words)).font(.callout).fixedSize(horizontal: false, vertical: true).frame(maxWidth: wide - 40, alignment: .leading).padding(.leading, 40)
    }
    private func table(_ heads: [String], _ widths: [CGFloat], _ rows: [(graha: String?, cells: [SheetCell])]) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            SheetRow(graha: nil, cells: zip(heads, widths).map { SheetCell(text: $0, width: $1, header: true) })
            ForEach(rows.indices, id: \.self) { SheetRow(graha: rows[$0].graha, cells: rows[$0].cells) }
        }
        .padding(.leading, 40)
    }

    /// a graha's condition in the words of the strength rules: the primary and secondary factors it meets
    private func condition(_ code: String) -> String {
        guard let g = chart.graha(code) else { return "" }
        let k = chart.keyFactors(g)
        let lines = [("Primary strength", k.primaryStrength), ("Primary weakness", k.primaryWeakness), ("Secondary strength", k.secondaryStrength), ("Secondary weakness", k.secondaryWeakness)]
            .filter { !$0.1.isEmpty }.map { "\($0.0): \($0.1.joined(separator: "; "))" }
        return lines.isEmpty ? "No primary or secondary factor marked" : lines.joined(separator: "\n")
    }
    private func location(_ code: String) -> String {
        guard let g = chart.graha(code) else { return "" }
        return "The \(ord(chart.house(ofSign: g.sign))) house, \(Names.signs[g.sign]) (\(chart.placing(code)))"
    }
    private func ownership(_ code: String) -> String {
        let ruled = chart.housesRuled(by: code)
        return ruled.isEmpty ? "Rules no house; it acts through the lord of its sign" : "Lord of the \(houses(ruled))"
    }
    private func karaka(_ code: String) -> String {
        let of = (1...12).filter { h in Lore.houseKarakas[h - 1].contains { $0.code == code } }
        let matters = of.flatMap { h in Lore.houseKarakas[h - 1].filter { $0.code == code }.map { "\($0.matter) (\(ord(h)))" } }
        return [Lore.signifies[code].map { $0.prefix(1).uppercased() + $0.dropFirst() }, matters.isEmpty ? nil : "House karaka for " + matters.joined(separator: ", ")].compactMap { $0 }.joined(separator: "\n")
    }
    private func aspects(_ code: String) -> String {
        guard let g = chart.graha(code) else { return "" }
        let cast = chart.aspectedSigns(by: code).map { chart.house(ofSign: $0) }.sorted()
        let with = chart.grahas.filter { $0.sign == g.sign && $0.id != code }.map { name($0.id) }
        let seenBy = chart.aspecting(sign: g.sign).filter { $0 != code && chart.graha($0)?.sign != g.sign }.map(name)
        return ["Aspects the \(houses(cast))" + (cast.isEmpty ? " (the nodes cast no aspect here)" : " house\(cast.count > 1 ? "s" : "")"),
                "Joined by: " + (with.isEmpty ? "none" : with.joined(separator: ", ")), "Aspected by: " + (seenBy.isEmpty ? "none" : seenBy.joined(separator: ", "))].joined(separator: "\n")
    }

    // MARK: 1. Yoga vichara

    private var yogaGrahas: [String] { chart.grahas.map(\.id).filter { code in chart.yogas.contains { $0.grahas.contains(code) } } }

    @ViewBuilder private var yogaVichara: some View {
        step(1, "Yoga Vichara")
        prompt("i.", "Identify – make list")
        if chart.yogas.isEmpty { answer("No yoga of the app's set is formed in this chart.") }
        table(["Yoga", "Grahas", "The rule it met"], [220, 150, 570], chart.yogas.map { yoga in
            (nil, [SheetCell(text: yoga.name + (Lore.yogaBeyondBook(yoga.name) ? " *" : ""), width: 220, met: true),
                   SheetCell(text: yoga.grahas.isEmpty ? "—" : yoga.grahas.map(name).joined(separator: ", "), width: 150),
                   SheetCell(text: yoga.why, width: 570)]) })
        if chart.yogas.contains(where: { Lore.yogaBeyondBook($0.name) }) { answer("* a yoga Light on Life does not name.").foregroundStyle(.secondary) }
        prompt("ii.", "Assess condition and placement")
        table(["Graha", "Yogas it forms", "Condition", "Placement"], [80, 220, 440, 200], yogaGrahas.map { code in
            (code, [SheetCell(text: name(code), width: 80, tint: Tint.graha(code)),
                    SheetCell(text: chart.yogas.filter { $0.grahas.contains(code) }.map(\.name).joined(separator: "\n"), width: 220),
                    SheetCell(text: condition(code), width: 440),
                    SheetCell(text: location(code), width: 200)]) })
        prompt("iii.", "Look at location, ownership and as Karaka")
        table(["Graha", "Location", "Ownership", "As karaka"], [80, 220, 200, 440], yogaGrahas.map { code in
            (code, [SheetCell(text: name(code), width: 80, tint: Tint.graha(code)),
                    SheetCell(text: location(code), width: 220),
                    SheetCell(text: ownership(code) + "\n" + chart.temporalWord(code), width: 200),
                    SheetCell(text: karaka(code), width: 440)]) })
    }

    // MARK: 2. Lagna vichara

    private func nakshatra(_ who: String, _ index: Int, _ nakName: String, _ pada: Int) -> String {
        let lord = Lore.nakshatraLords[index % 9]
        return "\(who) in \(nakName) (\(Lore.nakshatraMeanings[index])), pada \(pada). Ruled by \(name(lord)), which stands \(chart.placing(lord)). \(Lore.nakshatra(index))"
    }

    @ViewBuilder private var lagnaVichara: some View {
        let lagna = chart.asc.sign, code = chart.lord(ofHouse: 1), lore = Lore.lagnaLore[lagna]
        let inLagna = chart.grahas.filter { $0.sign == lagna }.map { name($0.id) }, onLagna = chart.aspecting(sign: lagna).filter { chart.graha($0)?.sign != lagna }.map(name)
        step(2, "Lagna Vichara")
        group("Strength and Placement")
        prompt("i.", "Condition of the Lagnesha/Lagna")
        answer("Lagnesha:", "\(name(code)), lord of \(Names.signs[lagna]). \(location(code)). \(ownership(code)).")
        answer(condition(code))
        answer("Lagna:", "\(Names.signs[lagna]) at \(Names.dms(chart.asc.deg)). In it: \(inLagna.isEmpty ? "no graha" : inLagna.joined(separator: ", ")). Aspected by: \(onLagna.isEmpty ? "none" : onLagna.joined(separator: ", "))."
               + (chart.hemming(of: lagna, except: "").map { " \($0.word): flanked by \($0.who.map(name).joined(separator: " and "))." } ?? ""))
        group("Nature and Universal Qualities")
        prompt("i.", "Five principles p.153 LOL – Symbolism of rashi/ruler, etc…")
        answer("1. The symbol of the rashi.", "\(Names.signs[lagna]) (\(Names.signsWestern[lagna])), a \(Lore.modes[lagna % 3]) \(Lore.elements[lagna % 4]) rashi. \(lore.image). Its people: \(lore.traits.joined(separator: "; ")). At its hardest: \(lore.hardest).")
        answer("2. Its ruler.", "\(name(code)): \(Lore.grahaMeanings[code]?.essence ?? ""). It \(lore.verb).")
        answer("3. The strength of the grahas in its houses.", chart.grahas.prefix(7).map { g in
            let k = chart.keyFactors(g), mark = !k.primaryStrength.isEmpty && k.primaryWeakness.isEmpty ? "strong" : k.primaryStrength.isEmpty && !k.primaryWeakness.isEmpty ? "weak" : !k.primaryStrength.isEmpty ? "mixed" : "middling"
            return "\(name(g.id)) in the \(ord(chart.house(ofSign: g.sign))), \(mark)" }.joined(separator: "; ") + ".")
        answer("4. The lagna lord's regard for the other house lords.", (2...12).map { h -> String in
            let other = chart.lord(ofHouse: h), regard = Lore.natural[code]?[other]
            return "\(ord(h)) \(name(other)): " + (other == code ? "itself" : regard == nil ? "none set" : regard! > 0 ? "friend" : regard! < 0 ? "enemy" : "neutral") }.joined(separator: "; ") + ".")
        answer("5. Which houses each graha rules.", chart.grahas.prefix(7).map { "\(name($0.id)): \(houses(chart.housesRuled(by: $0.id))) (\(chart.temporalWord($0.id)))" }.joined(separator: "; ") + ".")
        prompt("ii.", "Nakshatras – especially of Lagna and MO")
        answer(nakshatra("The lagna stands", chart.asc.nak, chart.asc.nak_name, chart.asc.pada))
        if let moon = chart.graha("Mo") { answer(nakshatra("The Moon stands", moon.nak, moon.nak_name, moon.pada)) }
    }

    // MARK: 3. Bhava vichara

    @ViewBuilder private var bhavaVichara: some View {
        step(3, "Bhava Vichara")
        prompt("i.", "Bhava/Lord/Karaka – for any specific matter")
        HStack {
            Text("The matter:").font(.callout)
            Picker("The matter", selection: $matter) {
                ForEach(1...12, id: \.self) { h in Text("\(ord(h)) house · \(Lore.houseNames[h - 1]): \(Lore.houses[h - 1])").tag(h) }
            }
            .labelsHidden().frame(maxWidth: 560)
        }
        .padding(.leading, 40)
        .help("Choose the house the question belongs to; its bhava, its lord and its karaka are judged below")
        HouseJudgement(chart: chart, house: matter).frame(maxWidth: wide - 40, alignment: .leading).padding(.leading, 40)
        answer(chart.confluence(ofHouse: matter) + chart.weighed(ofHouse: matter).words)
    }

    // MARK: 4. Dasha-bhukti vichara

    @ViewBuilder private func lord(_ role: String, _ period: Period) -> some View {
        let code = period.lord, format = Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: store.zone)
        let mine = chart.yogas.filter { $0.grahas.contains(code) }.map(\.name)
        answer("\(role): \(name(code)),", "\(Names.date(julianDay: period.start).formatted(format)) to \(Names.date(julianDay: period.end).formatted(format)).").padding(.top, 4)
        prompt("i.", "Daśā lord's condition and Yogas")
        answer(condition(code))
        answer("Yogas:", mine.isEmpty ? "it takes part in none." : mine.joined(separator: "; ") + ".")
        prompt("ii.", "Inherent Effect: as NB/NM, TB/TM and Kāraka")
        answer("NB/NM:", "a natural \(chart.benefic(code) ? "benefic" : "malefic")\(code == "Mo" ? " (the Moon by its light: \(chart.moonWaxing ? "waxing" : "waning"))" : code == "Me" ? " (Mercury by its company)" : "").")
        answer("TB/TM:", chart.housesRuled(by: code).isEmpty ? "it rules no house; read it through \(name(Chart.signLords[chart.graha(code)?.sign ?? 0])), lord of its sign." : chart.temporalWord(code) + ".")
        answer("Kāraka:", karaka(code).replacingOccurrences(of: "\n", with: ". ") + ".")
        prompt("iii.", "Position: location, ownership and aspects")
        answer("Location:", location(code) + ".")
        answer("Ownership:", ownership(code) + ".")
        answer("Aspects:", aspects(code).replacingOccurrences(of: "\n", with: ". ") + ".")
    }

    @ViewBuilder private var dashaVichara: some View {
        let running = Vimshottari.running(at: day, in: chart.dasha, depth: 2)
        step(4, "Daśā-Bhukti Vichara")
        if running.count == 2 {
            lord("Daśā lord (DL)", running[0])
            lord("Bhukti lord (BL)", running[1])
        } else {
            answer("No Vimshottari period holds this moment.")
        }
    }

    // MARK: 5. Gochara vichara

    private func passing(_ code: String, _ role: String, _ sky: Chart) -> String {
        if let words = chart.periodLordPassing(code, role: role, sky: sky) { return words }
        guard let g = sky.graha(code) else { return "" }
        return "\(name(code)), lord of the \(role), is passing through \(Names.signs[g.sign]), the \(ord(chart.house(ofSign: g.sign))) house from the lagna."
    }
    /// the transiting grahas now on a birth position, or aspecting it
    private func reactivation(_ code: String, _ sky: Chart) -> String {
        guard let natal = chart.graha(code) else { return "" }
        let offsets: [String: [Int]] = ["Ma": [3, 6, 7], "Ju": [4, 6, 8], "Sa": [2, 6, 9]]
        let on = sky.grahas.filter { $0.sign == natal.sign && Lore.exalted[$0.id] != nil || $0.sign == natal.sign && ["Ra", "Ke"].contains($0.id) }.map(\.id)
        let seeing = sky.grahas.filter { g in Lore.exalted[g.id] != nil && g.sign != natal.sign && (offsets[g.id] ?? [6]).contains { (g.sign + $0) % 12 == natal.sign } }.map(\.id)
        var text = "\(name(code)) stands at birth in \(Names.signs[natal.sign]), the \(ord(chart.house(ofSign: natal.sign))) house. "
        text += on.isEmpty ? "No graha is passing over it. " : "Passing over it now: \(on.map(name).joined(separator: ", "))\(on.contains(code) ? " (\(name(code)) itself has returned to its birth sign)" : ""). "
        text += seeing.isEmpty ? "None aspects it by transit." : "Aspecting it by transit: \(seeing.map(name).joined(separator: ", "))."
        return text
    }

    @ViewBuilder private var gocharaVichara: some View {
        let running = Vimshottari.running(at: day, in: chart.dasha, depth: 2)
        step(5, "Gocara Vichara")
        if let sky, running.count == 2 {
            prompt("i.", "DL/BL placement by transit")
            answer("DL:", passing(running[0].lord, "daśā", sky))
            answer("BL:", passing(running[1].lord, "bhukti", sky))
            prompt("ii.", "Reactivation of natal position")
            answer("DL:", reactivation(running[0].lord, sky))
            if running[1].lord != running[0].lord { answer("BL:", reactivation(running[1].lord, sky)) }
        } else {
            answer("Reading the sky…").foregroundStyle(.secondary)
        }
    }

    var body: some View {
        let format = Date.FormatStyle(date: .abbreviated, time: .shortened, timeZone: store.skyZone)
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Level 1 – Chart Prep Pro Forma, after Steven Highburger, Vedic Traditions. Each heading below is a prompt of the pro forma, in its order; under it stands what this chart answers.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(maxWidth: wide, alignment: .leading)
                part("Static Analysis – Potential")
                yogaVichara
                lagnaVichara
                bhavaVichara
                part("Dynamic Analysis – Timing")
                Text("Read for \(store.moment == nil ? "today" : "the time bar's moment"), \((store.moment ?? readAt ?? Date()).formatted(format)). Move the time bar to read another date.")
                    .font(.caption).foregroundStyle(.secondary)
                dashaVichara
                gocharaVichara
            }
            .frame(minWidth: wide, alignment: .leading)
        }
        .task(id: key) {
            while !Task.isCancelled {
                await readNow()
                try? await Task.sleep(nanoseconds: 300_000_000_000)
            }
        }
    }
}

/// Pro Forma Rahu/Ketu: the levels by which a Rahu or Ketu dasha or bhukti is analysed, after the Level 2
/// lessons of Vedic Traditions (Steven Highburger), each level answered from the chart on the desk.
///
///   1. As a natural malefic   2. Its karakatva, the innate meanings   3. Acting like other grahas:
///      its rashi dispositor, its nakshatra dispositor, the grahas associated with it, the grahas aspecting it;
///   then one list of those grahas, sorted by their condition and by how often each one's influence repeats.
struct RahuKetuProFormaCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart
    private let wide: CGFloat = 980

    private func name(_ code: String) -> String { Names.lords[code] ?? code }
    private func ord(_ n: Int) -> String { Chart.ordinal(n) }
    private func houses(_ list: [Int]) -> String { list.isEmpty ? "no house" : "the " + list.map(ord).joined(separator: ", ") }
    private var day: Double { store.moment.map { $0.timeIntervalSince1970 / 86400 + 2440587.5 } ?? Date().timeIntervalSince1970 / 86400 + 2440587.5 }

    private func step(_ words: String) -> some View { Text(words).font(.headline).padding(.top, 8) }
    private func answer(_ words: String) -> some View {
        Text(words).font(.callout).fixedSize(horizontal: false, vertical: true).frame(maxWidth: wide - 30, alignment: .leading).padding(.leading, 30)
    }
    private func answer(_ head: String, _ words: String) -> some View {
        (Text(head + " ").fontWeight(.semibold) + Text(words)).font(.callout).fixedSize(horizontal: false, vertical: true).frame(maxWidth: wide - 30, alignment: .leading).padding(.leading, 30)
    }

    /// a graha's condition as a number and in words: primary factors count two, secondary one
    private func condition(_ code: String) -> (score: Int, words: String) {
        guard let g = chart.graha(code) else { return (0, "") }
        let k = chart.keyFactors(g), score = 2 * k.primaryStrength.count - 2 * k.primaryWeakness.count + k.secondaryStrength.count - k.secondaryWeakness.count
        let lines = [("Primary strength", k.primaryStrength), ("Primary weakness", k.primaryWeakness), ("Secondary strength", k.secondaryStrength), ("Secondary weakness", k.secondaryWeakness)]
            .filter { !$0.1.isEmpty }.map { "\($0.0): \($0.1.joined(separator: "; "))" }
        let verdict = score >= 2 ? "Strong" : score <= -2 ? "Weak" : score > 0 ? "Leans strong" : score < 0 ? "Leans weak" : "Middling"
        return (score, verdict + (lines.isEmpty ? "" : "\n" + lines.joined(separator: "\n")))
    }

    /// the four ways a node takes on other grahas, in the pro forma's order
    private func actsLike(_ node: Graha) -> [(role: String, grahas: [String])] {
        let with = chart.grahas.filter { $0.sign == node.sign && !["Ra", "Ke"].contains($0.id) && Lore.exalted[$0.id] != nil }.map(\.id)
        let seeing = chart.aspecting(sign: node.sign).filter { !with.contains($0) }
        return [("Its rashi dispositor", [Chart.signLords[node.sign]]), ("Its nakshatra dispositor", [node.nak_lord]),
                ("Grahas associated with it", with), ("Grahas aspecting it", seeing)]
    }

    /// short themes of each node, in the app's own words
    private static let themes: [String: String] = [
        "Ra": "hunger that is hard to satisfy; ambition that can run against the person's own grain, and the frustration that follows it; restless effort and reaction; strategy and control; masks and concealment, with insight once the veil lifts; foreign people, places and cultures; a pull that fascinates.",
        "Ke": "the other end of the same axis: what is already known and is let go; detachment, insight and liberation; suddenness; the hidden and the past. Like Rahu it wears the dress of the grahas it is tied to."]

    private typealias Listed = (code: String, roles: [String], state: (score: Int, words: String))

    private func stands(_ g: Graha, _ code: String) -> String {
        let format = Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: store.zone)
        let running = Vimshottari.running(at: day, in: chart.dasha, depth: 2)
        let mahas = chart.dasha.filter { $0.lord == code && $0.end > chart.jd }
        var text = "\(Names.signs[g.sign]), the \(ord(chart.house(ofSign: g.sign))) house, in \(g.nak_name) pada \(g.pada). "
        if !mahas.isEmpty {
            let spans: [String] = mahas.map { Names.date(julianDay: $0.start).formatted(format) + " to " + Names.date(julianDay: $0.end).formatted(format) }
            text += "Its daśā: " + spans.joined(separator: "; ") + ". "
        }
        if running.count == 2, running[0].lord == code { text += "Its daśā is running now. " }
        if running.count == 2, running[1].lord == code { text += "Its bhukti is running now, within \(name(running[0].lord))'s daśā, until " + Names.date(julianDay: running[1].end).formatted(format) + "." }
        return text
    }

    private func malefic(_ code: String, house: Int) -> String {
        let classes: String = Lore.houseClasses(house).map(\.name).joined(separator: ", ").lowercased()
        let kind: String = Lore.positiveHouses.contains(house) ? "a positive house, where a malefic disturbs what would otherwise be easy" : "a house that asks more, where a malefic can contain the harder side"
        return "\(name(code)) is a natural malefic. It presses on the \(ord(house)) house (\(Lore.houses[house - 1])). That house is \(classes), \(kind)."
    }

    private func meanings(_ code: String) -> String {
        let own: String = Lore.signifies[code].map { $0.prefix(1).uppercased() + $0.dropFirst() + ". " } ?? ""
        let more: String = Self.themes[code].map { $0.prefix(1).uppercased() + $0.dropFirst() } ?? ""
        return own + more
    }

    private func stance(_ other: String) -> String {
        let sign: String = chart.graha(other).map { Names.signs[$0.sign] } ?? ""
        return "\(name(other)) stands \(chart.placing(other)), in \(sign); it rules \(houses(chart.housesRuled(by: other)))."
    }

    private func listed(_ acts: [(role: String, grahas: [String])]) -> [Listed] {
        var roles: [String: [String]] = [:]
        for row in acts { for other in row.grahas { roles[other, default: []].append(row.role) } }
        let items: [Listed] = roles.map { (code: $0.key, roles: $0.value, state: condition($0.key)) }
        return items.sorted { a, b in
            if a.state.score != b.state.score { return a.state.score > b.state.score }
            if a.roles.count != b.roles.count { return a.roles.count > b.roles.count }
            return a.code < b.code
        }
    }

    private func reading(_ code: String, _ list: [Listed]) -> String? {
        guard let lead = list.max(by: { a, b in a.roles.count != b.roles.count ? a.roles.count < b.roles.count : a.state.score < b.state.score }) else { return nil }
        let times: String = lead.roles.count == 1 ? "once" : "\(lead.roles.count) times"
        let through: String = lead.roles.map { $0.lowercased() }.joined(separator: "; ")
        let state: String = lead.state.words.components(separatedBy: "\n").first?.lowercased() ?? ""
        return "\(name(code)) acts most like \(name(lead.code)), which reaches it \(times) (\(through)) and is \(state) in this chart. A node gives as the grahas it acts like are able to give: the stronger and the more often repeated, the more its period delivers in their name."
    }

    private func actsTable(_ acts: [(role: String, grahas: [String])]) -> some View {
        var rows: [(graha: String?, cells: [SheetCell])] = []
        for (index, row) in acts.enumerated() {
            if row.grahas.isEmpty {
                rows.append((nil, [SheetCell(text: "\(index + 1).", width: 28), SheetCell(text: row.role, width: 220, met: true), SheetCell(text: "none", width: 110), SheetCell(text: "—", width: 560)]))
            }
            for other in row.grahas {
                rows.append((other, [SheetCell(text: "\(index + 1).", width: 28), SheetCell(text: row.role, width: 220, met: true),
                                     SheetCell(text: name(other), width: 110, tint: Tint.graha(other)), SheetCell(text: stance(other), width: 560)]))
            }
        }
        let heads: [SheetCell] = [SheetCell(text: "", width: 28, header: true), SheetCell(text: "Acts like", width: 220, header: true), SheetCell(text: "Graha", width: 110, header: true), SheetCell(text: "Where it stands and what it rules", width: 560, header: true)]
        return VStack(alignment: .leading, spacing: 1) {
            SheetRow(graha: nil, cells: heads)
            ForEach(rows.indices, id: \.self) { SheetRow(graha: rows[$0].graha, cells: rows[$0].cells) }
        }
        .padding(.leading, 30)
    }

    private func listTable(_ list: [Listed]) -> some View {
        let heads: [SheetCell] = [SheetCell(text: "Graha", width: 110, header: true), SheetCell(text: "1. Condition", width: 420, header: true), SheetCell(text: "2. Duplication", width: 110, header: true), SheetCell(text: "Through", width: 280, header: true)]
        return VStack(alignment: .leading, spacing: 1) {
            SheetRow(graha: nil, cells: heads)
            ForEach(list, id: \.code) { item in
                SheetRow(graha: item.code, cells: [
                    SheetCell(text: name(item.code), width: 110, tint: Tint.graha(item.code)),
                    SheetCell(text: item.state.words, width: 420, met: abs(item.state.score) >= 2, helps: item.state.score >= 0),
                    SheetCell(text: item.roles.count == 1 ? "once" : "\(item.roles.count) times", width: 110, met: item.roles.count > 1),
                    SheetCell(text: item.roles.joined(separator: "\n"), width: 280)])
            }
        }
        .padding(.leading, 30)
    }

    @ViewBuilder private func node(_ code: String) -> some View {
        if let g = chart.graha(code) {
            let house: Int = chart.house(ofSign: g.sign)
            let acts = actsLike(g)
            let list: [Listed] = listed(acts)
            Text(name(code)).font(.title3).fontWeight(.semibold).foregroundStyle(Color.orange).padding(.top, 12)
            answer("Stands in", stands(g, code))
            step("1.  As a NM")
            answer(malefic(code, house: house))
            step("2.  \(name(code))'s Karaka-tva (innate meanings)")
            answer(meanings(code))
            answer("In this chart", "these meanings gather in the \(ord(house)) house: the matters of \(Lore.houseNames[house - 1].lowercased()) are where the pull, the high expectation and the blind spot are met.")
            step("3.  Along with the meanings above, it will also “act” like other grahas")
            Text("Acts like:").font(.callout).fontWeight(.semibold).padding(.leading, 30).padding(.top, 2)
            actsTable(acts)
            step("Make a list and sort by:  1. Condition of grahas   2. Duplication of influence on \(code == "Ra" ? "RA" : "KE")")
            listTable(list)
            if let words = reading(code, list) { answer("Read:", words) }
        }
    }

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 4) {
                Text("To analyse any Rahu or Ketu daśā or bhukti, several levels are looked at, in this order. After Steven Highburger, Vedic Traditions; each level is answered from this chart, for Rahu and then for Ketu.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(maxWidth: wide, alignment: .leading)
                node("Ra")
                node("Ke")
                Text("Rahu and Ketu have no mass, always stand opposite each other, cause the eclipses and own no sign or house: they give through the grahas they are tied to, which is why the list above is the heart of the reading.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).frame(maxWidth: wide, alignment: .leading).padding(.top, 10)
            }
            .frame(minWidth: wide, alignment: .leading)
        }
    }
}
