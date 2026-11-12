import SwiftUI

/// The five limbs of the birth day, read as Light on Life reads them: the weekday and the planetary hour take the
/// nature of their lords; the tithi is read by its fortnight and its joints; the karana and the soli-lunar yoga
/// are named; and a point at a gandanta, the joint of a water sign and a fire sign, is marked.
struct Limb5: Identifiable {
    let id: String
    let value: String
    let words: String
    var graha: String? = nil
}

extension Lore {
    static let weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    /// the order of the planetary hours, each hour passing to the next slower graha but two
    static let horaOrder = ["Su", "Ve", "Me", "Mo", "Sa", "Ju", "Ma"]
    /// the names of the 27 soli-lunar yogas in English
    static let yogaSense = ["supported", "fondness", "long-lived", "good fortune", "splendour", "large-cheeked", "virtuous", "determination", "spear", "cheek", "growth", "constant",
                            "beating", "thrilling", "diamond", "success", "calamity", "comfort", "obstruction", "auspicious", "accomplished", "amenable", "auspicious", "bright white",
                            "priest or god", "chief", "poor support"]
    static let panchangaMethod = "The day is counted from sunrise to sunrise. The hours divide the day from sunrise to sunset into twelve and the night into twelve; the first hour belongs to the lord of the weekday. A reading from any one limb holds only where the rest of the chart says the same (Light on Life, chapter 7)."
}

extension Chart {
    private func called(_ code: String) -> String { Names.lords[code] ?? code }

    /// the weekday counted from sunrise (0 is Sunday) and the lord of the planetary hour at birth
    func varaAndHora(zoneHours: Double) -> (weekday: Int, hora: String)? {
        guard let rise = day.sunrise, let set = day.sunset else { return nil }
        let before = jd < rise
        guard let start = before ? day.sunrise_before : rise else { return nil }
        let weekday = Int(floor(start + zoneHours / 24 + 1.5)) % 7
        // the hour: day hours from sunrise to sunset, night hours from sunset to the next sunrise
        let lastSet = before ? set - 1 : set, nextRise = before ? rise : (day.sunrise_after ?? rise + 1)
        let hour: Int
        if jd < lastSet { hour = min(11, Int((jd - start) / ((lastSet - start) / 12))) }
        else { hour = 12 + min(11, Int((jd - lastSet) / ((nextRise - lastSet) / 12))) }
        let first = Lore.horaOrder.firstIndex(of: Names.weekdayLords[weekday]) ?? 0
        return (weekday, Lore.horaOrder[(first + hour) % 7])
    }

    /// a point within 3°20′ of the joint between a water sign and a fire sign
    static func gandanta(sign: Int, deg: Double) -> Bool {
        ([3, 7, 11].contains(sign) && deg >= 30 - 10.0 / 3) || ([0, 4, 8].contains(sign) && deg < 10.0 / 3)
    }

    /// the points of the chart standing at a gandanta
    var gandantaPoints: [String] {
        (Chart.gandanta(sign: asc.sign, deg: asc.deg) ? ["the lagna"] : []) + grahas.filter { Chart.gandanta(sign: $0.sign, deg: $0.deg) }.map { called($0.id) }
    }

    private func standing(_ code: String) -> String {
        guard let g = graha(code) else { return "" }
        let ruled = housesRuled(by: code), w = factors(for: g)
        return "In this chart \(["Su", "Mo"].contains(code) ? "the " : "")\(called(code)) \(ruled.isEmpty ? "rules no sign" : "rules the \(ruled.map(Chart.ordinal).joined(separator: " and "))") and stands in the \(Chart.ordinal(house(ofSign: g.sign))); " + Chart.weighed(w.supports.count, w.strains.count)
    }

    /// the five limbs of the birth day, with the hour lord and the gandanta mark
    func panchanga(zoneHours: Double) -> [Limb5] {
        var limbs: [Limb5] = []
        if let (weekday, hora) = varaAndHora(zoneHours: zoneHours) {
            let lord = Names.weekdayLords[weekday]
            limbs.append(Limb5(id: "Vara", value: "\(Lore.weekdays[weekday]), counted from sunrise: the day of \(["Su", "Mo"].contains(lord) ? "the " : "")\(called(lord))", words: "A day takes the nature of its lord. \(standing(lord))", graha: lord))
            limbs.append(Limb5(id: "Hora", value: "The hour of \(["Su", "Mo"].contains(hora) ? "the " : "")\(called(hora))", words: "The planetary hour is the finest of the time lords. The houses its lord rules and stands in are read as matters close to hand. \(standing(hora))", graha: hora))
        }
        if let sun = graha("Su"), let moon = graha("Mo") {
            let apart = (moon.lon - sun.lon + 360).truncatingRemainder(dividingBy: 360), within = apart / 12 - Double(self.day.tithi)
            let number = self.day.tithi % 15 + 1, waxing = self.day.tithi < 15
            let hoursLeft = (1 - within) * 12 / max(0.1, moon.speed - sun.speed) * 24
            var words = waxing ? "A birth in the bright fortnight: the waxing Moon is read as growth and plenty, and what the chart shows tends to improve with time."
                               : "A birth in the dark fortnight: the waning Moon is read as completion and turning inward; what the chart shows is consolidated more than expanded."
            words += " The birth fell \(Int((within * 100).rounded())) percent of the way through the tithi."
            if [5, 10, 15].contains(number), hoursLeft < 0.8 { words += " It fell in the last 48 minutes of this tithi, a joint Parashara marks for rites of pacification." }
            if self.day.tithi == 28 {
                let sixth = min(5, Int(within * 6))
                words += sixth == 0 ? " Parashara reads the first sixth of the Krishna Chaturdashi, where this birth fell, as auspicious."
                                    : " Parashara reads the Krishna Chaturdashi by sixths; this birth fell in the \(Chart.ordinal(sixth + 1)), which he marks for rites and for care of \(["", "the father", "the mother", "the mother's brother", "the family", "one's own health and means"][sixth])."
            }
            limbs.append(Limb5(id: "Tithi", value: Names.tithi(self.day.tithi), words: words))
        }
        let karana = Names.karana(self.day.karana), fixed = ["Shakuni", "Chatushpada", "Naga", "Kimstughna"].contains(karana)
        limbs.append(Limb5(id: "Karana", value: karana, words: fixed ? "One of the four fixed karanas, which are read as asking for care in what is begun under them."
            : karana == "Vishti" ? "Vishti, also called Bhadra, is the one movable karana read as asking for care in what is begun under it." : "One of the movable karanas, read as favourable for what is begun. Karanas weigh more in choosing a time than in reading a birth."))
        let yoga = self.day.yoga
        limbs.append(Limb5(id: "Yoga", value: "\(Names.yogas[yoga]) (\(Lore.yogaSense[yoga]))", words: "The \(Chart.ordinal(yoga + 1)) of the 27 yogas made by adding the longitudes of the Sun and the Moon: it speaks of how the two lights work together."))
        if let moon = graha("Mo") { limbs.append(Limb5(id: "Nakshatra", value: "\(moon.nak_name), pada \(moon.pada)", words: Lore.nakshatra(moon.nak), graha: "Mo")) }
        let joints = gandantaPoints
        limbs.append(Limb5(id: "Gandanta", value: joints.isEmpty ? "No point stands at a gandanta" : joints.joined(separator: ", "),
                           words: joints.isEmpty ? "A gandanta is the last 3°20′ of Karka, Vrischika and Meena and the first 3°20′ of Mesha, Simha and Dhanu, where a sign and a nakshatra end together."
                                                 : "A gandanta is the joint where a water sign and a nakshatra end together and a fire sign begins. A point there is read as weak for outer matters and as apt for inner work; the tradition answers it with remedies."))
        return limbs
    }

    /// what the book adds to a point of attention: when Kuja dosha is lightened, how a Kala-sarpa lies, when raja yogas are broken
    func yogaConditions(_ yoga: Yoga) -> String? {
        if yoga.name.hasPrefix("Kuja dosha"), let mars = graha("Ma") {
            var eased: [String] = []
            if mars.status == "Own" || mars.status == "Exalt." { eased.append("Mars is \(mars.status == "Own" ? "in its own sign" : "exalted"), which greatly lightens it") }
            if graha("Mo")?.sign == mars.sign { eased.append("the Moon stands with Mars, which cancels it") }
            let counts = yogas.filter { $0.name.hasPrefix("Kuja dosha") }.count
            return "\(eased.isEmpty ? "None of the conditions in the chart that lighten it is met" : eased.joined(separator: ", and ").prefix(1).uppercased() + eased.joined(separator: ", and ").dropFirst()). It is counted from \(counts) of the three points (lagna, Moon, Venus); it is read as spent once Mars matures at 28, and as balanced by a partner whose chart carries the same. About half of all charts carry it from each point."
        }
        if yoga.name == "Kala-sarpa yoga", let rahu = graha("Ra"), let ketu = graha("Ke") {
            let towardRahu = grahas.prefix(7).allSatisfy { ($0.lon - ketu.lon + 360).truncatingRemainder(dividingBy: 360) < 180 }
            let hosts = Array(Set([Chart.signLords[rahu.sign], Chart.signLords[ketu.sign]])).sorted()
            let with = grahas.prefix(7).filter { $0.sign == rahu.sign || $0.sign == ketu.sign }.map(\.id)
            let focus = Array(Set([house(ofSign: rahu.sign), house(ofSign: ketu.sign)] + hosts.flatMap { housesRuled(by: $0) } + with.flatMap { housesRuled(by: $0) })).sorted()
            return "\(towardRahu ? "All seven move toward Rahu (anuloma), the form read as the lighter" : "All seven move toward Ketu (viloma), the form read as giving gain with strain beside it"). Its matters gather in the houses the nodes stand in, those their sign lords rule, and those ruled by a graha standing with a node: the \(focus.map(Chart.ordinal).joined(separator: ", ")). No classical text names this yoga, and those that describe it do not agree on its result."
        }
        return nil
    }

    /// Saravali 39's breaker of raja yogas, the one Light on Life gives as its example
    var rajaBhanga: String? {
        let fallen = ["Su", "Ma", "Ju", "Sa"].compactMap { graha($0) }.filter { $0.status == "Debil." }
        guard fallen.count >= 2, fallen.contains(where: { $0.sign == asc.sign }), graha("Mo")?.sign == 7 else { return nil }
        return "Two of the Sun, Mars, Jupiter and Saturn are debilitated (\(fallen.map { called($0.id) }.joined(separator: ", "))), one of them in the lagna, with the Moon in Vrischika: Saravali 39 reads this as breaking the chart's raja yogas, so their promise is read as coming through one's own effort."
    }
}

/// The five limbs of the birth day.
struct PanchangaCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(chart.panchanga(zoneHours: store.birth?.zoneHours ?? 0)) { limb in
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 8) {
                        Text(limb.id).foregroundStyle(.secondary).frame(width: 84, alignment: .leading).help(Help.term(limb.id) ?? "")
                        Text(limb.value).fontWeight(.medium)
                        if let code = limb.graha { Button(Names.lords[code] ?? code) { store.pick = .graha(code) }.buttonStyle(.bordered).controlSize(.small).tint(Tint.graha(code)) }
                    }
                    Text(limb.words).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true).padding(.leading, 92)
                }
            }
            if store.showHelp { Text(Lore.panchangaMethod).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
            Text(Lore.balance).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}

extension Report {
    func panchangaPage(_ number: Int) -> AnyView {
        page(number, title: "Panchanga") {
            title("The Five Limbs of the Birth Day", y: 76)
            rule(x: 65, y: 95, width: 468)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(chart.panchanga(zoneHours: birth.zoneHours ?? 0)) { limb in
                    VStack(alignment: .leading, spacing: 1) {
                        (Text(limb.id + ".  ").bold().foregroundColor(Ink.maroon) + Text(limb.value).bold()).font(Ink.times(11))
                        Text(limb.words).font(Ink.times(10.4)).fixedSize(horizontal: false, vertical: true)
                    }
                }
                Text(Lore.panchangaMethod + " " + Lore.balance).font(Ink.times(9.6)).italic().fixedSize(horizontal: false, vertical: true).padding(.top, 4)
            }
            .frame(width: 452, alignment: .leading).at(74, 106)
        }
    }
}
