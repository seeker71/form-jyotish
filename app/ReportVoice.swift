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

    func yogaPage(_ number: Int) -> AnyView {
        var order: [String] = []
        for yoga in chart.yogas where !order.contains(yoga.group) { order.append(yoga.group) }
        return page(number, title: "Yogas") {
            title("Yogas Formed in the Chart", y: 76)
            rule(x: 65, y: 95, width: 468)
            VStack(alignment: .leading, spacing: 9) {
                if chart.yogas.isEmpty { prose("None of the yogas the engine knows is formed in this chart.") }
                ForEach(order, id: \.self) { group in
                    VStack(alignment: .leading, spacing: 3) {
                        subhead(group)
                        ForEach(chart.yogas.filter { $0.group == group }) { yoga in
                            (Text(yoga.name).bold() + Text(yoga.grahas.isEmpty ? "" : "  (" + yoga.grahas.joined(separator: ", ") + ")") + Text("  " + yoga.why + (Lore.yogaNote(yoga.name).map { ". " + $0 } ?? "")))
                                .font(Ink.times(10.4)).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                prose("Each yoga is listed with the rule it met, so the rule can be checked. A yoga gives in the periods of the grahas that form it, and in the measure of their strength. Points of attention name where the chart asks for awareness; the same teachers read them as places of growth.", size: 10).padding(.top, 4)
                closing
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
        [weighedPage(Array(chart.grahas.prefix(5)), part: 1), weighedPage(Array(chart.grahas.dropFirst(5)), part: 2), yogaPage]
    }
}
