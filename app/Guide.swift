import SwiftUI

/// A link that takes the reader somewhere: to a workspace, with something picked.
struct GoLink: View {
    @EnvironmentObject var store: Store
    var title: String
    var workspace: String?
    var pick: Pick?
    var now = false

    var body: some View {
        Button {
            if let workspace { store.workspace = workspace }
            if let pick { store.pick = pick }
            if now { store.goNow() }
        } label: { Label(title, systemImage: "arrow.right.circle") }
            .buttonStyle(.link)
            .help(workspace.map { "Opens the \($0) workspace" } ?? "Shows this in the inspector")
    }
}

/// The order in which a chart is read, each step with a way to see it in this chart.
struct GuideCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    private struct Step: Identifiable {
        let id: Int
        let title: String
        let words: String
        let link: GoLink
    }

    private var steps: [Step] {
        let running = chart.dasha.first { $0.holds(store.viewDay ?? chart.jd) }
        let period: Pick? = running.map { .period(lords: [$0.lord], start: $0.start, end: $0.end) }
        return [
            Step(id: 1, title: "Start from the lagna", words: "The sign rising in the east at birth is the first house, and every other house is counted from it. Its lord carries the whole chart.",
                 link: GoLink(title: "Show the lagna", workspace: "Overview", pick: .sign(chart.asc.sign))),
            Step(id: 2, title: "Find the Moon", words: "The Moon is the mind. Its sign is read as a second lagna, and its nakshatra decides which dasha life begins in.",
                 link: GoLink(title: "Show the Moon", workspace: "Overview", pick: .graha("Mo"))),
            Step(id: 3, title: "Read the houses", words: "Each house is an area of life. For each, look at its sign, where its lord has gone, who stands in it and who looks at it.",
                 link: GoLink(title: "Go to the houses below", workspace: "Guide", pick: .sign(chart.asc.sign))),
            Step(id: 4, title: "Weigh each graha", words: "A graha gives according to its condition: its dignity in its sign, the house it is in, who aspects it, and its measured strength.",
                 link: GoLink(title: "Open Strength", workspace: "Strength", pick: .graha("Su"))),
            Step(id: 5, title: "Notice the yogas", words: "Certain combinations have names and known tendencies. They colour the chart but do not replace reading the houses.",
                 link: GoLink(title: "Open Yogas", workspace: "Yogas")),
            Step(id: 6, title: "Look closer with the vargas", words: "Divisional charts examine one area in finer detail. The navamsa is read beside the birth chart for every question.",
                 link: GoLink(title: "Open Vargas", workspace: "Vargas")),
            Step(id: 7, title: "Ask when", words: "The dashas say whose time it is. A graha's promise in the chart comes forward in its own periods.",
                 link: GoLink(title: "Open Dasha", workspace: "Dasha", pick: period)),
            Step(id: 8, title: "See what is passing", words: "Transits show the present sky over the birth chart. Slow grahas, Saturn and Jupiter above all, set the season; they act within what the dasha allows.",
                 link: GoLink(title: "Open Transits at the present", workspace: "Transits", now: true)),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(steps) { step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(step.id)").font(.title3).fontWeight(.semibold).foregroundStyle(Color.accentColor).frame(width: 22, alignment: .trailing)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.title).fontWeight(.semibold)
                        Text(step.words).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        step.link
                    }
                }
            }
            Text(Lore.balance).font(.footnote).foregroundStyle(.secondary).padding(.top, 2)
        }
    }
}

/// The chart said in plain sentences, each fact linked to where it can be examined.
struct ReadingCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    private func chip(_ code: String) -> some View {
        Button(Names.lords[code] ?? code) { store.pick = .graha(code) }.buttonStyle(.bordered).controlSize(.small).tint(Tint.graha(code)).help(Help.graha(code))
    }
    private func signChip(_ sign: Int) -> some View {
        Button(Names.signs[sign]) { store.pick = .sign(sign) }.buttonStyle(.bordered).controlSize(.small).help(Lore.sign(sign))
    }
    private func line<Links: View>(_ heading: String, _ words: String, @ViewBuilder links: () -> Links) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(heading).font(.subheadline).fontWeight(.semibold)
            Text(words).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) { links() }
        }
    }
    private func placed(_ g: Graha) -> String {
        "\(Names.signs[g.sign]), the \(Chart.ordinal(chart.house(ofSign: g.sign))) house"
    }
    private func names(_ grahas: [Graha]) -> String { grahas.map { Names.lords[$0.id] ?? $0.name }.joined(separator: ", ") }

    var body: some View {
        let seven = Array(chart.grahas.prefix(7))
        let lagnaLord = chart.lord(ofHouse: 1), lord = chart.graha(lagnaLord)
        let moon = chart.graha("Mo"), sun = chart.graha("Su")
        let ranked = seven.indices.sorted { chart.strengthRatio($0) > chart.strengthRatio($1) }
        let high = seven.filter { $0.status == "Exalt." || $0.status == "Own" }, low = seven.filter { $0.status == "Debil." }
        let back = seven.filter(\.retro), burnt = seven.filter { $0.combust == true }
        let day = store.viewDay ?? chart.jd, running = Vimshottari.running(at: day, in: chart.dasha, depth: 2)
        VStack(alignment: .leading, spacing: 12) {
            line("The lagna", "\(Names.signs[chart.asc.sign]) rises, \(Lore.sign(chart.asc.sign).lowercased()) Its lord, \(Names.lords[lagnaLord] ?? lagnaLord), stands in \(lord.map(placed) ?? "").") {
                signChip(chart.asc.sign); chip(lagnaLord)
            }
            if let moon {
                line("The Moon", "The Moon is in \(placed(moon)), in the nakshatra \(moon.nak_name), pada \(moon.pada). \(Lore.nakshatra(moon.nak))") {
                    chip("Mo"); signChip(moon.sign)
                }
            }
            if let sun {
                line("The Sun", "The Sun is in \(placed(sun)). The Moon is \(chart.day.tithi < 15 ? "waxing" : "waning"): the birth fell on \(Names.tithi(chart.day.tithi)).") {
                    chip("Su"); signChip(sun.sign)
                }
            }
            line("Condition of the grahas",
                 [high.isEmpty ? nil : "In their own or exalted signs: \(names(high)).", low.isEmpty ? nil : "Debilitated: \(names(low)).",
                  back.isEmpty ? nil : "Retrograde: \(names(back)).", burnt.isEmpty ? nil : "Combust: \(names(burnt)).",
                  high.isEmpty && low.isEmpty && back.isEmpty && burnt.isEmpty ? "None is exalted, in its own sign, debilitated, retrograde or combust." : nil].compactMap { $0 }.joined(separator: " ")) {
                ForEach(high + low + back.filter { g in !(high + low).contains { $0.id == g.id } }) { chip($0.id) }
            }
            if let first = ranked.first, let last = ranked.last {
                line("Strength", String(format: "By shadbala %@ is strongest at %.2f times what is required, and %@ weakest at %.2f.",
                                        Names.lords[seven[first].id] ?? "", chart.strengthRatio(first), Names.lords[seven[last].id] ?? "", chart.strengthRatio(last))) {
                    chip(seven[first].id); chip(seven[last].id); GoLink(title: "Open Strength", workspace: "Strength")
                }
            }
            line("Yogas", chart.yogas.isEmpty ? "None of the yogas the app knows is formed." : "\(chart.yogas.count) are formed, among them \(chart.yogas.prefix(3).map(\.name).joined(separator: ", ")).") {
                GoLink(title: "Open Yogas", workspace: "Yogas")
            }
            if running.count == 2 {
                let maha = running[0].lord, antar = running[1].lord, ruled = chart.housesRuled(by: maha)
                let standing = chart.graha(maha).map { " and stands in the \(Chart.ordinal(chart.house(ofSign: $0.sign)))" } ?? ""
                line(store.atBirth ? "The time at birth" : "The time under view",
                     "The mahadasha of \(Names.lords[maha] ?? maha) is running, with the antardasha of \(Names.lords[antar] ?? antar). \(Names.lords[maha] ?? maha) \(ruled.isEmpty ? "rules no house" : "rules the " + ruled.map(Chart.ordinal).joined(separator: " and "))\(standing).") {
                    chip(maha); chip(antar); GoLink(title: "Open Dasha", workspace: "Dasha", pick: .period(lords: [maha], start: running[0].start, end: running[0].end))
                }
            }
            Text(Lore.balance).font(.footnote).foregroundStyle(.secondary)
        }
    }
}

/// The twelve houses: what each covers, and the four things a reader looks at for it.
struct HousesCard: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    var body: some View {
        ScrollView(.horizontal) {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                ForEach([("House", 126.0), ("Sign", 80.0), ("Its lord, and where it stands", 176.0), ("Grahas in it", 86.0), ("Aspected by", 84.0), ("Bindus", 44.0)], id: \.0) { title, width in
                    Text(title).font(.caption).foregroundStyle(.secondary).frame(width: width, alignment: .leading).help(Help.term(title) ?? "")
                }
            }
            .padding(.horizontal, 6)
            ForEach(1...12, id: \.self) { house in
                let sign = chart.sign(ofHouse: house), lord = chart.lord(ofHouse: house), lordAt = chart.graha(lord)
                let chosen = store.pick == .sign(sign), near = store.hover == .sign(sign)
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 0) {
                        Text("\(house) · \(Lore.houseNames[house - 1])").fontWeight(.medium).frame(width: 126, alignment: .leading)
                        Text(Names.signs[sign]).frame(width: 80, alignment: .leading)
                        HStack(spacing: 4) {
                            Text(Names.lords[lord] ?? lord).foregroundStyle(Tint.graha(lord)).onTapGesture { store.pick = .graha(lord) }
                            Text(lordAt.map { "in the \(Chart.ordinal(chart.house(ofSign: $0.sign)))" + ($0.status.map { s in s == "Neutr." ? "" : ", \(s)" } ?? "") } ?? "").foregroundStyle(.secondary)
                        }
                        .frame(width: 176, alignment: .leading)
                        Text(chart.occupants(ofHouse: house).map(\.id).joined(separator: " ")).frame(width: 86, alignment: .leading)
                        Text(chart.aspecting(sign: sign).joined(separator: " ")).frame(width: 84, alignment: .leading)
                        Text("\(chart.sarva[sign])").foregroundStyle(chart.sarva[sign] >= 30 ? AnyShapeStyle(.green) : chart.sarva[sign] <= 24 ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
                            .frame(width: 44, alignment: .leading)
                    }
                    if store.showHelp || chosen {
                        Text("\(Lore.houses[house - 1].prefix(1).uppercased() + Lore.houses[house - 1].dropFirst()). It is \(Lore.houseKind(house)).")
                            .font(.footnote).foregroundStyle(.secondary).frame(width: 596, alignment: .leading).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 3).padding(.horizontal, 6)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.accentColor.opacity(chosen ? 0.22 : near ? 0.09 : 0)))
                .contentShape(Rectangle())
                .onTapGesture { store.pick = .sign(sign) }
                .onHover { inside in store.hover = inside ? .sign(sign) : (store.hover == .sign(sign) ? nil : store.hover) }
            }
        }
        .monospacedDigit()
        }
    }
}
