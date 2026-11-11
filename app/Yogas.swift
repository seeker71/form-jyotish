import SwiftUI

/// The yogas the chart holds, grouped by kind, each with the rule it met.
struct YogaList: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    private var groups: [(name: String, yogas: [Yoga])] {
        var order: [String] = []
        for yoga in chart.yogas where !order.contains(yoga.group) { order.append(yoga.group) }
        return order.map { group in (group, chart.yogas.filter { $0.group == group }) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Lore.yogaPrinciple).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            if chart.yogas.isEmpty { Text("None of the yogas the engine knows is formed in this chart.").foregroundStyle(.secondary) }
            ForEach(groups, id: \.name) { group in
                VStack(alignment: .leading, spacing: 3) {
                    Text(group.name).font(.subheadline).fontWeight(.semibold).foregroundStyle(.secondary)
                    ForEach(group.yogas) { yoga in
                        let chosen = store.pick?.graha.map(yoga.grahas.contains) ?? false
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(yoga.name).fontWeight(.semibold)
                                ForEach(yoga.grahas, id: \.self) { code in
                                    Text(code).font(.callout).fontWeight(.medium).foregroundStyle(Tint.graha(code))
                                        .onTapGesture { store.pick = .graha(code) }.help(Help.graha(code))
                                }
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(yoga.why + ".").foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                                if let meaning = Lore.yogaMeaning(yoga, in: chart) {
                                    (Text("Tradition: ").fontWeight(.medium) + Text(meaning.tradition)).fixedSize(horizontal: false, vertical: true)
                                    (Text("Read as: ").fontWeight(.medium) + Text(meaning.reading)).fixedSize(horizontal: false, vertical: true)
                                }
                                if let standing = Lore.yogaStanding(yoga, in: chart) { Text(standing).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
                            }
                            .padding(.leading, 12)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 2).padding(.horizontal, 6)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.accentColor.opacity(chosen ? 0.2 : 0)))
                        .contentShape(Rectangle())
                        .onTapGesture { if let first = yoga.grahas.first { store.pick = .graha(first) } }
                        .help("Press ⌘K and type the yoga's name for its rule and meaning")
                    }
                }
            }
        }
    }
}

/// Which signs each graha looks at in full, and which grahas stand there.
struct AspectTable: View {
    let chart: Chart
    private let widths: [CGFloat] = [112, 250, 220]

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                PickRow(pick: nil, cells: zip(["Graha", "Aspects the signs", "And the grahas there"], widths).map { ($0, $1) }, header: true)
                ForEach(Array(chart.grahas.prefix(7).enumerated()), id: \.element.id) { index, g in
                    let signs = chart.aspects[index]
                    let seen = (chart.grahas + chart.outer).filter { signs.contains($0.sign) }.map(\.id)
                    PickRow(pick: .graha(g.id), cells: zip([g.name, signs.map { Names.signs[$0] }.joined(separator: ", "), seen.isEmpty ? "none" : seen.joined(separator: ", ")], widths).map { ($0, $1) },
                            tint: Tint.graha(g.id), retro: g.retro)
                }
            }
        }
    }
}

/// The state each graha is in: by age, by wakefulness, by mood.
struct AvasthaTable: View {
    let chart: Chart
    private let widths: [CGFloat] = [112, 150, 170, 170]

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 1) {
                PickRow(pick: nil, cells: zip(["Graha", "Baladi", "Jagradadi", "Deeptadi"], widths).map { ($0, $1) }, header: true)
                ForEach(chart.grahas.prefix(7)) { g in
                    PickRow(pick: .graha(g.id), cells: zip([g.name, Help.avastha(g.baladi ?? ""), Help.avastha(g.jagradadi ?? ""), Help.avastha(g.deeptadi ?? "")], widths).map { ($0, $1) },
                            tint: Tint.graha(g.id), retro: g.retro)
                }
            }
        }
    }
}
