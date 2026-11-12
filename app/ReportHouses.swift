import SwiftUI

/// The report's pages on the twelve houses: each judged by its three limbs, the house, its lord and its karaka,
/// as Light on Life teaches from Phaladipika 15.1 and 15.6.
extension Report {
    /// several factors as one sentence: each after the first begins small, unless it begins with a graha's name
    private func joined(_ lines: [String]) -> String {
        lines.enumerated().map { index, line in
            let first = line.split(separator: " ").first.map { $0.trimmingCharacters(in: .punctuationCharacters) } ?? ""
            return index == 0 || Names.lords.values.contains(first) ? line : line.prefix(1).lowercased() + line.dropFirst()
        }.joined(separator: "; ") + "."
    }

    private func limbLine(_ limb: Limb) -> String {
        var parts: [String] = []
        if !limb.supports.isEmpty { parts.append("Supports: " + joined(limb.supports)) }
        if !limb.strains.isEmpty { parts.append("Asks more: " + joined(limb.strains)) }
        parts += limb.notes
        return parts.isEmpty ? "Nothing marked either way." : parts.joined(separator: " ")
    }

    private func houseBlock(_ house: Int) -> some View {
        let sign = chart.sign(ofHouse: house), matters = Lore.houses[house - 1]
        return VStack(alignment: .leading, spacing: 2) {
            (Text("\(Chart.ordinal(house)) house · \(Lore.houseNames[house - 1])").bold().foregroundColor(Ink.maroon)
                + Text("   \(Names.signs[sign]). \(matters.prefix(1).uppercased() + matters.dropFirst())."))
                .font(Ink.times(10.6)).fixedSize(horizontal: false, vertical: true)
            ForEach(chart.limbs(ofHouse: house)) { limb in
                (Text(limb.title + ". ").bold() + Text(self.limbLine(limb))).font(Ink.times(9.7)).fixedSize(horizontal: false, vertical: true)
            }
            Text(chart.confluence(ofHouse: house)).font(Ink.times(9.7)).italic().fixedSize(horizontal: false, vertical: true)
        }
    }

    var housePages: [(Int) -> AnyView] {
        let parts = [[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]]
        return parts.enumerated().map { index, houses in
            { number in
                self.page(number, title: "The Houses Judged #\(index + 1)") {
                    self.title("The Twelve Houses, Each Judged by Three Limbs", y: 76)
                    self.rule(x: 65, y: 95, width: 468)
                    VStack(alignment: .leading, spacing: 9) {
                        if index == 0 {
                            Text("A house is read from three limbs: the house itself, its lord, and its karaka, the graha with a natural affinity for its matters. For each limb the page sets what supports it beside what asks more of it. Where the three agree the reading is firm; where they differ it stays mixed. Strength says how fully a graha can act; whether it eases or asks more comes from its nature and the houses it rules. The method is the one Hart de Fouw and Robert Svoboda teach in Light on Life, from Mantreswara's Phaladipika, chapter 15, verses 1 and 6.")
                                .font(Ink.times(10)).fixedSize(horizontal: false, vertical: true)
                        }
                        ForEach(houses, id: \.self) { self.houseBlock($0) }
                        if index == parts.count - 1 { Text(Lore.balance).font(Ink.times(10)).italic().fixedSize(horizontal: false, vertical: true).padding(.top, 4) }
                    }
                    .frame(width: 452, alignment: .leading).at(74, 106)
                }
            }
        }
    }
}

/// The report's page on the states of the grahas and on their aspects.
extension Report {
    func statesPage(_ number: Int) -> AnyView {
        let seven = Array(chart.grahas.prefix(7)), widths: [CGFloat] = [70, 126, 126, 130]
        let head = { (words: String) in Text(words).font(Ink.times(12)).bold().foregroundColor(Ink.maroon) }
        let listed = { (houses: [Int]) -> String in
            let names = houses.map(Chart.ordinal)
            return names.count < 2 ? names.joined() : names.dropLast().joined(separator: ", ") + " and " + (names.last ?? "")
        }
        return page(number, title: "Avasthas and Aspects") {
            title("The States of the Grahas, and Their Aspects", y: 76)
            rule(x: 65, y: 95, width: 468)
            VStack(alignment: .leading, spacing: 6) {
                head("Avasthas")
                Text("The state each graha is in: its age by the degree it holds, its wakefulness by the sign it is in, its mood by its dignity. The avasthas temper a reading; they do not reverse it.")
                    .font(Ink.times(10.2)).fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 0) { ForEach(Array(["Graha", "By age", "By wakefulness", "By mood"].enumerated()), id: \.offset) { Text($0.element).italic().bold().frame(width: widths[$0.offset], alignment: .leading) } }
                    ForEach(seven) { g in
                        HStack(alignment: .top, spacing: 0) {
                            Text(Names.lords[g.id] ?? g.name).foregroundColor(Ink.graha(g.id)).frame(width: widths[0], alignment: .leading)
                            Text(g.baladi.map(Help.avastha) ?? "").frame(width: widths[1], alignment: .leading)
                            Text(g.jagradadi.map(Help.avastha) ?? "").frame(width: widths[2], alignment: .leading)
                            Text(g.deeptadi.map(Help.avastha) ?? "").frame(width: widths[3], alignment: .leading)
                        }
                    }
                }
                .font(Ink.times(10.2))
                head("What each graha aspects").padding(.top, 6)
                Text("Every graha aspects the seventh sign from itself. Mars also aspects the 4th and 8th, Jupiter the 5th and 9th, Saturn the 3rd and 10th. The count is by whole signs and includes the sign the graha stands in.")
                    .font(Ink.times(10.2)).fixedSize(horizontal: false, vertical: true)
                ForEach(seven) { g in
                    Text("\(Names.lords[g.id] ?? g.name), from the \(Chart.ordinal(chart.house(ofSign: g.sign))) house, aspects the \(listed(chart.aspectedSigns(by: g.id).map { chart.house(ofSign: $0) }.sorted())).")
                        .font(Ink.times(10.4)).fixedSize(horizontal: false, vertical: true)
                }
                head("Who looks at each house").padding(.top, 6)
                ForEach(0..<6, id: \.self) { row in
                    HStack(alignment: .top, spacing: 0) {
                        ForEach([row + 1, row + 7], id: \.self) { house in
                            let who = chart.aspecting(sign: chart.sign(ofHouse: house)).map { Names.lords[$0] ?? $0 }
                            (Text("\(Chart.ordinal(house)) · \(Lore.houseNames[house - 1]):  ").bold() + Text(who.isEmpty ? "no graha" : who.joined(separator: ", ")))
                                .font(Ink.times(10.2)).frame(width: 226, alignment: .leading)
                        }
                    }
                }
                Text("A benefic's aspect supports the house it falls on, and a malefic's asks more of it, unless the graha is that house's own lord. The pages on the twelve houses weigh each aspect in its place.")
                    .font(Ink.times(9.8)).italic().fixedSize(horizontal: false, vertical: true).padding(.top, 4)
            }
            .frame(width: 452, alignment: .leading).at(74, 106)
        }
    }
}
