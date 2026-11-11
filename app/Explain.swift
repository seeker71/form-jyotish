import SwiftUI

/// What a fact means, said in a few short paragraphs: shown on a card over the desk when the fact is clicked.
struct Explanation: Equatable {
    var title: String
    var group: String = ""
    var lines: [String]
    /// a workspace where this can be examined
    var workspace: String? = nil
    /// a glossary word to open
    var term: String? = nil
}

extension Lore {
    private static let aims = [("dharma", "purpose and right action", "fire"), ("artha", "livelihood and resources", "earth"), ("kama", "desire and relationship", "air"), ("moksha", "release and inner freedom", "water")]

    /// a glossary word or a table heading, as an explanation
    static func explain(term: String, chart: Chart?) -> Explanation {
        if let entry = Glossary.entries(for: chart).first(where: { $0.term == term || $0.term.hasPrefix(term + " ") }) {
            return Explanation(title: entry.term, group: entry.group, lines: [entry.words] + (entry.here.isEmpty ? [] : [entry.here]), workspace: entry.workspace, term: entry.term)
        }
        if let yoga = explain(yoga: term, chart: chart) { return yoga }
        return Explanation(title: term, lines: [Help.term(term) ?? "The glossary holds no entry under this name."])
    }

    /// a nakshatra and one of its padas: where it lies, who presides, whose dasha it opens, and what the pada adds
    static func explain(nakshatra nak: Int, pada: Int, of who: String) -> Explanation {
        let name = Glossary.nakshatraNames[nak], start = Double(nak) * 360 / 27, end = start + 360.0 / 27
        let place = { (lon: Double) in "\(Names.dms(lon.truncatingRemainder(dividingBy: 30))) \(Names.signs[Int(lon / 30) % 12])" }
        let lord = Vimshottari.order[nak % 9], years = Int(Vimshottari.years[nak % 9])
        let navamsa = (nak * 4 + pada - 1) % 12, aim = aims[navamsa % 4]
        return Explanation(title: "\(name), pada \(pada)", group: "Nakshatra · \(who)", lines: [
            "\(name) is the \(Chart.ordinal(nak + 1)) of the 27 nakshatras, the lunar mansions the Moon passes through in a month. It runs from \(place(start)) to \(place(end - 0.0001)).",
            Lore.nakshatra(nak),
            "Its lord is \(Names.lords[lord] ?? lord). A Moon in \(name) opens life in \(Names.lords[lord] ?? lord)'s dasha, which lasts \(years) years in full; any graha here takes some of \(Names.lords[lord] ?? lord)'s colour.",
            "Each nakshatra has four padas, quarters of 3°20′. Pada \(pada) of \(name) falls in the navamsa of \(Names.signs[navamsa]), \(aim.2 == "earth" || aim.2 == "air" ? "an" : "a") \(aim.2) sign. That makes it a pada of \(aim.0): \(aim.1). The pada is why this point stands in \(Names.signs[navamsa]) in the D9 chart.",
        ], workspace: "Vargas", term: "Nakshatra")
    }

    /// a sign and the house it makes in this chart
    static func explain(sign: Int, in chart: Chart) -> Explanation {
        let house = chart.house(ofSign: sign), lord = Chart.signLords[sign]
        return Explanation(title: "\(Names.signs[sign]) (\(Names.signsWestern[sign]))", group: "Rasi", lines: [
            Lore.sign(sign),
            "Its lord is \(Names.lords[lord] ?? lord). Whatever stands in \(Names.signs[sign]) answers to \(Names.lords[lord] ?? lord), wherever that graha is placed.",
            "In this chart \(Names.signs[sign]) is the \(Chart.ordinal(house)) house: \(Lore.houses[house - 1]).",
        ], term: "Rasi")
    }

    /// a house counted from the lagna and from the Moon
    static func explain(house: Int, fromMoon: Int) -> Explanation {
        Explanation(title: "The \(Chart.ordinal(house)) house", group: "House (bhava)", lines: [
            "The \(Chart.ordinal(house)) house, \(Lore.houseNames[house - 1].lowercased()), covers \(Lore.houses[house - 1]).",
            Lore.houseKind(house),
            "Counted from the Moon the same sign is the \(Chart.ordinal(fromMoon)) house, \(Lore.houseNames[fromMoon - 1].lowercased()): \(Lore.houses[fromMoon - 1]). The count from the lagna reads the outer life; the count from the Moon reads how it is felt.",
        ], term: "House (bhava)")
    }

    /// a graha's dignity: how it stands in the sign it is in
    static func explain(dignity status: String, combust: Bool, of who: String, sign: Int) -> Explanation {
        let words: [String: String] = [
            "Exalt.": "Exalted: the sign where this graha's nature shows most fully. Its matters come with ease and reach.",
            "Own": "In its own sign: at home, acting from its own ground and steady in what it gives.",
            "Grt.Fr.": "In the sign of a great friend: its host is a friend both by nature and by placement in this chart, so it is well received.",
            "Friend": "In a friend's sign: its host supports it.",
            "Neutr.": "In a neutral sign: its host neither helps nor hinders; the graha gives by its own strength.",
            "Enemy": "In the sign of a graha it is at odds with: it works in a setting unlike itself, which asks for adjustment.",
            "Grt.En.": "In the sign of a graha it is much at odds with, by nature and by placement: its matters ask for patience and skill.",
            "Debil.": "Debilitated: the sign opposite its exaltation, where its nature is least at ease. Its gifts come through effort, and what is built here is one's own.",
        ]
        var lines = [words[status] ?? status,
                     "Dignity is reckoned from the lord of the sign a graha stands in: natural friendship between the two, joined with where they stand from each other in this chart. \(who) is in \(Names.signs[sign]), whose lord is \(Names.lords[Chart.signLords[sign]] ?? "")."]
        if combust { lines.append("Combust: \(who) stands close to the Sun and is hidden in its light. Its matters work inwardly, close to the self.") }
        return Explanation(title: "\(who): \(status)\(combust ? ", combust" : "")", group: "Dignity", lines: lines, workspace: "Strength", term: "Dignity")
    }
}

/// The card an explanation is shown on, in the middle of the window.
struct Explained: View {
    @EnvironmentObject var store: Store
    let about: Explanation

    private func close() { store.explanation = nil }

    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea().onTapGesture { close() }
            VStack(alignment: .leading, spacing: 10) {
                Text(about.title).font(.title2).fontWeight(.semibold)
                if !about.group.isEmpty { Text(about.group).font(.caption).foregroundStyle(.secondary) }
                ForEach(about.lines, id: \.self) { Text($0).font(.title3).fixedSize(horizontal: false, vertical: true) }
                HStack(spacing: 10) {
                    if let workspace = about.workspace { Button("Go to \(workspace)") { store.workspace = workspace; close() } }
                    if let term = about.term {
                        Button("Open the glossary") {
                            store.workspace = "Guide"; store.glossary = term.components(separatedBy: " (").first ?? term; close()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { store.showCard = "glossary" }
                        }
                    }
                    Spacer()
                    Button("Close") { close() }.keyboardShortcut(.cancelAction)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .frame(width: 560, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .windowBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.15)))
            .contentShape(RoundedRectangle(cornerRadius: 12)).onTapGesture { }
        }
    }
}
