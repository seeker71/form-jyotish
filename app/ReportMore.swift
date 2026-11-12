import SwiftUI

/// The report's further pages: the sixteen divisional charts, Vimshottari to the sookshma dasha,
/// Krishnamurti Paddhati, and the transits.
extension Report {
    func dateText(_ julianDay: Double, _ format: String = "dd-MM-yyyy") -> String { text(Names.date(julianDay: julianDay), format) }
    func age(_ julianDay: Double, spaced: Bool = false) -> String {
        let months = Int(max(0, julianDay - chart.jd) / 365.25 * 12 + 0.001)
        return spaced ? "\(months / 12)y \(months % 12)m" : "\(months / 12)y\(months % 12)m"
    }
    func lordText(_ code: String, three: Bool = false) -> Text {
        Text((three ? Names.lordsThree[code] : Names.lords[code]) ?? code).foregroundColor(Ink.graha(code))
    }
    func title(_ words: String, y: CGFloat) -> some View {
        Text(words).font(Ink.times(14.5)).foregroundColor(Ink.maroon).centred(from: 50, to: 548, y: y)
    }
    func band(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Ink.band).frame(width: width, height: height).at(x, y)
            Rectangle().fill(Ink.rule).frame(width: width, height: 0.7).at(x, y)
            Rectangle().fill(Ink.rule).frame(width: width, height: 0.7).at(x, y + height)
        }
    }
    func rule(x: CGFloat, y: CGFloat, width: CGFloat) -> some View { Rectangle().fill(Ink.rule).frame(width: width, height: 0.7).at(x, y) }

    // MARK: divisional charts

    func vargaHouses(_ index: Int, of chart: Chart) -> (first: Int, houses: [[Mark]]) {
        let first = chart.asc.vargas[index]
        var bySign = [[Mark]](repeating: [], count: 12)
        bySign[first].append(Mark(code: "As"))
        for graha in chart.grahas + chart.outer {
            let node = graha.id == "Ra" || graha.id == "Ke"
            bySign[graha.vargas[index]].append(Mark(code: graha.id + (graha.retro && !node ? "R" : "")))
        }
        bySign[chart.bhrigu.vargas[index]].append(Mark(code: "BP"))
        return (first, houses(bySign, first: first))
    }

    var vargaPages: [(Int) -> AnyView] {
        (0..<2).map { half in
            { number in
                self.page(number, title: "Divisional Charts #\(half + 1)") {
                    ForEach(0..<8, id: \.self) { slot in
                        let index = half * 8 + slot, varga = self.vargaHouses(index, of: self.chart)
                        let x: CGFloat = slot % 2 == 0 ? 64 : 312, y = 62 + CGFloat(slot / 2) * 164
                        Text(Names.vargas[index]).font(Ink.times(13.5)).foregroundColor(Ink.maroon).at(x, y)
                        NorthPanel(firstSign: varga.first, houses: varga.houses, codeSize: 11).frame(width: 222, height: 140).at(x, y + 19)
                    }
                }
            }
        }
    }

    // MARK: Vimshottari

    /// One table of nine sub-periods: a heading, an optional line under it, and the dated rows.
    func dashaBlock(heading: Text, corner: String = "", note: String = "", rows: [Period], x: CGFloat, y: CGFloat) -> some View {
        let top = y + (note.isEmpty ? 17 : 31)
        return ZStack(alignment: .topLeading) {
            heading.font(Ink.times(11.5)).bold().at(x, y)
            Text(corner).font(Ink.times(11.5)).foregroundColor(Ink.maroon).frame(width: 140, alignment: .trailing).at(x, y)
            Text(note).font(Ink.times(10.3)).foregroundColor(Ink.maroon).at(x, y + 15)
            band(x: x, y: top, width: 140, height: 18)
            HStack(spacing: 0) {
                Text("Antar").frame(width: 43, alignment: .leading)
                Text("Beginning").frame(width: 50, alignment: .leading)
                Text("Ending").frame(width: 47, alignment: .leading)
            }
            .font(Ink.times(9.8)).bold().at(x + 1, top + 3)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(rows.indices, id: \.self) { index in
                    let row = rows[index], shown = row.end > chart.jd
                    HStack(spacing: 0) {
                        lordText(row.lord).frame(width: 42, alignment: .leading)
                        Text(shown ? dateText(max(row.start, chart.jd)) : "").frame(width: 50, alignment: .leading)
                        Text(shown ? dateText(row.end) : "").frame(width: 48, alignment: .leading)
                    }
                    .frame(height: 14.4)
                }
            }
            .font(Ink.times(10)).at(x, top + 24)
            rule(x: x, y: top + 24 + 9 * 14.4 + 2, width: 140)
        }
    }

    func mahaPage(_ number: Int) -> AnyView {
        let running = Vimshottari.running(at: chart.jd, in: chart.dasha, depth: 5)
        let balance = running.first.map { "\(Names.lords[$0.lord] ?? $0.lord) \(Vimshottari.span(days: $0.end - chart.jd))" } ?? ""
        return page(number, title: "Vimshottari MD and AD") {
            title("Vimshottari Mahadasha and Antardashas", y: 76)
            facts([("Dasha balance at birth", balance, false), ("Dasha at the time of birth", running.map(\.lord).joined(separator: "-"), false)], x: 200, y: 97, labelWidth: 118)
            ForEach(chart.dasha.indices, id: \.self) { index in
                let maha = chart.dasha[index], years = Int(Vimshottari.years[Vimshottari.order.firstIndex(of: maha.lord) ?? 0])
                dashaBlock(heading: lordText(maha.lord) + Text(" (\(years)y)").foregroundColor(Ink.graha(maha.lord)),
                           note: "From \(maha.start <= chart.jd ? "0 yrs." : age(maha.start)) to \(age(maha.end))",
                           rows: Vimshottari.parts(of: maha), x: 64 + CGFloat(index % 3) * 164, y: 134 + CGFloat(index / 3) * 200)
            }
        }
    }

    func antarPage(_ maha: Period, part: Int) -> (Int) -> AnyView {
        { number in
            let antars = Vimshottari.parts(of: maha)
            return self.page(number, title: "Vimshottari Detailed AD and PD #\(part)") {
                self.title("Vimshottari Antardasha and Pratyantardashas", y: 76)
                (self.lordText(maha.lord).bold() + Text("  Mahadasha \(self.dateText(max(maha.start, self.chart.jd))) to \(self.dateText(maha.end))"))
                    .font(Ink.times(10.8)).centred(from: 50, to: 548, y: 95)
                Text("Age : \(self.age(maha.start, spaced: true)) to \(self.age(maha.end, spaced: true))").font(Ink.times(10.8)).centred(from: 50, to: 548, y: 108)
                ForEach(antars.indices, id: \.self) { index in
                    let antar = antars[index]
                    self.dashaBlock(heading: self.lordText(maha.lord) + Text("-") + self.lordText(antar.lord),
                                    corner: antar.start > self.chart.jd ? self.age(antar.start) : "",
                                    rows: Vimshottari.parts(of: antar), x: 64 + CGFloat(index % 3) * 164, y: 136 + CGFloat(index / 3) * 200)
                }
            }
        }
    }

    /// Thirty-six pratyantardashas from the one running on the day the report is made, each with its sookshma dashas.
    func sookshmaPages() -> [(Int) -> AnyView] {
        let all = chart.dasha.flatMap { maha in Vimshottari.parts(of: maha).flatMap { antar in Vimshottari.parts(of: antar).map { (maha.lord, antar.lord, $0) } } }
        let today = Date().timeIntervalSince1970 / 86400 + 2440587.5
        let first = min(all.firstIndex { $0.2.holds(today) } ?? 0, max(0, all.count - 36))
        let shown = Array(all[first..<min(first + 36, all.count)])
        return (0..<3).map { part in
            { number in
                self.page(number, title: "Vimshottari Dasha – PD and Sookshma #\(part + 1)") {
                    self.title("Vimshottari Pratyantardasha and Sookshma Dasha", y: 76)
                    Text("Each date is the day and time a sookshma dasha begins.").font(Ink.times(8.5)).centred(from: 50, to: 548, y: 96)
                    ForEach(0..<12, id: \.self) { slot in
                        if part * 12 + slot < shown.count {
                            let entry = shown[part * 12 + slot], x = 64 + CGFloat(slot % 4) * 119.5, y = 116 + CGFloat(slot / 4) * 201
                            (self.lordText(entry.0, three: true) + Text("-") + self.lordText(entry.1, three: true) + Text("-") + self.lordText(entry.2.lord, three: true))
                                .font(Ink.times(11)).bold().at(x, y)
                            self.band(x: x, y: y + 14, width: 111, height: 25)
                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 0) { Text("Beginning").frame(width: 56, alignment: .leading); Text(self.dateText(entry.2.start)).frame(width: 55, alignment: .trailing) }
                                HStack(spacing: 0) { Text("Ending").frame(width: 56, alignment: .leading); Text(self.dateText(entry.2.end)).frame(width: 55, alignment: .trailing) }
                            }
                            .font(Ink.times(9.8)).bold().at(x, y + 15)
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Vimshottari.parts(of: entry.2)) { sookshma in
                                    HStack(spacing: 0) {
                                        self.lordText(sookshma.lord, three: true).frame(width: 30, alignment: .leading)
                                        Text(self.dateText(sookshma.start, "dd-MM-yyyy HH:mm")).frame(width: 81, alignment: .trailing)
                                    }
                                    .frame(height: 12.4)
                                }
                            }
                            .font(Ink.times(9.8)).at(x, y + 43)
                            self.rule(x: x, y: y + 43 + 9 * 12.4 + 2, width: 111)
                        }
                    }
                }
            }
        }
    }

    var dashaPages: [(Int) -> AnyView] {
        [mahaPage] + chart.dasha.enumerated().map { antarPage($1, part: $0 + 1) } + sookshmaPages()
    }

    // MARK: Krishnamurti Paddhati

    func lordCells(_ p: (String, String, String, String)) -> some View {
        HStack(spacing: 0) {
            ForEach([p.0, p.1, p.2, p.3].indices, id: \.self) { index in
                let code = [p.0, p.1, p.2, p.3][index]
                Text(code).foregroundColor(Ink.graha(code)).frame(width: 24, alignment: .leading)
            }
        }
    }

    func kpChartPage(_ number: Int) -> AnyView {
        struct Row { var name: String; var code: String; var flags: String; var sign: Int; var deg: Double; var nak: String; var pada: Int; var lords: (String, String, String, String) }
        let kp = chart.kp, reading = KPReading(kp: kp), lagna = kp.cusps[0]
        var rows = [Row(name: "Lagna", code: "La", flags: "", sign: lagna.sign, deg: lagna.deg, nak: lagna.nak_name, pada: lagna.pada, lords: (lagna.rasi_lord, lagna.nak_lord, lagna.sub_lord, lagna.sub_sub))]
        for g in kp.grahas + kp.outer {
            let node = g.id == "Ra" || g.id == "Ke"
            rows.append(Row(name: Names.lords[g.id] ?? g.name, code: g.id, flags: (g.retro && !node ? "R" : "") + (g.combust == true ? "C" : ""),
                            sign: g.sign, deg: g.deg, nak: g.nak_name, pada: g.pada, lords: (g.rasi_lord, g.nak_lord, g.sub_lord, g.sub_sub)))
        }
        var bySign = [[Mark]](repeating: [], count: 12), byHouse = [[Mark]](repeating: [], count: 12)
        bySign[lagna.sign].append(Mark(code: "As")); byHouse[0].append(Mark(code: "As"))
        for g in kp.grahas + kp.outer {
            let mark = Mark(code: g.id + (g.retro && g.id != "Ra" && g.id != "Ke" ? "R" : ""))
            bySign[g.sign].append(mark); byHouse[reading.house(of: g.lon)].append(mark)
        }
        let widths: [CGFloat] = [66, 34, 30, 58, 98, 28]
        let heads = ["Sign", "Degree", "Nakshatra", "Pada", "RL", "NL", "SL", "SS"]
        let headWidths: [CGFloat] = [30, 58, 98, 28, 24, 24, 24, 24]
        return page(number, title: "Krishnamurti Paddhati - Chart") {
            title("Krishnamurti Paddhati", y: 76)
            rule(x: 65, y: 95, width: 468)
            Text("\(text(moment, "d MMMM yyyy")) • \(text(moment, "HH:mm")) hrs. • \(birth.place)").font(Ink.times(11.5)).foregroundColor(Ink.maroon).centred(from: 50, to: 548, y: 103)
            band(x: 100, y: 120, width: 398, height: 17)
            HStack(spacing: 0) {
                Text("Planet").frame(width: widths[0], alignment: .leading); Text("R/C").frame(width: widths[1], alignment: .leading)
                ForEach(heads.indices, id: \.self) { Text(heads[$0]).frame(width: headWidths[$0], alignment: .leading) }
            }
            .font(Ink.times(10.5)).bold().at(110, 123)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(rows.indices, id: \.self) { index in
                    let row = rows[index]
                    HStack(spacing: 0) {
                        Text(row.name).foregroundColor(Ink.graha(row.code)).frame(width: widths[0], alignment: .leading)
                        Text(row.flags).frame(width: widths[1], alignment: .leading)
                        Text(Names.signsShort[row.sign]).frame(width: widths[2], alignment: .leading)
                        Text(Names.colons(row.deg)).frame(width: widths[3], alignment: .leading)
                        Text(row.nak).frame(width: widths[4], alignment: .leading)
                        Text("\(row.pada)").frame(width: widths[5], alignment: .leading)
                        lordCells(row.lords)
                    }
                    .frame(height: 13.7)
                }
            }
            .font(Ink.times(10.6)).at(110, 141)
            rule(x: 100, y: 322, width: 398)
            Text("Birth Chart").font(Ink.times(13.5)).foregroundColor(Ink.maroon).centred(from: 64, to: 286, y: 328)
            NorthPanel(firstSign: lagna.sign, houses: houses(bySign, first: lagna.sign), codeSize: 12).frame(width: 222, height: 150).at(64, 346)
            Text("Cuspal Chart").font(Ink.times(13.5)).foregroundColor(Ink.maroon).centred(from: 312, to: 534, y: 328)
            NorthPanel(firstSign: lagna.sign, houses: byHouse, codeSize: 12, numbered: false).frame(width: 222, height: 150).at(312, 346)
            title("Bhava Details (Placidus System)", y: 508)
            band(x: 100, y: 528, width: 398, height: 17)
            HStack(spacing: 0) {
                Text("House cusp").frame(width: widths[0] + widths[1], alignment: .leading)
                ForEach(heads.indices, id: \.self) { Text(heads[$0]).frame(width: headWidths[$0], alignment: .leading) }
            }
            .font(Ink.times(10.5)).bold().at(110, 531)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(kp.cusps.indices, id: \.self) { index in
                    let cusp = kp.cusps[index]
                    HStack(spacing: 0) {
                        Text("\(index + 1).\(Self.ordinals[index])").frame(width: widths[0] + widths[1], alignment: .leading)
                        Text(Names.signsShort[cusp.sign]).frame(width: widths[2], alignment: .leading)
                        Text(Names.colons(cusp.deg)).frame(width: widths[3], alignment: .leading)
                        Text(cusp.nak_name).frame(width: widths[4], alignment: .leading)
                        Text("\(cusp.pada)").frame(width: widths[5], alignment: .leading)
                        lordCells((cusp.rasi_lord, cusp.nak_lord, cusp.sub_lord, cusp.sub_sub))
                    }
                    .frame(height: 13.7)
                }
            }
            .font(Ink.times(10.6)).at(110, 550)
            rule(x: 100, y: 717, width: 398)
        }
    }

    static let ordinals = ["First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth", "Ninth", "Tenth", "Eleventh", "Twelfth"]

    func kpSignificatorPage(_ number: Int) -> AnyView {
        let kp = chart.kp, reading = KPReading(kp: kp), lagna = kp.cusps[0], moon = kp.grahas.first { $0.id == "Mo" }
        // the Hindu day runs from sunrise: a birth before the day's sunrise belongs to the weekday before
        let weekday = (Calendar(identifier: .gregorian).dateComponents(in: zone, from: moment).weekday ?? 1) - 1
        let dayLord = Names.weekdayLords[(weekday + (chart.day.sunrise.map { chart.jd < $0 } == true ? 6 : 0)) % 7]
        let balance = moon.map { Vimshottari.balance(moon: $0.lon, at: chart.jd) }
        let full = { (code: String?) in code.flatMap { Names.lords[$0] } ?? "" }
        let ruling: [(String, String?)] = [("Day lord", dayLord), ("Lagna lord", lagna.rasi_lord), ("Lagna Nak Lord", lagna.nak_lord), ("Lagna Sub Lord", lagna.sub_lord),
                                           ("Moon Rashi lord", moon?.rasi_lord), ("Moon Nak. lord", moon?.nak_lord), ("Moon Sub lord", moon?.sub_lord)]
        let join = { (codes: [String]) in codes.joined(separator: ",") }
        let numbers = { (houses: [Int]) in houses.map(String.init).joined(separator: "  ") }
        return page(number, title: "Krishnamurti Paddhati - Significators") {
            title("Krishnamurti Paddhati", y: 76)
            rule(x: 65, y: 95, width: 468)
            title("Significations of the Houses", y: 110)
            band(x: 76, y: 130, width: 446, height: 30)
            HStack(alignment: .top, spacing: 0) {
                Text("House").frame(width: 84, alignment: .leading); Text("Planets in nak.\nof occupants").frame(width: 100, alignment: .leading)
                Text("Occupants").frame(width: 76, alignment: .leading); Text("Planets in nak.\nof cusp sign lord").frame(width: 100, alignment: .leading)
                Text("Cusp sign lord").frame(width: 80, alignment: .leading)
            }
            .font(Ink.times(10.5)).bold().at(86, 133)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<12, id: \.self) { house in
                    let row = reading.houseRow(house)
                    HStack(spacing: 0) {
                        Text("\(house + 1). \(Self.ordinals[house])").frame(width: 84, alignment: .leading)
                        Text(join(row.starsOfOccupants)).frame(width: 100, alignment: .leading)
                        Text(join(row.occupants)).frame(width: 76, alignment: .leading)
                        Text(join(row.starsOfLord)).frame(width: 100, alignment: .leading)
                        Text(row.lord).foregroundColor(Ink.graha(row.lord)).frame(width: 80, alignment: .leading)
                    }
                    .frame(height: 13.6)
                }
            }
            .font(Ink.times(10.8)).at(86, 166)
            rule(x: 76, y: 332, width: 446)
            title("Houses Signified by Planets", y: 352)
            band(x: 76, y: 372, width: 446, height: 44)
            Text("Planet").font(Ink.times(10.5)).bold().at(86, 375)
            Text("Planets as significators of houses").font(Ink.times(10.5)).bold().centred(from: 150, to: 522, y: 375)
            rule(x: 150, y: 389, width: 372)
            HStack(alignment: .top, spacing: 0) {
                ForEach(["Very strong\nsignificator", "Strong\nsignificator", "Normal\nsignificator", "Weak\nsignificator"], id: \.self) { Text($0).frame(width: 88, alignment: .leading) }
            }
            .font(Ink.times(10.5)).bold().at(170, 391)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(kp.grahas) { graha in
                    let s = reading.signified(by: graha)
                    HStack(spacing: 0) {
                        lordText(graha.id).frame(width: 84, alignment: .leading)
                        Text(numbers(s.veryStrong)).frame(width: 88, alignment: .leading); Text(numbers(s.strong)).frame(width: 88, alignment: .leading)
                        Text(numbers(s.normal)).frame(width: 88, alignment: .leading); Text(numbers(s.weak)).frame(width: 88, alignment: .leading)
                    }
                    .frame(height: 13.8)
                }
            }
            .font(Ink.times(10.8)).at(86, 422)
            rule(x: 76, y: 550, width: 446)
            heading("Ruling Planets", from: 76, to: 284, y: 566)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(ruling.indices, id: \.self) { index in
                    HStack(spacing: 0) {
                        Text(ruling[index].0).frame(width: 104, alignment: .leading); Text(":").frame(width: 12, alignment: .leading)
                        Text(full(ruling[index].1)).foregroundColor(Ink.graha(ruling[index].1 ?? ""))
                    }
                    .frame(height: 13.8)
                }
            }
            .font(Ink.times(11)).at(86, 590)
            rule(x: 76, y: 690, width: 208)
            rule(x: 314, y: 585, width: 208)
            facts([("Fortuna", "\(Names.signsShort[kp.fortuna.sign]) \(Names.colons(kp.fortuna.deg))", false),
                   ("Bal. of dasha", balance.map { "\(full($0.lord)) \(Vimshottari.span(days: $0.days))" } ?? "", false),
                   ("KP Ayanamsha", "-" + Names.colons(kp.ayanamsa), false)], x: 324, y: 590, labelWidth: 104)
            rule(x: 314, y: 636, width: 208)
        }
    }

    var kpPages: [(Int) -> AnyView] { [kpChartPage, kpSignificatorPage] }

    // MARK: transits

    func transitPage(_ sky: Chart) -> (Int) -> AnyView {
        { number in
            let lagna = self.chart.asc.sign, moon = self.moonSign
            var bySign = [[Mark]](repeating: [], count: 12)
            bySign[lagna].append(Mark(code: "As"))
            let minutes = { (deg: Double) in String(format: "%02d:%02d", Int(deg), Int(deg * 60) % 60) }
            for g in sky.grahas + sky.outer { bySign[g.sign].append(Mark(code: g.id + (g.retro && g.id != "Ra" && g.id != "Ke" ? "R" : ""), detail: minutes(g.deg))) }
            let heads = ["Planet", "R", "Sign", "Degree", "Speed", "Nakshatra", "Pada", "From Lagna", "From Moon"]
            let widths: [CGFloat] = [58, 18, 28, 50, 54, 94, 30, 62, 62]
            return self.page(number, title: "Transits") {
                self.title("Transits over the Birth Chart", y: 76)
                Text("The sky on \(self.text(Names.date(julianDay: sky.jd), "d MMMM yyyy • HH:mm")) hrs, set in the houses of the birth lagna")
                    .font(Ink.times(11)).foregroundColor(Ink.maroon).centred(from: 50, to: 548, y: 97)
                NorthPanel(firstSign: lagna, houses: self.houses(bySign, first: lagna), codeSize: 14, stacked: true).frame(width: 470, height: 300).at(64, 118)
                self.band(x: 65, y: 440, width: 468, height: 18)
                HStack(spacing: 0) { ForEach(heads.indices, id: \.self) { Text(heads[$0]).frame(width: widths[$0], alignment: .leading) } }
                    .font(Ink.times(10.5)).bold().italic().at(70, 443)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(sky.grahas + sky.outer) { g in
                        HStack(spacing: 0) {
                            Text(Names.lords[g.id] ?? g.name).foregroundColor(Ink.graha(g.id)).frame(width: widths[0], alignment: .leading)
                            Text(g.retro && g.id != "Ra" && g.id != "Ke" ? "R" : "").frame(width: widths[1], alignment: .leading)
                            Text(Names.signsShort[g.sign]).frame(width: widths[2], alignment: .leading)
                            Text(Names.colons(g.deg)).frame(width: widths[3], alignment: .leading)
                            Text(Names.colons(g.speed)).frame(width: widths[4], alignment: .leading)
                            Text(g.nak_name).frame(width: widths[5], alignment: .leading)
                            Text("\(g.pada)").frame(width: widths[6], alignment: .leading)
                            Text("\((g.sign - lagna + 12) % 12 + 1)").frame(width: widths[7], alignment: .leading)
                            Text("\((g.sign - moon + 12) % 12 + 1)").frame(width: widths[8], alignment: .leading)
                        }
                        .frame(height: 13.9)
                    }
                }
                .font(Ink.times(10.8)).at(70, 464)
                self.rule(x: 65, y: 464 + 12 * 13.9 + 3, width: 468)
                Text(self.passingNote(sky)).font(Ink.times(10)).italic().fixedSize(horizontal: false, vertical: true).frame(width: 452, alignment: .leading).at(70, 642)
            }
        }
    }

    /// what the slow grahas are passing over, said as the app says it
    func passingNote(_ sky: Chart) -> String {
        var words = "A transit acts within what the running dasha allows. Houses are counted from the birth lagna and from the birth Moon."
        if let saturn = sky.graha("Sa") {
            let fromMoon = (saturn.sign - moonSign + 12) % 12 + 1
            if [12, 1, 2].contains(fromMoon) { words += " Saturn stands \(Chart.ordinal(fromMoon)) from the Moon: this is Sade Sati, Saturn's passage over the Moon, read as a season for maturing and consolidating." }
            if [4, 8].contains(fromMoon) { words += " Saturn stands \(Chart.ordinal(fromMoon)) from the Moon, a passage traditionally read as a time to simplify and build resilience." }
        }
        return words + " " + Lore.balance
    }

    var transitPages: [(Int) -> AnyView] { transit.map { [transitPage($0), transitReadPage($0)] } ?? [] }
}
