import SwiftUI

extension Lore {
    /// Yogini dasha names its periods after eight yoginis, each tied to a graha.
    static let yoginis = ["Mo": "Mangala", "Su": "Pingala", "Ju": "Dhanya", "Ma": "Bhramari", "Me": "Bhadrika", "Sa": "Ulka", "Ve": "Siddha", "Ra": "Sankata"]

    /// what each dasha system is, how its first lord is found, and the condition under which the classics apply it
    static let dashaNotes: [String: (basis: String, condition: String)] = [
        "Ashtottari": ("108 years over eight grahas (Ketu is left out). Each graha rules a run of three or four nakshatras from Ardra.",
                       "Rahu, not in the lagna, stands in an angle or trine from the lagna's lord."),
        "Yogini": ("36 years over eight yoginis, each tied to a graha, repeating. The Moon's nakshatra number plus three, cast out by eight, names the first.",
                   "Used for any chart, often as a second opinion beside Vimshottari."),
        "Shodashottari": ("116 years over eight grahas, counted from Pushya to the Moon's nakshatra.",
                          "The lagna is in the Moon's hora with a birth in the waning half, or in the Sun's hora with a birth in the waxing half."),
        "Dwadashottari": ("112 years over eight grahas (Venus is left out), counted from the Moon's nakshatra to Revati.",
                          "The lagna falls in a navamsa of Venus (Vrishabha or Tula)."),
        "Panchottari": ("105 years over seven grahas, counted from Anuradha to the Moon's nakshatra.",
                        "The lagna is Karka and falls in the dwadasamsa of Karka."),
        "Shatabdika": ("100 years over seven grahas, counted from Revati to the Moon's nakshatra.",
                       "The lagna is vargottama: the same sign in the birth chart and the navamsa."),
        "Chaturashiti-sama": ("84 years, twelve to each of seven grahas, counted from Swati to the Moon's nakshatra.",
                              "The lord of the 10th house stands in the 10th."),
        "Dwisaptati-sama": ("72 years, nine to each of eight grahas, counted from Mula to the Moon's nakshatra.",
                            "The lagna's lord stands in the 7th, or the 7th's lord in the lagna."),
        "Shat-trimsha-sama": ("36 years over eight grahas, counted from Shravana to the Moon's nakshatra.",
                              "A day birth with the lagna in the Sun's hora, or a night birth with the lagna in the Moon's hora."),
    ]
}

extension Chart {
    /// Whether the classical condition for a dasha system holds in this chart; nil where there is none.
    func dashaApplies(_ system: String) -> Bool? {
        let lagnaLord = graha(lord(ofHouse: 1)), waning = day.tithi >= 15, sunHora = asc.vargas[1] == 4
        let byDay = (day.sunrise.map { jd >= $0 } ?? true) && (day.sunset.map { jd < $0 } ?? true)
        switch system {
        case "Ashtottari":
            guard let rahu = graha("Ra"), let lord = lagnaLord else { return nil }
            return rahu.sign != asc.sign && [0, 3, 4, 6, 8, 9].contains((rahu.sign - lord.sign + 12) % 12)
        case "Shodashottari": return waning ? !sunHora : sunHora
        case "Dwadashottari": return asc.navamsa == 1 || asc.navamsa == 6
        case "Panchottari": return asc.sign == 3 && asc.vargas[7] == 3
        case "Shatabdika": return asc.navamsa == asc.sign
        case "Chaturashiti-sama": return graha(lord(ofHouse: 10)).map { house(ofSign: $0.sign) == 10 } ?? false
        case "Dwisaptati-sama": return (lagnaLord.map { house(ofSign: $0.sign) == 7 } ?? false) || (graha(lord(ofHouse: 7)).map { house(ofSign: $0.sign) == 1 } ?? false)
        case "Shat-trimsha-sama": return byDay ? sunHora : !sunHora
        default: return nil
        }
    }
}

/// The dasha systems beside Vimshottari: what each is, when the classics apply it, and its periods.
struct OtherDashas: View {
    @EnvironmentObject var store: Store
    let chart: Chart
    @AppStorage("dashaSystem") private var system = "Yogini"
    @State private var open: Set<String> = []

    private func name(_ code: String, in system: String) -> String {
        let graha = Names.lords[code] ?? code
        return system == "Yogini" ? "\(Lore.yoginis[code] ?? "") (\(graha))" : graha
    }

    var body: some View {
        let format = Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: store.zone)
        let chosen = chart.dashas.first { $0.name == system } ?? chart.dashas.first
        let day = store.viewDay ?? chart.jd
        VStack(alignment: .leading, spacing: 8) {
            Picker("System", selection: $system) { ForEach(chart.dashas, id: \.name) { Text("\($0.name) (\($0.years)y)").tag($0.name) } }
                .labelsHidden().frame(width: 260).help("Choose a dasha system")
            if let chosen, let note = Lore.dashaNotes[chosen.name] {
                Text(note.basis).fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if let applies = chart.dashaApplies(chosen.name) {
                        Image(systemName: applies ? "checkmark.circle" : "circle.dashed").foregroundStyle(applies ? .green : .secondary)
                        Text("Applied when: \(note.condition) In this chart that \(applies ? "holds" : "does not hold").").foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    } else {
                        Image(systemName: "checkmark.circle").foregroundStyle(.green)
                        Text(note.condition).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    }
                }
                if let maha = chosen.periods.first(where: { $0.holds(day) }), let antar = maha.antar?.first(where: { $0.holds(day) }) {
                    Text("Running \(store.atBirth ? "at birth" : "at the moment under view"): \(name(maha.lord, in: chosen.name)) – \(name(antar.lord, in: chosen.name)), until \(Names.date(julianDay: antar.end).formatted(format)).")
                        .fontWeight(.medium)
                }
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(chosen.periods.filter { $0.end > chart.jd }) { maha in
                        let running = maha.holds(day)
                        HStack(spacing: 6) {
                            Button { if open.contains(maha.id) { open.remove(maha.id) } else { open.insert(maha.id) } } label: {
                                Image(systemName: open.contains(maha.id) ? "chevron.down" : "chevron.right").frame(width: 12)
                            }
                            .buttonStyle(.plain).accessibilityLabel("Show the sub-periods of \(name(maha.lord, in: chosen.name))")
                            Text(name(maha.lord, in: chosen.name)).foregroundStyle(Tint.graha(maha.lord)).frame(width: 190, alignment: .leading)
                            Text("\(Names.date(julianDay: max(maha.start, chart.jd)).formatted(format)) – \(Names.date(julianDay: maha.end).formatted(format))").foregroundStyle(.secondary)
                        }
                        .fontWeight(running ? .bold : .regular)
                        .padding(.vertical, 1).padding(.horizontal, 4)
                        .contentShape(Rectangle())
                        .onTapGesture { store.pick = .graha(maha.lord); store.go(to: max(maha.start, chart.jd) + 0.001) }
                        .help("Go to the start of this period")
                        if open.contains(maha.id) {
                            ForEach((maha.antar ?? []).filter { $0.end > chart.jd }) { antar in
                                HStack(spacing: 6) {
                                    Text(name(antar.lord, in: chosen.name)).foregroundStyle(Tint.graha(antar.lord)).frame(width: 190, alignment: .leading)
                                    Text("\(Names.date(julianDay: max(antar.start, chart.jd)).formatted(format)) – \(Names.date(julianDay: antar.end).formatted(format))").foregroundStyle(.secondary)
                                }
                                .fontWeight(antar.holds(day) ? .bold : .regular)
                                .padding(.leading, 36)
                                .contentShape(Rectangle())
                                .onTapGesture { store.pick = .graha(antar.lord); store.go(to: max(antar.start, chart.jd) + 0.001) }
                            }
                        }
                    }
                }
                .monospacedDigit()
                Text("Vimshottari is the system most readers use for every chart. The others are read where their condition holds, or as a cross-check.").font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
