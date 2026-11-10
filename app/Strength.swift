import SwiftUI

private let seven = ["Su", "Mo", "Ma", "Me", "Ju", "Ve", "Sa"]

/// The six-fold strength: every row for the seven grahas, the sums in bold, then rupas and the share of what is required.
struct ShadbalaTable: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    private func cell(_ text: String, _ index: Int, bold: Bool) -> some View {
        let code = seven[index], chosen = store.pick?.graha == code, near = store.hover?.graha == code
        return Text(text).fontWeight(bold ? .semibold : .regular)
            .frame(width: 62, alignment: .trailing).padding(.vertical, 1.5)
            .background(Color.accentColor.opacity(chosen ? 0.22 : near ? 0.09 : 0))
            .contentShape(Rectangle())
            .onTapGesture { store.pick = .graha(code) }
            .onHover { inside in store.hover = inside ? .graha(code) : (store.hover == .graha(code) ? nil : store.hover) }
    }

    private func row(_ name: String, _ values: [String], bold: Bool = false, secondary: Bool = false) -> some View {
        HStack(spacing: 0) {
            Text(name).fontWeight(bold ? .semibold : .regular).foregroundStyle(secondary ? .secondary : .primary)
                .padding(.leading, bold ? 0 : 12).frame(width: 130, alignment: .leading).help(Help.term(name) ?? "")
            ForEach(0..<7, id: \.self) { cell(values[$0], $0, bold: bold) }
        }
    }

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text("virupas").font(.caption).foregroundStyle(.secondary).frame(width: 130, alignment: .leading)
                    ForEach(0..<7, id: \.self) { index in
                        Text(Names.lords[seven[index]] ?? "").font(.callout).fontWeight(.medium).foregroundStyle(Tint.graha(seven[index])).frame(width: 62, alignment: .trailing)
                    }
                }
                .padding(.bottom, 4)
                ForEach(chart.shadbala) { r in
                    row(r.title, r.values.map { String(format: "%.2f", $0) }, bold: r.isSum)
                    if r.isSum { Divider().frame(width: 130 + 62 * 7).padding(.vertical, 2) }
                }
                row("Rupas", (0..<7).map { String(format: "%.2f", chart.rupas($0)) }, bold: true)
                row("Required", Chart.requiredRupas.map { String(format: "%.1f", $0) }, secondary: true)
                row("Times required", (0..<7).map { String(format: "%.2f", chart.strengthRatio($0)) }, bold: true)
                Text("After B.V. Raman's Graha and Bhava Balas. Planetary war is not read.").font(.footnote).foregroundStyle(.secondary).padding(.top, 6)
            }
            .monospacedDigit()
        }
    }
}

/// Bindus by graha and sign, with the sarvashtakavarga under them. A row picks its graha, a column its sign.
struct AshtakavargaTable: View {
    @EnvironmentObject var store: Store
    let chart: Chart

    private func points(_ value: Int, sign: Int, graha: String?, strong: Int, weak: Int) -> some View {
        let chosen = store.pick == .sign(sign) || (graha != nil && store.pick?.graha == graha)
        let near = store.hover == .sign(sign) || (graha != nil && store.hover?.graha == graha)
        return Text("\(value)")
            .fontWeight(value >= strong ? .semibold : .regular)
            .foregroundStyle(value >= strong ? AnyShapeStyle(.green) : value <= weak ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
            .frame(width: 36, alignment: .center).padding(.vertical, 2)
            .background(Color.accentColor.opacity(chosen ? 0.22 : near ? 0.09 : 0))
            .contentShape(Rectangle())
            .onTapGesture { store.pick = .sign(sign) }
            .onHover { inside in store.hover = inside ? .sign(sign) : (store.hover == .sign(sign) ? nil : store.hover) }
    }

    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text("").frame(width: 110, alignment: .leading)
                    ForEach(0..<12, id: \.self) { sign in
                        Text(Names.signsShort[sign]).font(.caption).foregroundStyle(sign == chart.asc.sign ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary)).frame(width: 36)
                    }
                    Text("Sum").font(.caption).foregroundStyle(.secondary).frame(width: 50, alignment: .trailing)
                }
                .padding(.bottom, 3)
                ForEach(0..<7, id: \.self) { index in
                    HStack(spacing: 0) {
                        Text(Names.lords[seven[index]] ?? "").fontWeight(.medium).foregroundStyle(Tint.graha(seven[index])).frame(width: 110, alignment: .leading)
                            .contentShape(Rectangle()).onTapGesture { store.pick = .graha(seven[index]) }
                        ForEach(0..<12, id: \.self) { sign in points(chart.ashtakavarga[index][sign], sign: sign, graha: seven[index], strong: 5, weak: 2) }
                        Text("\(chart.ashtakavarga[index].reduce(0, +))").foregroundStyle(.secondary).frame(width: 50, alignment: .trailing)
                    }
                }
                Divider().frame(width: 110 + 36 * 12 + 50).padding(.vertical, 3)
                HStack(spacing: 0) {
                    Text("Sarva").fontWeight(.semibold).frame(width: 110, alignment: .leading).help(Help.term("Sarva") ?? "")
                    ForEach(0..<12, id: \.self) { sign in points(chart.sarva[sign], sign: sign, graha: nil, strong: 30, weak: 24) }
                    Text("\(chart.sarva.reduce(0, +))").foregroundStyle(.secondary).frame(width: 50, alignment: .trailing)
                }
                Text("Green marks 5 or more of a graha's 8 bindus, or 30 or more of the sign's total; red marks 2 or fewer, or 24 or fewer. The lagna's sign is tinted.")
                    .font(.footnote).foregroundStyle(.secondary).padding(.top, 6)
            }
            .monospacedDigit()
        }
    }
}

// MARK: report pages

extension Report {
    func shadbalaPage(_ number: Int) -> AnyView {
        let column: CGFloat = 47, left: CGFloat = 76, first: CGFloat = 196
        let line = { (name: String, values: [String], bold: Bool, y: CGFloat) -> AnyView in
            AnyView(HStack(spacing: 0) {
                Text(name).frame(width: first - left - (bold ? 0 : 0), alignment: .leading).padding(.leading, bold ? 0 : 10).frame(width: first - left, alignment: .leading)
                ForEach(0..<7, id: \.self) { Text(values[$0]).frame(width: column, alignment: .trailing) }
            }
            .font(Ink.times(10.8)).fontWeight(bold ? .bold : .regular).at(left, y))
        }
        var y: CGFloat = 132
        var rows: [AnyView] = []
        for r in chart.shadbala {
            rows.append(line(r.title, r.values.map { String(format: "%.2f", $0) }, r.isSum, y))
            y += r.isSum ? 21 : 14
        }
        let after = y + 4
        return page(number, title: "Shad Bala") {
            title("Shad Bala", y: 76)
            band(x: 65, y: 104, width: 468, height: 18)
            HStack(spacing: 0) {
                Text("").frame(width: first - left, alignment: .leading)
                ForEach(0..<7, id: \.self) { lordText(seven[$0]).frame(width: column, alignment: .trailing) }
            }
            .font(Ink.times(10.5)).bold().at(left, 107)
            ForEach(rows.indices, id: \.self) { rows[$0] }
            rule(x: 65, y: after, width: 468)
            line("Shadbala in Rupas", (0..<7).map { String(format: "%.2f", chart.rupas($0)) }, true, after + 8)
            line("Minimum requirement", Chart.requiredRupas.map { String(format: "%.1f", $0) }, false, after + 24)
            line("Times the requirement", (0..<7).map { String(format: "%.2f", chart.strengthRatio($0)) }, true, after + 40)
            rule(x: 65, y: after + 58, width: 468)
            Text("Read after B.V. Raman's Graha and Bhava Balas, in virupas (sixtieths of a rupa). Planetary war is not read.")
                .font(Ink.times(9)).italic().at(left, after + 64)
        }
    }

    func ashtakavargaPage(_ number: Int) -> AnyView {
        let column: CGFloat = 30, left: CGFloat = 76, first: CGFloat = 138
        let line = { (name: Text, values: [Int], bold: Bool, y: CGFloat) -> AnyView in
            AnyView(HStack(spacing: 0) {
                name.frame(width: first - left, alignment: .leading)
                ForEach(0..<12, id: \.self) { Text("\(values[$0])").frame(width: column, alignment: .center) }
                Text("\(values.reduce(0, +))").frame(width: 34, alignment: .trailing)
            }
            .font(Ink.times(11)).fontWeight(bold ? .bold : .regular).at(left, y))
        }
        return page(number, title: "Ashtakavarga") {
            title("Ashtakavarga: Bhinnashtakavarga and Sarvashtakavarga", y: 76)
            band(x: 65, y: 104, width: 468, height: 18)
            HStack(spacing: 0) {
                Text("Sign").frame(width: first - left, alignment: .leading)
                ForEach(0..<12, id: \.self) { Text(Names.signsShort[$0]).foregroundColor($0 == chart.asc.sign ? Ink.maroon : .black).frame(width: column, alignment: .center) }
                Text("Sum").frame(width: 34, alignment: .trailing)
            }
            .font(Ink.times(10.5)).bold().at(left, 107)
            ForEach(0..<7, id: \.self) { index in line(lordText(seven[index]), chart.ashtakavarga[index], false, 130 + CGFloat(index) * 16) }
            rule(x: 65, y: 246, width: 468)
            line(Text("Sarva"), chart.sarva, true, 252)
            rule(x: 65, y: 272, width: 468)
            Text("Bindus each graha gathers in each sign, counted from the seven grahas and the lagna. The lagna's sign is marked in the heading.")
                .font(Ink.times(9)).italic().frame(width: 440, alignment: .leading).at(left, 278)
        }
    }

    var strengthPages: [(Int) -> AnyView] { [shadbalaPage, ashtakavargaPage] }
}
