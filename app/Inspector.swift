import SwiftUI

/// Says what the picked thing is, in the birth chart and in the sky of the moment under view.
/// Everything it names can be clicked to pick that in turn.
struct Inspector: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(spacing: 0) {
        TourPanel()
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(store.followPointer && store.hover != nil && store.hover != store.pick ? "Under the pointer. Click to keep it here." : store.pick != nil ? "Picked" : " ")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Toggle("Follow the pointer", isOn: $store.followPointer).toggleStyle(.checkbox).controlSize(.small).font(.caption)
                        .help("On: this panel shows whatever the pointer rests on, and returns to what was clicked when the pointer leaves. Off: it changes only on a click.")
                }
                if let chart = store.chart {
                    switch store.focus {
                    case .graha(let code): grahaPanel(code, chart)
                    case .sign(let sign): signPanel(sign, chart)
                    case .period(let lords, let start, let end): periodPanel(lords, start, end, chart)
                    case nil: help
                    }
                } else {
                    help
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: pieces

    private var help: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Point at anything").font(.title3).fontWeight(.semibold)
            Text("Rest the pointer on a graha, a sign or a dasha period on any card: it is explained here, and every other card shows where it stands. Click to keep it.")
            Text("On a chart, the signs a graha aspects turn orange and the signs it rules turn green. Rest on a yoga and its grahas light up in every chart. Drag a card's title onto another card to rearrange the desk.")
            if store.chart != nil, store.tourAt == nil {
                Button { store.tour(to: 0) } label: { Label("Walk through this chart", systemImage: "figure.walk") }
                    .help("Eleven steps in the order a chart is read. The desk shows each step in this chart while it is explained here.")
            }
            Text("The bar below moves the whole desk through time. Press ⌘K and type to add a card, change a setting, or ask what a word means.")
        }
        .foregroundStyle(.secondary)
    }

    /// One fact: its name and its value. Both can be clicked: the name says what the term means, the value
    /// what this particular reading means (`about`), or the term again where there is no more to say.
    private func fact(_ name: String, _ value: String, about: Explanation? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(name).foregroundStyle(.secondary).underline(true, color: Color.secondary.opacity(0.35)).frame(width: 84, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture { store.explanation = Lore.explain(term: name, chart: store.chart) }
                .help("Click for what \(name.lowercased()) means")
            Text(value).underline(about != nil, color: Color.accentColor.opacity(0.6))
                .contentShape(Rectangle())
                .onTapGesture { store.explanation = about ?? Lore.explain(term: name, chart: store.chart) }
                .help(about == nil ? "Click for what \(name.lowercased()) means" : "Click for what this means")
        }
    }

    private func chip(_ code: String) -> some View {
        Button(Names.lords[code] ?? code) { store.pick = .graha(code) }
            .buttonStyle(.bordered).controlSize(.small).tint(Tint.graha(code))
    }

    private func signChip(_ sign: Int) -> some View {
        Button(Names.signs[sign]) { store.pick = .sign(sign) }.buttonStyle(.bordered).controlSize(.small)
    }

    private func section(_ title: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.subheadline).fontWeight(.semibold).padding(.top, 4).help(Help.term(title) ?? "")
            if store.showHelp, let words = Help.term(title) { Text(words).font(.footnote).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
        }
    }
    private func note(_ words: String) -> some View {
        Group { if store.showHelp, !words.isEmpty { Text(words).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) } }
    }

    private func house(_ sign: Int, from: Int) -> Int { (sign - from + 12) % 12 + 1 }

    // MARK: a graha

    @ViewBuilder private func grahaPanel(_ code: String, _ chart: Chart) -> some View {
        if let g = (chart.grahas + chart.outer).first(where: { $0.id == code }) {
            let moon = chart.graha("Mo")?.sign ?? 0
            Text("\(g.name) · \(Names.lords[g.id] ?? g.id)").font(.title3).fontWeight(.semibold).foregroundStyle(Tint.graha(g.id))
            note(Help.graha(g.id))
            let who = Names.lords[g.id] ?? g.name
            fact("Rasi", "\(Names.signs[g.sign]) \(Names.dms(g.deg))", about: Lore.explain(sign: g.sign, in: chart))
            fact("House", "\(house(g.sign, from: chart.asc.sign)) from the lagna, \(house(g.sign, from: moon)) from the Moon", about: Lore.explain(house: house(g.sign, from: chart.asc.sign), fromMoon: house(g.sign, from: moon)))
            fact("Nakshatra", "\(g.nak_name), pada \(g.pada)", about: Lore.explain(nakshatra: g.nak, pada: g.pada, of: who))
            if let status = g.status { fact("Dignity", status + (g.combust == true ? " · combust" : ""), about: Lore.explain(dignity: status, combust: g.combust == true, of: who, sign: g.sign)) }
            fact("Navamsa", Names.signs[g.navamsa] + (chart.navamsaStanding(g).map { " · \($0.word)" } ?? "") + (g.navamsa == g.sign ? " · vargottama" : ""), about: chart.explainNavamsa(g))
            if let hem = chart.hemming(of: g.sign, except: g.id) { fact("Hemmed", hem.word, about: chart.explainHemming(g)) }
            if !chart.roles(of: g.id).isEmpty || g.id == "Ra" || g.id == "Ke" { fact("Roles", chart.roles(of: g.id).isEmpty ? "through its host" : chart.roles(of: g.id).joined(separator: ", "), about: chart.explainRoles(g.id)) }
            if Lore.signifies[g.id] != nil { fact("Signifies", (Lore.signifies[g.id] ?? "").components(separatedBy: ", ").prefix(3).joined(separator: ", "), about: chart.explainSignifies(g.id)) }
            fact("Motion", String(format: "%+.4f° a day", g.speed) + (g.retro && g.id != "Ra" && g.id != "Ke" ? " · retrograde" : ""))
            if let index = chart.grahas.prefix(7).firstIndex(where: { $0.id == code }) {
                fact("Shadbala", String(format: "%.2f rupas · %.2f × required", chart.rupas(index), chart.strengthRatio(index)))
                fact("Bindus", "\(chart.ashtakavarga[index][g.sign]) of 8 in its own ashtakavarga here")
            }
            if let age = g.baladi, let wake = g.jagradadi, let mood = g.deeptadi { fact("Avasthas", "\(Help.avastha(age)) · \(Help.avastha(wake)) · \(Help.avastha(mood))") }
            let weighed = chart.factors(for: g)
            if !weighed.supports.isEmpty {
                section("What supports it")
                ForEach(weighed.supports, id: \.self) { Label($0, systemImage: "plus.circle").font(.callout).foregroundStyle(.green).labelStyle(FactLabel()) }
            }
            if !weighed.strains.isEmpty {
                section("What asks more of it")
                ForEach(weighed.strains, id: \.self) { Label($0, systemImage: "minus.circle").font(.callout).foregroundStyle(.orange).labelStyle(FactLabel()) }
            }
            if !weighed.supports.isEmpty || !weighed.strains.isEmpty { note(Lore.balance) }
            let ruled = chart.housesRuled(by: code)
            if !ruled.isEmpty { fact("Rules", ruled.map { "the \(Chart.ordinal($0)) (\(Lore.houseNames[$0 - 1].lowercased()))" }.joined(separator: ", ")) }
            note(Lore.nakshatra(g.nak))
            section("Its lords")
            HStack { Text("Rasi").foregroundStyle(.secondary); chip(g.rasi_lord); Text("Star").foregroundStyle(.secondary); chip(g.nak_lord) }
            HStack { Text("Sub").foregroundStyle(.secondary); chip(g.sub_lord); Text("Sub-sub").foregroundStyle(.secondary); chip(g.sub_sub) }
            if let sky = store.sky, let t = (sky.grahas + sky.outer).first(where: { $0.id == code }) {
                section("In the sky of the moment")
                fact("Rasi", "\(Names.signs[t.sign]) \(Names.dms(t.deg))" + (t.retro && t.id != "Ra" && t.id != "Ke" ? " ℞" : ""))
                fact("House", "\(house(t.sign, from: chart.asc.sign)) from the lagna, \(house(t.sign, from: moon)) from the Moon")
            }
            let glances = chart.aspectedSigns(by: code), seenBy = chart.aspecting(sign: g.sign)
            if !glances.isEmpty {
                section("Aspects")
                HStack { ForEach(glances, id: \.self) { signChip($0) } }
            }
            if !seenBy.isEmpty {
                HStack { Text("Aspected by").foregroundStyle(.secondary); ForEach(seenBy, id: \.self) { chip($0) } }
            }
            let formed = chart.yogas.filter { $0.grahas.contains(code) }
            if !formed.isEmpty {
                section("Yogas it forms")
                ForEach(formed) { yoga in Text(yoga.name).font(.callout).help(yoga.why) }
            }
            section("See it elsewhere")
            HStack(spacing: 10) { GoLink(title: "Strength", workspace: "Strength"); GoLink(title: "Yogas", workspace: "Yogas"); GoLink(title: "Houses", workspace: "Guide") }
            section("In the vargas")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), alignment: .leading)], alignment: .leading, spacing: 2) {
                ForEach(0..<16, id: \.self) { index in
                    Text("\(Names.vargaCodes[index]) \(Names.signs[g.vargas[index]])").font(.callout)
                }
            }
            if let maha = chart.dasha.first(where: { $0.lord == code && $0.end > chart.jd }) {
                section("Its mahadasha")
                periodButton([maha.lord], maha, chart)
            }
            if let kpGraha = chart.kp.grahas.first(where: { $0.id == code }) {
                let s = KPReading(kp: chart.kp).signified(by: kpGraha), list = { (h: [Int]) in h.isEmpty ? "none" : h.map(String.init).joined(separator: ", ") }
                section("Houses it signifies (KP)")
                fact("Strong", list(s.veryStrong + s.strong))
                fact("Normal", list(s.normal))
                fact("Weak", list(s.weak))
            }
        }
    }

    // MARK: a sign

    @ViewBuilder private func signPanel(_ sign: Int, _ chart: Chart) -> some View {
        let moon = chart.graha("Mo")?.sign ?? 0
        let lord = Names.weekdayLords[[2, 5, 3, 1, 0, 3, 5, 2, 4, 6, 6, 4][sign]]
        let here = (chart.grahas + chart.outer).filter { $0.sign == sign }
        Text("\(Names.signs[sign]) · \(Names.signsWestern[sign])").font(.title3).fontWeight(.semibold)
        note(Lore.sign(sign))
        fact("House", "\(house(sign, from: chart.asc.sign)) from the lagna, \(house(sign, from: moon)) from the Moon", about: Lore.explain(house: house(sign, from: chart.asc.sign), fromMoon: house(sign, from: moon)))
        if sign == chart.asc.sign { fact("Lagna", "\(Names.dms(chart.asc.deg)) · \(chart.asc.nak_name), pada \(chart.asc.pada)", about: Lore.explain(nakshatra: chart.asc.nak, pada: chart.asc.pada, of: "The lagna")) }
        HStack { Text("Lord").foregroundStyle(.secondary).frame(width: 84, alignment: .leading); chip(lord) }
        fact("Bindus", "\(chart.sarva[sign]) in the sarvashtakavarga (337 over twelve signs)")
        fact("Sign aspects", chart.jaimini.glances[sign].map { Names.signs[$0] }.joined(separator: ", "))
        let padas = (1...12).filter { chart.jaimini.arudhas[$0 - 1] == sign }
        if !padas.isEmpty { fact("Arudhas here", padas.map { $0 == 1 ? "AL" : $0 == 12 ? "UL" : "A\($0)" }.joined(separator: ", ")) }
        if !chart.aspecting(sign: sign).isEmpty { HStack { Text("Aspected by").foregroundStyle(.secondary).frame(width: 84, alignment: .leading); ForEach(chart.aspecting(sign: sign), id: \.self) { chip($0) } } }
        note("The \(Chart.ordinal(chart.house(ofSign: sign))) house covers \(Lore.houses[chart.house(ofSign: sign) - 1]). It is \(Lore.houseKind(chart.house(ofSign: sign))).")
        section(here.isEmpty ? "No graha stands here at birth" : "Here at birth")
        ForEach(here) { g in HStack { chip(g.id); Text(Names.dms(g.deg)).foregroundStyle(.secondary) } }
        if let sky = store.sky {
            let passing = (sky.grahas + sky.outer).filter { $0.sign == sign }
            section(passing.isEmpty ? "No graha passes here at the moment" : "Passing here at the moment")
            ForEach(passing) { g in HStack { chip(g.id); Text(Names.dms(g.deg)).foregroundStyle(.secondary) } }
        }
        let cusps = chart.kp.cusps.indices.filter { chart.kp.cusps[$0].sign == sign }
        if !cusps.isEmpty { fact("KP cusps", cusps.map { "\($0 + 1)" }.joined(separator: ", ")) }
    }

    // MARK: a period

    private func periodButton(_ lords: [String], _ p: Period, _ chart: Chart) -> some View {
        let format = Date.FormatStyle(date: .abbreviated, time: lords.count > 2 ? .shortened : .omitted, timeZone: store.zone)
        return Button {
            store.pick = .period(lords: lords, start: p.start, end: p.end)
            store.go(to: max(p.start, chart.jd) + 0.0001)
        } label: {
            HStack {
                Text(Names.lords[p.lord] ?? p.lord).foregroundStyle(Tint.graha(p.lord)).frame(width: 70, alignment: .leading)
                Text("\(Names.date(julianDay: max(p.start, chart.jd)).formatted(format)) – \(Names.date(julianDay: p.end).formatted(format))").foregroundStyle(.secondary)
            }
            .font(.callout)
        }
        .buttonStyle(.plain)
        .fontWeight(store.viewDay.map(p.holds) == true ? .bold : .regular)
    }

    @ViewBuilder private func periodPanel(_ lords: [String], _ start: Double, _ end: Double, _ chart: Chart) -> some View {
        let levels = ["Mahadasha", "Antardasha", "Pratyantardasha", "Sookshma dasha", "Prana dasha"]
        let format = Date.FormatStyle(date: .abbreviated, time: .shortened, timeZone: store.zone)
        let whole = Period(lord: lords.last ?? "", start: start, end: end, antar: nil)
        Text(lords.map { Names.lords[$0] ?? $0 }.joined(separator: " – ")).font(.title3).fontWeight(.semibold)
        Text(levels[min(lords.count, levels.count) - 1]).foregroundStyle(.secondary)
        note(Help.term(levels[min(lords.count, levels.count) - 1]) ?? "")
        fact("Begins", Names.date(julianDay: max(start, chart.jd)).formatted(format))
        fact("Ends", Names.date(julianDay: end).formatted(format))
        fact("Length", Vimshottari.span(days: end - start))
        HStack {
            Button("Go to its start") { store.go(to: max(start, chart.jd) + 0.0001) }
            ForEach(Array(Set(lords)), id: \.self) { chip($0) }
        }
        if lords.count < 5 {
            section("Its parts")
            ForEach(Vimshottari.parts(of: whole).filter { $0.end > chart.jd }) { part in periodButton(lords + [part.lord], part, chart) }
        }
    }
}

/// A fact with its mark, the mark aligned to the first line.
struct FactLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            configuration.icon
            configuration.title.foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
        }
    }
}
