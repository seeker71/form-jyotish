import SwiftUI

/// Transits read against the birth chart, as Light on Life gives them from Phaladipika: the period lords by the
/// sign they pass, measured against their strength at birth; Jupiter and Saturn by the houses they touch; and,
/// for those who count from the Moon, the favourable places with their vedha and the third of a sign where each
/// graha gives.
struct GocharaRow: Identifiable {
    let id: String
    let fromMoon: Int
    let favourable: Bool
    /// the place from the Moon that would cancel a favourable passage, and the grahas standing there now
    let vedhaPlace: Int?
    let vedhaBy: [String]
    /// whether the graha is in the third of the sign where it gives
    let giving: Bool
    let third: String
}

extension Lore {
    /// favourable places counted from the Moon, each with the place whose occupation cancels it (vedha)
    static let gochara: [String: [Int: Int]] = [
        "Su": [3: 9, 6: 12, 10: 4, 11: 5],
        "Mo": [1: 5, 3: 9, 6: 12, 7: 2, 10: 4, 11: 8],
        "Ma": [3: 12, 6: 9, 11: 5],
        "Me": [2: 5, 4: 3, 6: 9, 8: 1, 10: 8, 11: 12],
        "Ju": [2: 12, 5: 4, 7: 3, 9: 10, 11: 8],
        "Ve": [1: 8, 2: 7, 3: 1, 4: 10, 5: 9, 8: 5, 9: 11, 11: 6, 12: 3],
        "Sa": [3: 12, 6: 9, 11: 5], "Ra": [3: 12, 6: 9, 11: 5], "Ke": [3: 12, 6: 9, 11: 5],
    ]
    /// father and son do not cancel each other: the Sun and Saturn, the Moon and Mercury
    static let vedhaExempt: [String: String] = ["Su": "Sa", "Sa": "Su", "Mo": "Me", "Me": "Mo", "Ra": "Ke", "Ke": "Ra"]
    static let gocharaMethod = "Counted from the birth Moon. A graha in a favourable place gives its good unless another graha stands in that place's vedha, which cancels it; the Sun and Saturn do not cancel each other, nor the Moon and Mercury; Rahu and Ketu, always opposite, are not counted against each other. The Sun and Mars give in the first third of a sign, Jupiter and Venus in the middle third, the Moon and Saturn in the last, Mercury and the nodes throughout (Phaladipika 26). Light on Life counts transits from the lagna first and gives this as the second way."
}

extension Chart {
    private func called(_ code: String) -> String { Names.lords[code] ?? code }

    /// each graha's passage counted from this chart's Moon
    func gochara(sky: Chart) -> [GocharaRow] {
        guard let moon = graha("Mo") else { return [] }
        return sky.grahas.map { g in
            let from = (g.sign - moon.sign + 12) % 12 + 1, vedha = Lore.gochara[g.id]?[from]
            let blockers = vedha.map { place in sky.grahas.filter { $0.id != g.id && $0.id != Lore.vedhaExempt[g.id] && ($0.sign - moon.sign + 12) % 12 + 1 == place }.map(\.id) } ?? []
            let part = g.deg < 10 ? 0 : g.deg < 20 ? 1 : 2
            let wanted: Int? = ["Su", "Ma"].contains(g.id) ? 0 : ["Ju", "Ve"].contains(g.id) ? 1 : ["Mo", "Sa"].contains(g.id) ? 2 : nil
            let third = wanted.map { ["first third", "middle third", "last third"][$0] } ?? "throughout"
            return GocharaRow(id: g.id, fromMoon: from, favourable: vedha != nil, vedhaPlace: vedha, vedhaBy: blockers, giving: wanted == nil || wanted == part, third: third)
        }
    }

    /// one row of the count from the Moon, as a sentence
    func gocharaWords(_ row: GocharaRow) -> String {
        var text = "\(["Su", "Mo"].contains(row.id) ? "The " : "")\(called(row.id)) passes the \(Chart.ordinal(row.fromMoon)) from the Moon, "
        if let place = row.vedhaPlace {
            text += row.vedhaBy.isEmpty ? "a favourable place, and nothing stands in its vedha (the \(Chart.ordinal(place)))"
                                        : "a favourable place, cancelled for now by \(row.vedhaBy.map(called).joined(separator: " and ")) in its vedha (the \(Chart.ordinal(place)))"
        } else { text += "a place that asks more" }
        text += row.third == "throughout" ? "; it gives throughout the sign." : "; it gives in the \(row.third) of a sign, \(row.giving ? "where it is now" : "which it is not in now")."
        return text
    }

    /// a period lord in transit: by the sign it passes, against its strength at birth (Phaladipika 20, as Light on Life reads it)
    func periodLordPassing(_ code: String, role: String, sky: Chart) -> String? {
        guard !["Ra", "Ke"].contains(code), let now = sky.graha(code), let natal = graha(code) else { return nil }
        let house = Chart.ordinal(self.house(ofSign: now.sign)), status = now.status ?? ""
        var text = "\(called(code)), lord of the \(role), is passing through \(Names.signs[now.sign]), the \(house) house from the lagna."
        let hard = ["Debil.", "Enemy", "Grt.En."].contains(status) || now.combust == true
        let good = ["Exalt.", "Own", "Grt.Fr.", "Friend"].contains(status) || (now.retro && !["Su", "Mo"].contains(code))
        if hard { text += " It is \(sky.weakness(now) ?? "under strain") there: a period lord so placed in transit is read as a stretch that asks more in the matters of the \(house) house." }
        else if good {
            let how = status == "Exalt." ? "exalted" : status == "Own" ? "in its own sign" : ["Grt.Fr.", "Friend"].contains(status) ? "in a friend's sign" : "retrograde"
            text += " It is \(how) there, which is read as bringing the \(house) house forward"
            text += weakness(natal).map { "; the verse adds that the graha be strong at birth as well, and at birth it is \($0), so the help comes in smaller measure." } ?? ", the more so as it is not weakened at birth."
        }
        if now.sign == natal.sign { text += " It is passing over its own place in the birth chart, which is read as waking what it promises there." }
        return text
    }

    /// Jupiter or Saturn in transit: the house it passes and the houses it aspects from there
    func slowPassing(_ code: String, sky: Chart) -> String? {
        guard code == "Ju" || code == "Sa", let g = sky.graha(code) else { return nil }
        let reached = (code == "Ju" ? [5, 7, 9] : [3, 7, 10]).map { Chart.ordinal(house(ofSign: (g.sign + $0 - 1) % 12)) }
        let natal = graha(code).flatMap { weakness($0) }
        return "\(called(code)) is passing through \(Names.signs[g.sign])\(g.retro ? ", retrograde" : ""), the \(Chart.ordinal(house(ofSign: g.sign))) house from the lagna, and from there aspects the \(reached[0]), \(reached[1]) and \(reached[2]). \(code == "Ju" ? "Jupiter's passage is read as easing the houses it touches" : "Saturn's passage is read as asking for work and patience in the houses it touches")\(natal.map { ", in the measure of its place at birth, where it is \($0)" } ?? "")."
    }
}

/// The passage of each graha counted from the birth Moon, with vedha and the third of the sign where it gives.
struct GocharaCard: View {
    @EnvironmentObject var store: Store
    let natal: Chart

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let sky = store.sky {
                let heads: [(String, CGFloat)] = [("Graha", 84), ("From Moon", 84), ("Place", 110), ("Vedha", 190), ("Gives in", 150)]
                ScrollView(.horizontal) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 0) { ForEach(heads, id: \.0) { Text($0.0).font(.caption).foregroundStyle(.secondary).frame(width: $0.1, alignment: .leading) } }
                        ForEach(natal.gochara(sky: sky)) { row in
                            let open = row.favourable && row.vedhaBy.isEmpty
                            HStack(spacing: 0) {
                                Text(Names.lords[row.id] ?? row.id).fontWeight(.medium).foregroundStyle(Tint.graha(row.id)).frame(width: 84, alignment: .leading)
                                Text(Chart.ordinal(row.fromMoon)).frame(width: 84, alignment: .leading)
                                Text(row.favourable ? "favourable" : "asks more").foregroundStyle(open ? AnyShapeStyle(.green) : row.favourable ? AnyShapeStyle(.secondary) : AnyShapeStyle(.orange)).frame(width: 110, alignment: .leading)
                                Text(row.vedhaPlace.map { place in row.vedhaBy.isEmpty ? "\(Chart.ordinal(place)): open" : "\(Chart.ordinal(place)): cancelled by \(row.vedhaBy.joined(separator: " "))" } ?? "").frame(width: 190, alignment: .leading)
                                Text(row.third + (row.third == "throughout" ? "" : row.giving ? " · now" : " · not now")).foregroundStyle(row.giving ? .primary : .secondary).frame(width: 150, alignment: .leading)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { store.pick = .graha(row.id) }
                            .help(natal.gocharaWords(row))
                        }
                    }
                    .monospacedDigit()
                }
                if store.showHelp { Text(Lore.gocharaMethod).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
                Text(Lore.balance).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            } else {
                HStack {
                    Text("The desk stands at the birth, so there is no later sky to count.").foregroundStyle(.secondary)
                    Button("Go to now") { store.goNow() }.controlSize(.small)
                }
            }
        }
    }
}

extension Report {
    /// The transit page in words: the running period's lords in transit, Jupiter and Saturn, and the count from the Moon.
    func transitReadPage(_ sky: Chart) -> (Int) -> AnyView {
        { number in
            let running = Vimshottari.running(at: sky.jd, in: self.chart.dasha, depth: 2), roles = ["mahadasha", "antardasha"]
            var lords: [String] = []
            for (index, period) in running.enumerated() where index == 0 || period.lord != running[0].lord {
                if let line = self.chart.periodLordPassing(period.lord, role: roles[index], sky: sky) { lords.append(line) }
                else { lords.append("\(Names.lords[period.lord] ?? period.lord), lord of the \(roles[index]), rules no sign; its passage is read through the lord of the sign it passes.") }
            }
            let head = { (words: String) in Text(words).font(Ink.times(12)).bold().foregroundColor(Ink.maroon) }
            let prose = { (words: String) in Text(words).font(Ink.times(10.6)).fixedSize(horizontal: false, vertical: true) }
            return self.page(number, title: "Transits Read") {
                self.title("The Transits Read against the Birth Chart", y: 76)
                self.rule(x: 65, y: 95, width: 468)
                VStack(alignment: .leading, spacing: 7) {
                    prose("Transits bring forward what the birth chart and the running period already hold; they do not change its nature. They are read first from the lagna, then from the Moon.")
                    head("The lords of the running period")
                    if lords.isEmpty { prose("The day of this report lies outside the 120 years of the Vimshottari cycle, so no period is running.") }
                    ForEach(lords, id: \.self) { prose($0) }
                    head("Jupiter and Saturn").padding(.top, 3)
                    ForEach(["Ju", "Sa"].compactMap { self.chart.slowPassing($0, sky: sky) }, id: \.self) { prose($0) }
                    head("Counted from the Moon (gochara)").padding(.top, 3)
                    ForEach(self.chart.gochara(sky: sky)) { row in Text("· " + self.chart.gocharaWords(row)).font(Ink.times(10.2)).fixedSize(horizontal: false, vertical: true) }
                    Text(Lore.gocharaMethod).font(Ink.times(9.6)).italic().fixedSize(horizontal: false, vertical: true).padding(.top, 3)
                    Text(Lore.balance).font(Ink.times(10)).italic().fixedSize(horizontal: false, vertical: true)
                }
                .frame(width: 452, alignment: .leading).at(74, 106)
            }
        }
    }
}
