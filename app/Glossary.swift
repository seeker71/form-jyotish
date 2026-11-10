import SwiftUI

/// One thing that can be looked up: a term in plain words, where it shows in the open chart, and a way to go there.
struct GlossaryEntry: Identifiable {
    let term: String
    let group: String
    let words: String
    /// what this is in the open chart, if it is something a chart has
    var here: String = ""
    var pick: Pick? = nil
    var workspace: String? = nil
    var id: String { group + "/" + term }
}

enum Glossary {
    static let groups = ["Basics", "Grahas", "Signs", "Houses", "Nakshatras", "Strength", "Dashas and time", "Krishnamurti Paddhati"]

    /// the ideas everything else rests on, each with the workspace where it can be seen
    static let basics: [(term: String, words: String, workspace: String?)] = [
        ("Lagna", "The ascendant: the point of the zodiac rising on the eastern horizon at the moment of birth. Its sign becomes the first house, so it sets the frame of the whole chart.", "Overview"),
        ("Graha", "A planet in the Jyotish sense, literally \u{201C}that which seizes\u{201D}: the Sun, the Moon, Mars, Mercury, Jupiter, Venus, Saturn, and the Moon's two nodes Rahu and Ketu.", "Overview"),
        ("Rasi", "A sign: one of twelve equal 30-degree divisions of the zodiac, measured against the stars (the sidereal zodiac).", "Overview"),
        ("House (bhava)", "An area of life. In the simplest and oldest reckoning each sign is one house, counted from the lagna's sign.", "Guide"),
        ("Nakshatra", "One of 27 lunar mansions of 13\u{00B0}20\u{2032} each, older than the signs. The Moon's nakshatra at birth sets the dasha sequence.", "Overview"),
        ("Pada", "A quarter of a nakshatra, 3\u{00B0}20\u{2032} wide. The 108 padas match the 108 navamsas.", "Overview"),
        ("Varshaphal", "The annual chart of the Tajika tradition: the sky at the moment the Sun returns to the longitude it held at birth, read for the year from that birthday to the next.", nil),
        ("Muntha", "A point that starts in the birth lagna and moves one sign for each year of life. Its house in the annual chart marks where that year's attention gathers.", nil),
        ("Ayanamsa", "The gap between the tropical zodiac of the seasons and the sidereal zodiac of the stars, about 24 degrees now and slowly growing. Lahiri is India's official value. B.V. Raman's is about 1 degree 27 minutes smaller: choose it to follow the charts in his books, where it can move a graha near a sign's edge into the next sign and shifts dasha dates by up to two years.", nil),
        ("Dignity", "How well a graha is placed by sign: exalted, in its own sign, with a friend, neutral, with an enemy, or debilitated.", "Strength"),
        ("Exaltation and debilitation", "Each graha has one sign where it is strongest (exalted) and, opposite it, one where it is weakest (debilitated).", "Strength"),
        ("Retrograde", "A planet appearing to move backward against the stars, as the Earth overtakes it or is overtaken. Underlined in the charts. Read as intensified, inward or revisiting.", "Overview"),
        ("Combust", "A graha too close to the Sun to be seen. Its significations are read as absorbed in the Sun's light and working inwardly.", "Overview"),
        ("Benefic and malefic", "Jupiter, Venus, a well-placed Mercury and a waxing Moon are natural benefics: they tend to give. The Sun, Mars, Saturn, Rahu and Ketu are natural malefics: they ask for effort and give strength through it. A chart needs both kinds, and house rulership can change a graha's role in a given chart.", nil),
        ("Karaka", "Significator: what a graha naturally stands for whatever the chart, such as the Sun for the father or Venus for marriage.", nil),
        ("Aspect (drishti)", "A graha's glance. Every graha looks fully at the seventh sign from itself; Mars also at the 4th and 8th, Jupiter the 5th and 9th, Saturn the 3rd and 10th.", "Yogas"),
        ("Kendra", "The angles: houses 1, 4, 7 and 10. Grahas here act strongly and visibly.", "Guide"),
        ("Trikona", "The trines: houses 1, 5 and 9, the houses of fortune and merit.", "Guide"),
        ("Dusthana", "The difficult houses: 6, 8 and 12. Houses of effort and release. Grahas here, and these houses' lords, work through service, depth and letting go, and build the capacity to meet what comes.", "Guide"),
        ("Upachaya", "The growing houses: 3, 6, 10 and 11. Their results improve with time and effort; malefics do well here.", "Guide"),
        ("Varga", "A divisional chart: each sign divided into equal parts, each part assigned a sign. Each varga examines one area of life more finely.", "Vargas"),
        ("Navamsa", "The ninth-part chart (D9), the most used varga. It is read beside the birth chart for a graha's real strength, and for marriage.", "Vargas"),
        ("Vargottama", "A graha in the same sign in the birth chart and the navamsa: read as steady and strong.", "Vargas"),
        ("Yoga", "A named combination of grahas with a known tendency, such as Gajakesari (Jupiter in an angle from the Moon).", "Yogas"),
        ("Dasha", "A planetary period. Vimshottari, the usual system, gives each graha a span of years in a fixed order across 120 years, starting from the Moon's nakshatra.", "Dasha"),
        ("Transit (gochara)", "Where the grahas are now, read against the birth chart: above all from the birth Moon, and from the lagna.", "Transits"),
        ("Sade Sati", "Saturn's seven and a half years passing through the 12th, 1st and 2nd signs from the birth Moon. Traditionally a season for slowing down, taking stock and maturing.", "Transits"),
        ("Ashtakavarga", "A point system: each graha gives up to 8 points (bindus) to every sign, counted from the seven grahas and the lagna. Used to judge transits and the strength of houses.", "Strength"),
        ("Shadbala", "Six-fold strength: a measured total, in rupas, of a graha's strength of place, direction, time, motion, nature and aspect.", "Strength"),
        ("Tithi", "The lunar day: each 12 degrees the Moon gains on the Sun. Fifteen in the waxing half (Shukla), fifteen in the waning (Krishna).", nil),
        ("Rahu and Ketu", "The two points where the Moon's path crosses the Sun's. Not bodies, always opposite each other, always moving backward. Eclipses happen near them.", "Overview"),
    ]

    static func entries(for chart: Chart?) -> [GlossaryEntry] {
        var list = basics.map { GlossaryEntry(term: $0.term, group: "Basics", words: $0.words, workspace: $0.workspace) }
        for code in ["Su", "Mo", "Ma", "Me", "Ju", "Ve", "Sa", "Ra", "Ke"] {
            let g = chart?.graha(code)
            list.append(GlossaryEntry(term: "\(Names.lords[code] ?? code) (\(g?.name ?? code))", group: "Grahas", words: Help.graha(code),
                                      here: g.map { "Here: in \(Names.signs[$0.sign]), the \(Chart.ordinal(chart!.house(ofSign: $0.sign))) house, in \($0.nak_name)." } ?? "", pick: .graha(code)))
        }
        for sign in 0..<12 {
            let here = chart.map { c in "Here: the \(Chart.ordinal(c.house(ofSign: sign))) house" + (c.grahas.filter { $0.sign == sign }.isEmpty ? ", empty." : ", holding \(c.grahas.filter { $0.sign == sign }.map(\.id).joined(separator: " ")).") } ?? ""
            list.append(GlossaryEntry(term: "\(Names.signs[sign]) (\(Names.signsWestern[sign]))", group: "Signs",
                                      words: Lore.sign(sign) + " Ruled by \(Names.lords[Chart.signLords[sign]] ?? "").", here: here, pick: .sign(sign)))
        }
        for house in 1...12 {
            let here = chart.map { c in "Here: \(Names.signs[c.sign(ofHouse: house)]), ruled by \(Names.lords[c.lord(ofHouse: house)] ?? "")." } ?? ""
            list.append(GlossaryEntry(term: "\(Chart.ordinal(house)) house · \(Lore.houseNames[house - 1])", group: "Houses",
                                      words: Lore.houses[house - 1].prefix(1).uppercased() + Lore.houses[house - 1].dropFirst() + ". It is \(Lore.houseKind(house)).",
                                      here: here, pick: chart.map { .sign($0.sign(ofHouse: house)) }, workspace: "Guide"))
        }
        let lords = ["Ke", "Ve", "Su", "Mo", "Ma", "Ra", "Ju", "Sa", "Me"], names = chart?.grahas.first?.nak_name == nil ? [] : nakshatraNames
        for index in 0..<27 {
            let start = Double(index) * 360 / 27, end = start + 360 / 27
            let span = { (lon: Double) in "\(Names.dms(lon.truncatingRemainder(dividingBy: 30)).replacingOccurrences(of: "\u{2033}", with: "").dropLast(3)) \(Names.signs[Int(lon / 30) % 12])" }
            let inside = chart?.grahas.filter { $0.nak == index }.map(\.id) ?? []
            list.append(GlossaryEntry(term: names.isEmpty ? nakshatraNames[index] : names[index], group: "Nakshatras",
                                      words: "From \(span(start)) to \(span(end - 0.0001)). Ruled by \(Names.lords[lords[index % 9]] ?? ""). \(Lore.nakshatra(index))",
                                      here: inside.isEmpty ? "" : "Here: holds \(inside.joined(separator: " ")).", pick: inside.first.map { .graha($0) }))
        }
        let strength = ["Uccha", "Saptavargaja", "Ojayugma", "Kendradi", "Drekkana", "Sthana bala", "Dig bala", "Nata-unnata", "Paksha", "Tribhaga", "Abda", "Masa", "Vara", "Hora", "Ayana",
                        "Kala bala", "Cheshta bala", "Naisargika bala", "Drik bala", "Rupas", "Sarva", "Baladi", "Jagradadi", "Deeptadi"]
        list += strength.compactMap { term in Help.term(term).map { GlossaryEntry(term: term, group: "Strength", words: $0, workspace: "Strength") } }
        list += ["Mahadasha", "Antardasha", "Pratyantardasha", "Sookshma dasha", "Prana dasha"].compactMap { term in Help.term(term).map { GlossaryEntry(term: term, group: "Dashas and time", words: $0, workspace: "Dasha") } }
        list += ["Cusp", "Star lord", "Sub lord", "Sub-sub", "Occupants", "In stars of occupants", "In stars of cusp lord", "Cusp lord"].compactMap { term in
            Help.term(term).map { GlossaryEntry(term: term, group: "Krishnamurti Paddhati", words: $0, workspace: "KP") }
        }
        return list
    }

    static let nakshatraNames = ["Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira", "Ardra", "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni", "Uttara Phalguni",
                                 "Hasta", "Chitra", "Swati", "Vishakha", "Anuradha", "Jyeshtha", "Mula", "Purva Ashadha", "Uttara Ashadha", "Shravana", "Dhanishta", "Shatabhisha",
                                 "Purva Bhadrapada", "Uttara Bhadrapada", "Revati"]
}

/// Every term in one place, searchable, each tied to where it shows in the open chart.
struct GlossaryCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart?
    @State private var open: Set<String> = ["Basics"]

    private func row(_ entry: GlossaryEntry) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(entry.term).fontWeight(.semibold)
                if let workspace = entry.workspace { GoLink(title: workspace, workspace: workspace, pick: entry.pick) }
            }
            Text(entry.words).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if !entry.here.isEmpty { Text(entry.here).font(.callout).foregroundStyle(Color.accentColor).fixedSize(horizontal: false, vertical: true) }
        }
        .padding(.vertical, 4).padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { if let pick = entry.pick { store.pick = pick } }
        .help(entry.pick == nil ? "" : "Click to read about this in the inspector")
    }

    var body: some View {
        let all = Glossary.entries(for: chart)
        let words = store.glossary.lowercased().split(separator: " ")
        let found = all.filter { entry in let text = (entry.term + " " + entry.words + " " + entry.group).lowercased(); return words.allSatisfy { text.contains($0) } }
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search \(all.count) terms: a graha, a sign, a house, a nakshatra, any word", text: $store.glossary).textFieldStyle(.roundedBorder)
                if !store.glossary.isEmpty { Button("Clear") { store.glossary = "" }.controlSize(.small) }
            }
            if words.isEmpty {
                ForEach(Glossary.groups, id: \.self) { group in
                    let members = all.filter { $0.group == group }
                    Button {
                        if open.contains(group) { open.remove(group) } else { open.insert(group) }
                    } label: {
                        HStack { Image(systemName: open.contains(group) ? "chevron.down" : "chevron.right").frame(width: 12); Text(group).fontWeight(.semibold); Text("\(members.count)").foregroundStyle(.secondary) }
                    }
                    .buttonStyle(.plain).padding(.top, 2)
                    if open.contains(group) { ForEach(members) { row($0) } }
                }
            } else if found.isEmpty {
                Text("Nothing matches. Try a shorter word.").foregroundStyle(.secondary)
            } else {
                Text("\(found.count) found").font(.footnote).foregroundStyle(.secondary)
                ForEach(found.prefix(40)) { row($0) }
            }
        }
    }
}
