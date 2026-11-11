import SwiftUI

extension Lore {
    /// how the app and its report speak
    static let voice = "It states the conditions a chart shows and the understandings the tradition attaches to them, and it stops there. It names what supports a graha and what asks more of it side by side. A chart describes conditions; what is made of them remains with the person. Where the tradition's words are stern (dusthana, debilitated, malefic), the app keeps the word, so you can look it up anywhere, and gives the constructive reading the same teachers give: effort, depth, release, strength gained by use."

    /// where the positions and the rules come from
    static let sources: [(title: String, words: String, link: String?)] = [
        ("NASA JPL DE440", "The planetary ephemeris every position is read from. The app's positions are checked against NASA's Horizons service and against Swiss Ephemeris, and agree within a fraction of an arcsecond.", "https://ssd.jpl.nasa.gov/horizons/"),
        ("Brihat Parashara Hora Shastra", "Houses and their lords, dignities, aspects, vargas, yogas, the dashas, ashtakavarga. The arudha pada rule follows its chapter on padas: a pada falling on its own house moves to the tenth from it, one falling on the seventh to the fourth.", "https://archive.org/download/BPHSEnglish/BPHS%20-%201%20RSanthanam.pdf"),
        ("Parashara, verse by verse", "The chapters on padas and on the karakas, with translation.", "https://enjoylearningsanskrit.com/scriptures/parashara/chapter-29"),
        ("B.V. Raman, Graha and Bhava Balas", "Shadbala, row by row.", nil),
        ("K.N. Rao, Jaimini's Chara Dasha", "The order and years of the Chara dasha.", nil),
        ("K.S. Krishnamurti, Krishnamurti Paddhati", "The KP ayanamsa, sub-lords and significators.", nil),
    ]
    static let schools = "Where schools differ, the app follows one and says which. Rules are stated beside what they find, so a reader can check them."
}

/// The report's pages in words: the chart at a glance, each graha weighed, the yogas, and how to read the report.
extension Report {
    private func prose(_ words: String, size: CGFloat = 10.8) -> some View {
        Text(words).font(Ink.times(size)).fixedSize(horizontal: false, vertical: true)
    }
    private func subhead(_ words: String) -> some View { Text(words).font(Ink.times(12)).bold().foregroundColor(Ink.maroon) }
    private var closing: some View { Text(Lore.balance).font(Ink.times(10)).italic().fixedSize(horizontal: false, vertical: true) }

    func glancePage(_ number: Int) -> AnyView {
        page(number, title: "At a Glance") {
            title("This Chart at a Glance", y: 76)
            rule(x: 65, y: 95, width: 468)
            VStack(alignment: .leading, spacing: 11) {
                ForEach(chart.glance(day: chart.jd, atBirth: true)) { line in
                    VStack(alignment: .leading, spacing: 2) { subhead(line.heading); prose(line.words) }
                }
                closing.padding(.top, 6)
            }
            .frame(width: 452, alignment: .leading).at(74, 108)
        }
    }

    /// what a graha rules and where it stands, then what supports it beside what asks more of it
    private func weighed(_ g: Graha) -> some View {
        let ruled = chart.housesRuled(by: g.id), house = chart.house(ofSign: g.sign), w = chart.factors(for: g)
        let rules = ruled.isEmpty ? "Rules no sign; it gives through \(Names.lords[Chart.signLords[g.sign]] ?? ""), lord of the sign it stands in."
                                  : "Rules the \(ruled.map(Chart.ordinal).joined(separator: " and "))."
        let column = { (head: String, lines: [String]) in
            VStack(alignment: .leading, spacing: 1) {
                Text(head).font(Ink.times(9.6)).italic()
                ForEach(lines.isEmpty ? ["nothing marked"] : lines, id: \.self) { Text("· " + $0).font(Ink.times(9.8)).fixedSize(horizontal: false, vertical: true) }
            }
            .frame(width: 220, alignment: .leading)
        }
        return VStack(alignment: .leading, spacing: 2) {
            (Text(Names.lords[g.id] ?? g.name).bold().foregroundColor(Ink.graha(g.id))
                + Text("  \(g.retro && g.id != "Ra" && g.id != "Ke" ? "retrograde, " : "")in \(Names.signs[g.sign]), the \(Chart.ordinal(house)) house (\(Lore.houseNames[house - 1].lowercased())). \(rules)"))
                .font(Ink.times(10.8)).fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: 12) { column("What supports it", w.supports); column("What asks more of it", w.strains) }
        }
    }

    func weighedPage(_ grahas: [Graha], part: Int) -> (Int) -> AnyView {
        { number in
            self.page(number, title: "The Grahas Weighed #\(part)") {
                self.title("Each Graha: What Supports It and What Asks More of It", y: 76)
                self.rule(x: 65, y: 95, width: 468)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(grahas) { self.weighed($0) }
                    if part == 2 {
                        self.prose("The stern words of the tradition are kept so they can be looked up. A debilitated graha gives through effort; a dusthana works through service, depth or release; an aspect of Saturn or Mars asks for patience or courage. Each is a place where strength is gained by use.", size: 10)
                        self.closing
                    }
                }
                .frame(width: 452, alignment: .leading).at(74, 106)
            }
        }
    }

    private func yogaLine(_ yoga: Yoga) -> String {
        var line = "  " + yoga.why + "."
        if let meaning = Lore.yogaMeaning(yoga, in: chart) { line += " " + meaning.line }
        if let standing = Lore.yogaStanding(yoga, in: chart) { line += " " + standing }
        return line
    }

    /// The yogas, eight to a page: each with its rule, the tradition's reading, a reading to work with, and
    /// the standing of its grahas.
    var yogaPages: [(Int) -> AnyView] {
        let all = chart.yogas, size = 8
        let parts: [[Yoga]] = all.isEmpty ? [[]] : stride(from: 0, to: all.count, by: size).map { Array(all[$0..<min($0 + size, all.count)]) }
        return parts.enumerated().map { index, part in { number in self.yogaPage(number, part: part, index: index, last: index == parts.count - 1) } }
    }

    private func yogaPage(_ number: Int, part: [Yoga], index: Int, last: Bool) -> AnyView {
        var order: [String] = []
        for yoga in part where !order.contains(yoga.group) { order.append(yoga.group) }
        return page(number, title: "Yogas #\(index + 1)") {
            title("Yogas Formed in the Chart", y: 76)
            rule(x: 65, y: 95, width: 468)
            VStack(alignment: .leading, spacing: 8) {
                if index == 0 { prose(Lore.yogaPrinciple, size: 10) }
                if chart.yogas.isEmpty { prose("None of the yogas the engine knows is formed in this chart.") }
                ForEach(order, id: \.self) { group in
                    VStack(alignment: .leading, spacing: 3) {
                        subhead(group)
                        ForEach(part.filter { $0.group == group }) { yoga in
                            (Text(yoga.name).bold() + Text(yoga.grahas.isEmpty ? "" : "  (" + yoga.grahas.joined(separator: ", ") + ")") + Text(yogaLine(yoga)))
                                .font(Ink.times(10.2)).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                if last {
                    prose("A yoga gives in the periods of the grahas that form it. Points of attention name where the chart asks for awareness; the same teachers read them as places of growth. The readings follow Mantreswara's Phaladipika and Parashara.", size: 10).padding(.top, 4)
                    closing
                }
            }
            .frame(width: 452, alignment: .leading).at(74, 106)
        }
    }

    /// Jaimini's reading on one page: the seven chara karakas, the twelve arudha padas and the Chara dasha.
    func jaiminiPage(_ number: Int) -> AnyView {
        let j = chart.jaimini
        let line = { (head: String, rest: String) in (Text(head).bold() + Text("  " + rest)).font(Ink.times(10.2)).fixedSize(horizontal: false, vertical: true) }
        let columns = { (lines: [(String, String)]) in
            HStack(alignment: .top, spacing: 12) {
                ForEach(0..<2, id: \.self) { half in
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(lines.enumerated()).filter { $0.offset % 2 == half }, id: \.offset) { line($0.element.0, $0.element.1) }
                    }
                    .frame(width: 220, alignment: .leading)
                }
            }
        }
        let karakas: [(String, String)] = j.karakas.enumerated().map { index, code in
            let role = Lore.karakas[index], degrees = chart.graha(code).map { Names.dms($0.deg) } ?? ""
            return ("\(role.code) \(role.name)", "\(Names.lords[code] ?? code) \(degrees). \(role.words.prefix(1).uppercased() + role.words.dropFirst()).")
        }
        let padas: [(String, String)] = (1...12).map { house in
            let sign = j.arudhas[house - 1]
            return (house == 1 ? "AL" : house == 12 ? "UL" : "A\(house)", "of the \(Chart.ordinal(house)) (\(Lore.houseNames[house - 1].lowercased())): \(Names.signs[sign]), the \(Chart.ordinal(chart.house(ofSign: sign))) house")
        }
        let periods: [(String, String)] = j.chara.prefix(24).map { p in
            ("\(Names.signs[p.sign])\(p.years.map { " (\($0)y)" } ?? "")", "\(dateText(p.start)) to \(dateText(p.end))")
        }
        return page(number, title: "Jaimini") {
            title("Jaimini: Karakas, Arudha Padas and Chara Dasha", y: 76)
            rule(x: 65, y: 95, width: 468)
            VStack(alignment: .leading, spacing: 7) {
                subhead("The seven chara karakas")
                prose("The grahas ranked by how far each has come through its sign; the furthest is the atmakaraka.", size: 10)
                VStack(alignment: .leading, spacing: 2) { ForEach(Array(karakas.enumerated()), id: \.offset) { line($0.element.0, $0.element.1) } }
                prose("Karakamsa, the atmakaraka's navamsa sign: \(Names.signs[j.karakamsa]), the \(Chart.ordinal(chart.house(ofSign: j.karakamsa))) house of the birth chart.", size: 10.2)
                subhead("Arudha padas")
                prose("The image each house casts: count from the house to its lord, then as far again. A pada falling on its own house moves to the tenth from it, one falling on the seventh to the fourth (Parashara).", size: 10)
                columns(padas)
                subhead("Chara dasha")
                prose("Periods of signs, after K.N. Rao. The signs take their turns \(j.forward ? "forward" : "backward") through the zodiac from the lagna; a sign's years are the count from it to its lord.", size: 10)
                columns(periods)
                closing.padding(.top, 4)
            }
            .frame(width: 452, alignment: .leading).at(74, 106)
        }
    }

    func voicePage(_ number: Int) -> AnyView {
        page(number, title: "Sources and Voice") {
            title("How to Read This Report", y: 76)
            rule(x: 65, y: 95, width: 468)
            VStack(alignment: .leading, spacing: 8) {
                subhead("How it speaks"); prose(Lore.voice)
                subhead("Where the positions come from")
                (Text(Lore.sources[0].title).bold() + Text("  " + Lore.sources[0].words)).font(Ink.times(10.8)).fixedSize(horizontal: false, vertical: true)
                subhead("Where the rules come from")
                ForEach(Array(Lore.sources.dropFirst()), id: \.title) { s in
                    (Text(s.title).bold() + Text("  " + s.words)).font(Ink.times(10.8)).fixedSize(horizontal: false, vertical: true)
                }
                subhead("What is left open")
                prose("Planetary war (graha yuddha) is left out of the shadbala count. Cheshta and drik bala follow B.V. Raman and can differ from other programs by a few virupas. Dasha dates use a year of 365.25 days. " + Lore.schools)
                closing.padding(.top, 4)
            }
            .frame(width: 452, alignment: .leading).at(74, 108)
        }
    }

    var wordPages: [(Int) -> AnyView] {
        [weighedPage(Array(chart.grahas.prefix(5)), part: 1), weighedPage(Array(chart.grahas.dropFirst(5)), part: 2)] + yogaPages
    }
}
