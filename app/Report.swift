import AppKit
import SwiftUI

/// The report's palette and type: maroon headings, a thin red frame, cream chart panels edged in orange,
/// Times throughout, and one colour per graha.
enum Ink {
    static let maroon = Color(red: 0.58, green: 0.04, blue: 0.04)
    static let rule = Color(red: 0.86, green: 0.12, blue: 0.12)
    static let cream = Color(red: 1.0, green: 0.995, blue: 0.88)
    static let band = Color(red: 0.995, green: 0.93, blue: 0.80)
    static let orange = Color(red: 0.91, green: 0.50, blue: 0.05)

    static func times(_ size: CGFloat) -> Font { .custom("Times New Roman", size: size) }

    static func graha(_ code: String) -> Color {
        switch code.prefix(2) {
        case "Su", "Ma": return Color(red: 0.86, green: 0.0, blue: 0.0)
        case "Me": return Color(red: 0.0, green: 0.5, blue: 0.0)
        case "Ju": return Color(red: 0.93, green: 0.47, blue: 0.0)
        case "Ve": return Color(red: 0.9, green: 0.0, blue: 0.9)
        case "Sa": return Color(red: 0.0, green: 0.0, blue: 0.9)
        case "Ra": return Color(red: 0.33, green: 0.33, blue: 0.45)
        case "Ke", "As", "La": return Color(red: 0.6, green: 0.25, blue: 0.1)
        default: return .black
        }
    }
}

/// One label in a chart: a graha's code in its colour, and optionally its degrees.
struct Mark {
    var code: String
    var detail = ""
    var color: Color { Ink.graha(code) }
}

/// A North Indian chart panel: houses keep their places, the first in the upper diamond.
struct NorthPanel: View {
    /// the sign (0 = Mesha) that stands in the first house
    var firstSign: Int
    /// the marks of each of the twelve houses
    var houses: [[Mark]]
    var codeSize: CGFloat
    /// one mark to a line with its degrees, as the large birth chart shows them
    var stacked = false
    var numbered = true

    private static let centres: [CGPoint] = [
        CGPoint(x: 0.5, y: 0.25), CGPoint(x: 0.25, y: 0.1), CGPoint(x: 0.105, y: 0.25), CGPoint(x: 0.25, y: 0.5),
        CGPoint(x: 0.105, y: 0.75), CGPoint(x: 0.25, y: 0.9), CGPoint(x: 0.5, y: 0.75), CGPoint(x: 0.75, y: 0.9),
        CGPoint(x: 0.895, y: 0.75), CGPoint(x: 0.75, y: 0.5), CGPoint(x: 0.895, y: 0.25), CGPoint(x: 0.75, y: 0.1),
    ]
    private static let inner: [CGPoint] = [
        CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.25, y: 0.25), CGPoint(x: 0.5, y: 0.5),
        CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.25, y: 0.75), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.75),
        CGPoint(x: 0.75, y: 0.75), CGPoint(x: 0.5, y: 0.5), CGPoint(x: 0.75, y: 0.25), CGPoint(x: 0.75, y: 0.25),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Path { path in
                    path.move(to: .zero); path.addLine(to: CGPoint(x: w, y: h))
                    path.move(to: CGPoint(x: w, y: 0)); path.addLine(to: CGPoint(x: 0, y: h))
                    path.move(to: CGPoint(x: w / 2, y: 0)); path.addLine(to: CGPoint(x: w, y: h / 2))
                    path.addLine(to: CGPoint(x: w / 2, y: h)); path.addLine(to: CGPoint(x: 0, y: h / 2)); path.closeSubpath()
                }
                .stroke(Color.black, lineWidth: 0.4)
                ForEach(0..<12, id: \.self) { house in
                    let centre = Self.centres[house], corner = Self.inner[house]
                    Text(numbered ? "\((firstSign + house) % 12 + 1)" : "")
                        .font(.system(size: max(7, codeSize * 0.6)))
                        .position(x: (centre.x + (corner.x - centre.x) * 0.76) * w, y: (centre.y + (corner.y - centre.y) * 0.76) * h)
                    label(houses[house], house: house)
                        .position(x: centre.x * w, y: centre.y * h)
                }
            }
        }
        .padding(4.5)
        .background(Ink.cream)
        .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 0.5).padding(3.6))
        .overlay(Rectangle().strokeBorder(Ink.orange, lineWidth: 2.4).padding(0.6))
        .overlay(Rectangle().strokeBorder(Color.black, lineWidth: 0.5))
    }

    func label(_ marks: [Mark], house: Int) -> some View {
        // a crowded house (the Hora chart holds everything in two signs) sets its marks smaller, more to a line
        let crowded = !stacked && marks.count > 4
        let perRow = stacked ? 1 : crowded ? 4 : (house % 3 == 0 ? 3 : 2)
        let codeSize = crowded ? self.codeSize * 0.62 : self.codeSize
        let rows = stride(from: 0, to: marks.count, by: perRow).map { Array(marks[$0..<min($0 + perRow, marks.count)]) }
        return VStack(alignment: stacked ? .leading : .center, spacing: -1) {
            ForEach(rows.indices, id: \.self) { row in
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    ForEach(rows[row].indices, id: \.self) { item in
                        let mark = rows[row][item]
                        Text(mark.code).font(Ink.times(codeSize)).foregroundColor(mark.color).underline(mark.code.count == 3 && mark.code.hasSuffix("R"))
                            + Text(mark.detail.isEmpty ? "" : " " + mark.detail).font(Ink.times(codeSize * 0.7)).foregroundColor(.black)
                    }
                }
            }
        }
        .fixedSize()
    }
}

/// The seal that sits on the frame's top edge.
struct OmSeal: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white)
            Circle().trim(from: 0.06, to: 0.44).stroke(Ink.rule, style: StrokeStyle(lineWidth: 3.2, lineCap: .round)).padding(2)
            Text("ॐ").font(.system(size: 19)).offset(y: -2)
        }
    }
}

extension View {
    /// Act when a value changes, in the form macOS 13 also carries.
    func onChanged<V: Equatable>(of value: V, _ action: @escaping () -> Void) -> some View {
        onChange(of: value) { _ in action() }
    }
    /// Place a view by its top-left corner on the page, in points.
    func at(_ x: CGFloat, _ y: CGFloat) -> some View {
        frame(width: 612, height: 792, alignment: .topLeading).offset(x: x, y: y)
    }
    /// Centre a view between two x positions at a height.
    func centred(from x0: CGFloat, to x1: CGFloat, y: CGFloat) -> some View {
        frame(width: x1 - x0, alignment: .center).at(x0, y)
    }
}

/// A birth chart report, page by page, in the form of a classical printed horoscope.
@MainActor
struct Report {
    let birth: Birth
    let chart: Chart
    /// the sky at another moment, read for the same place, for the transit page
    var transit: Chart? = nil

    var zone: TimeZone { birth.timeZone ?? TimeZone(secondsFromGMT: 0)! }
    var moment: Date { birth.moment ?? Date() }
    var name: String { birth.name.isEmpty ? "Unnamed" : birth.name }

    func text(_ date: Date, _ format: String, zone: TimeZone? = nil) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = zone ?? self.zone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    func clock(_ julianDay: Double?, _ format: String = "HH:mm:ss") -> String {
        julianDay.map { text(Names.date(julianDay: $0), format) + " hrs" } ?? "none on this day"
    }
    func place(_ p: Placement) -> String { "\(Names.signsShort[p.sign]) \(Names.colons(p.deg))" }
    func place(_ lon: Double) -> (sign: String, degrees: String) {
        let sign = Int(lon / 30) % 12
        return (Names.signsShort[sign], Names.colons(lon - Double(sign) * 30))
    }
    func angle(_ value: Double, _ positive: String, _ negative: String) -> String {
        let total = Int((abs(value) * 3600).rounded())
        return String(format: "%d%@%02d'%02d", total / 3600, value < 0 ? negative : positive, (total / 60) % 60, total % 60)
    }
    var headline: String {
        "\(text(moment, "d MMMM yyyy")) • \(text(moment, "EEEE")) • \(text(moment, "HH:mm:ss")) hrs • \(birth.place.isEmpty ? "place not named" : birth.place)"
    }

    // MARK: derived readings

    var ishtkaal: String {
        let rises = [chart.day.sunrise, chart.day.sunrise_before].compactMap { $0 }.filter { $0 <= chart.jd }
        guard let rise = rises.max() else { return "no sunrise before birth" }
        let vipalas = Int(((chart.jd - rise) * 216000).rounded())
        return String(format: "%d:%02d:%02d ghatis", vipalas / 3600, (vipalas / 60) % 60, vipalas % 60)
    }
    /// seconds to add to the civil clock for local mean time
    var meanTimeCorrection: Double { birth.longitude * 240 - Double(zone.secondsFromGMT(for: moment)) }

    var dashaAtBirth: (running: String, balance: String) {
        guard let maha = chart.dasha.first(where: { $0.holds(chart.jd) }), let antar = maha.antar?.first(where: { $0.holds(chart.jd) }) else { return ("", "") }
        let order = ["Ke", "Ve", "Su", "Mo", "Ma", "Ra", "Ju", "Sa", "Me"], years = [7.0, 20, 6, 10, 7, 18, 16, 19, 17]
        var lord = order.firstIndex(of: antar.lord) ?? 0, start = antar.start, third = antar.lord
        for _ in 0..<9 {
            let end = start + (antar.end - antar.start) * years[lord] / 120
            if chart.jd < end { third = order[lord]; break }
            start = end; lord = (lord + 1) % 9
        }
        // the balance in years, then twelfths of a year, then thirtieths of those
        let left = (maha.end - chart.jd) / 365.25, y = Int(left), months = (left - Double(y)) * 12, m = Int(months)
        let full = { (code: String) in Names.lords[code] ?? code }
        return ("\(full(maha.lord))-\(full(antar.lord))-\(full(third))", "\(full(maha.lord)) \(y)y \(m)m \(Int((months - Double(m)) * 30))d")
    }

    // MARK: chart marks

    func marks(sign: (Graha) -> Int, ascendant: Int, bhrigu: Int, degrees: Bool) -> [[Mark]] {
        var bySign = [[Mark]](repeating: [], count: 12)
        let minutes = { (deg: Double) in String(format: "%02d:%02d", Int(deg), Int(deg * 60) % 60) }
        bySign[ascendant].append(Mark(code: "As", detail: degrees ? minutes(chart.asc.deg) : ""))
        for graha in chart.grahas + chart.outer {
            let node = graha.id == "Ra" || graha.id == "Ke"
            bySign[sign(graha)].append(Mark(code: graha.id + (graha.retro && !node ? "R" : ""), detail: degrees ? minutes(graha.deg) : ""))
        }
        bySign[bhrigu].append(Mark(code: "BP", detail: degrees ? minutes(chart.bhrigu.deg) : ""))
        return bySign
    }
    func houses(_ bySign: [[Mark]], first: Int) -> [[Mark]] { (0..<12).map { bySign[(first + $0) % 12] } }

    var rasiHouses: [[Mark]] { houses(marks(sign: \.sign, ascendant: chart.asc.sign, bhrigu: chart.bhrigu.sign, degrees: true), first: chart.asc.sign) }
    var moonHouses: [[Mark]] { houses(marks(sign: \.sign, ascendant: chart.asc.sign, bhrigu: chart.bhrigu.sign, degrees: false), first: moonSign) }
    var navamsaHouses: [[Mark]] { houses(marks(sign: \.navamsa, ascendant: chart.asc.navamsa, bhrigu: chart.bhrigu.navamsa, degrees: false), first: chart.asc.navamsa) }
    var moonSign: Int { chart.graha("Mo")?.sign ?? 0 }
    var bhavaHouses: [[Mark]] {
        let house = { (lon: Double) in chart.bhavas.firstIndex { $0.holds(lon) } ?? 0 }
        var byHouse = [[Mark]](repeating: [], count: 12)
        byHouse[0].append(Mark(code: "As"))
        for graha in chart.grahas + chart.outer {
            let node = graha.id == "Ra" || graha.id == "Ke"
            byHouse[house(graha.lon)].append(Mark(code: graha.id + (graha.retro && !node ? "R" : "")))
        }
        byHouse[house(chart.bhrigu.lon)].append(Mark(code: "BP"))
        return byHouse
    }

    // MARK: page furniture

    func page<Content: View>(_ number: Int, title: String, seal: Bool = true, @ViewBuilder content: () -> Content) -> AnyView {
        AnyView(
            ZStack(alignment: .topLeading) {
                Color.white
                RoundedRectangle(cornerRadius: 18).stroke(Ink.rule, lineWidth: 0.8).frame(width: 498, height: 678).at(50, 54)
                if seal {
                    Text(name).font(Ink.times(12)).at(60, 38)
                    Text(title).font(Ink.times(12)).frame(width: 478, alignment: .trailing).at(60, 38)
                    OmSeal().frame(width: 36, height: 36).at(288, 34)
                }
                content()
                Text("Form Jyotish · calculated by the Form engine from JPL DE440 · \(Names.ayanamsas[chart.ayanamsa_mode] ?? chart.ayanamsa_mode) ayanamsa, \(chart.node) node")
                    .font(.system(size: 7)).at(60, 740)
                Text("\(name) • \(number)").font(.system(size: 8)).frame(width: 478, alignment: .trailing).at(60, 739)
            }
            .frame(width: 612, height: 792)
            .foregroundColor(.black)
            .environment(\.colorScheme, .light)
        )
    }

    func heading(_ title: String, from x0: CGFloat, to x1: CGFloat, y: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Text(title).font(Ink.times(14.5)).foregroundColor(Ink.maroon).centred(from: x0, to: x1, y: y)
            Rectangle().fill(Ink.rule).frame(width: x1 - x0, height: 0.7).at(x0, y + 18)
        }
    }

    func facts(_ rows: [(String, String, Bool)], x: CGFloat, y: CGFloat, labelWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                HStack(spacing: 0) {
                    Text(rows[index].0).frame(width: labelWidth, alignment: .leading)
                    Text(rows[index].0.isEmpty ? "" : ":").frame(width: 14, alignment: .leading)
                    Text(rows[index].1).fontWeight(rows[index].2 ? .bold : .regular)
                }
                .frame(height: 13.8)
            }
        }
        .font(Ink.times(11.2))
        .at(x, y)
    }

    func tableBand(y: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Ink.band).frame(width: 468, height: height).at(65, y)
            Rectangle().fill(Ink.rule).frame(width: 468, height: 0.7).at(65, y)
            Rectangle().fill(Ink.rule).frame(width: 468, height: 0.7).at(65, y + height)
        }
    }

    // MARK: pages

    var cover: AnyView {
        AnyView(
            ZStack(alignment: .topLeading) {
                Color.white
                Text(name).font(Ink.times(20)).foregroundColor(Ink.maroon).centred(from: 0, to: 612, y: 103)
                Text("\(text(moment, "d MMMM yyyy")) • \(text(moment, "HH:mm:ss")) hrs. • \(birth.place)")
                    .font(Ink.times(14)).foregroundColor(Ink.maroon).centred(from: 0, to: 612, y: 133)
                Text("Processed On: \(text(Date(), "d MMMM yyyy", zone: .current))").font(Ink.times(11)).centred(from: 0, to: 612, y: 744)
            }
            .frame(width: 612, height: 792)
            .foregroundColor(.black)
            .environment(\.colorScheme, .light)
        )
    }

    func particulars(_ number: Int) -> AnyView {
        let dasha = dashaAtBirth
        let daylight = zone.daylightSavingTimeOffset(for: moment) / 3600
        let offset = Double(zone.secondsFromGMT(for: moment)) / 3600
        let boxed: [(String, String, Bool)] = [
            ("Date of birth", text(moment, "d MMMM yyyy"), true), ("Day of birth", text(moment, "EEEE"), false),
            ("Time of birth", text(moment, "HH:mm:ss") + " hrs", true), ("Ishtkaal", ishtkaal, false),
            ("Place of birth", birth.place.isEmpty ? "not named" : birth.place, true),
        ]
        let below: [(String, String, Bool)] = [
            ("Latitude", angle(birth.latitude, "N", "S"), false), ("Longitude", angle(birth.longitude, "E", "W"), false),
            ("Time zone", "UTC" + String(format: "%@%02d:%02d", offset < 0 ? "−" : "+", Int(abs(offset - daylight)), Int(abs(offset - daylight) * 60) % 60), false),
            ("War/daylight Corr.", Names.colons(daylight) + " hrs", false),
            ("GMT at birth", text(moment, "HH:mm:ss", zone: TimeZone(secondsFromGMT: 0)) + " hrs", false),
            ("LMT Corr.", Names.colons(meanTimeCorrection / 3600) + " hrs", false),
            ("Local Mean Time", text(moment.addingTimeInterval(meanTimeCorrection), "HH:mm:ss") + " hrs", false),
            ("Sidereal Time", Names.colons(chart.sidereal_time / 15) + " hrs", false),
            ("Sunsign (Western)", Names.signsWestern[Int(chart.sun_tropical / 30) % 12], false),
            ("Lagna", place(chart.asc), false),
        ]
        let calendar: [(String, String, Bool)] = [
            ("Paksha", Names.paksha(chart.day.tithi), true), ("Tithi at birth", Names.tithi(chart.day.tithi), true),
            ("Nak. at birth", chart.graha("Mo")?.nak_name ?? "", true), ("Yoga at birth", Names.yogas[chart.day.yoga], true),
            ("Karana at birth", Names.karana(chart.day.karana), true), ("", "", false),
            ("Sunrise", clock(chart.day.sunrise), false), ("Sunset", clock(chart.day.sunset), false),
            ("Next - day Sunrise", clock(chart.day.sunrise_after, "EEE HH:mm:ss"), false), ("", "", false),
            ("Dasha at Birth", dasha.running, false), ("Balance of Dasha", dasha.balance, false),
            ("Ayanamsha", "-" + Names.colons(chart.ayanamsa) + " " + (Names.ayanamsas[chart.ayanamsa_mode] ?? chart.ayanamsa_mode), false),
        ]
        return page(number, title: "", seal: false) {
            Text(name).font(Ink.times(17)).frame(width: 198, height: 22).background(Color.white)
                .overlay(Rectangle().stroke(Ink.rule, lineWidth: 0.8)).at(200, 43)
            heading("Birth Particulars", from: 66, to: 284, y: 74)
            RoundedRectangle(cornerRadius: 14).stroke(Ink.rule, lineWidth: 0.5).frame(width: 218, height: 84).at(66, 97)
            facts(boxed, x: 76, y: 104, labelWidth: 100)
            facts(below, x: 76, y: 192, labelWidth: 100)
            Rectangle().fill(Ink.rule).frame(width: 0.7, height: 250).at(299, 92)
            heading("Hindu Calendar", from: 310, to: 532, y: 74)
            facts(calendar, x: 324, y: 104, labelWidth: 100)
            Text("Sunrise and sunset are the Sun's upper limb at the horizon, with mean refraction.")
                .font(Ink.times(9)).italic().frame(width: 200, alignment: .leading).at(324, 292)
        }
    }

    func birthChart(_ number: Int) -> AnyView {
        struct Row { var name: String; var code: String; var flags: String; var p: Placement; var speed: String; var status: String }
        let asc = chart.asc
        var rows = [Row(name: "Lagna", code: "La", flags: "", p: asc, speed: "", status: "")]
        for g in chart.grahas {
            let p = Placement(lon: g.lon, sign: g.sign, sign_name: g.sign_name, deg: g.deg, nak: g.nak, nak_name: g.nak_name, pada: g.pada,
                              nak_lord: g.nak_lord, navamsa: g.navamsa, rasi_lord: g.rasi_lord, sub_lord: g.sub_lord, sub_sub: g.sub_sub, vargas: g.vargas)
            let node = g.id == "Ra" || g.id == "Ke"
            rows.append(Row(name: Names.lords[g.id] ?? g.name, code: g.id, flags: (g.retro && !node ? "R" : "") + (g.combust == true ? "C" : ""),
                            p: p, speed: Names.colons(g.speed), status: g.status ?? ""))
        }
        let widths: [CGFloat] = [54, 24, 28, 50, 50, 84, 28, 20, 20, 20, 22, 44, 30]
        let titles = ["Planet", "R/C", "Sign", "Degree", "Speed", "Nakshatra", "Pada", "RL", "NL", "SL", "SS", "Status", "SB"]
        let lord = { (code: String) in Text(code).foregroundColor(Ink.graha(code)) }
        return page(number, title: "Birth Chart") {
            Text(headline).font(Ink.times(11.5)).bold().foregroundColor(Ink.maroon).centred(from: 50, to: 548, y: 76)
            NorthPanel(firstSign: asc.sign, houses: rasiHouses, codeSize: 14, stacked: true).frame(width: 470, height: 272).at(64, 94)
            Text("Moon").font(Ink.times(11.5)).bold().foregroundColor(Ink.maroon).at(64, 377)
            NorthPanel(firstSign: moonSign, houses: moonHouses, codeSize: 11).frame(width: 226, height: 146).at(64, 392)
            Text("Navamsha").font(Ink.times(11.5)).bold().foregroundColor(Ink.maroon).at(308, 377)
            NorthPanel(firstSign: asc.navamsa, houses: navamsaHouses, codeSize: 11).frame(width: 226, height: 146).at(308, 392)
            tableBand(y: 559, height: 18)
            HStack(spacing: 0) {
                ForEach(titles.indices, id: \.self) { Text(titles[$0]).frame(width: widths[$0], alignment: .leading) }
            }
            .font(Ink.times(10.5)).bold().italic().at(70, 562)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(rows.indices, id: \.self) { index in
                    let row = rows[index]
                    HStack(spacing: 0) {
                        Text(row.name).foregroundColor(Ink.graha(row.code)).frame(width: widths[0], alignment: .leading)
                        Text(row.flags).frame(width: widths[1], alignment: .leading)
                        Text(Names.signsShort[row.p.sign]).frame(width: widths[2], alignment: .leading)
                        Text(Names.colons(row.p.deg)).frame(width: widths[3], alignment: .leading)
                        Text(row.speed).frame(width: widths[4], alignment: .leading)
                        Text(row.p.nak_name).frame(width: widths[5], alignment: .leading)
                        Text("\(row.p.pada)").frame(width: widths[6], alignment: .leading)
                        lord(row.p.rasi_lord).frame(width: widths[7], alignment: .leading)
                        lord(row.p.nak_lord).frame(width: widths[8], alignment: .leading)
                        lord(row.p.sub_lord).frame(width: widths[9], alignment: .leading)
                        lord(row.p.sub_sub).frame(width: widths[10], alignment: .leading)
                        Text(row.status).frame(width: widths[11], alignment: .leading)
                        Text((1...7).contains(index) ? String(format: "%.2f", chart.strengthRatio(index - 1)) : "").frame(width: widths[12], alignment: .leading)
                    }
                    .frame(height: 13.9)
                }
            }
            .font(Ink.times(10.8)).at(70, 583)
            Rectangle().fill(Ink.rule).frame(width: 468, height: 0.7).at(65, 726)
        }
    }

    func bhavaPage(_ number: Int) -> AnyView {
        let ordinals = ["First", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Eighth", "Ninth", "Tenth", "Eleventh", "Twelfth"]
        let cell = { (lon: Double) -> AnyView in
            let p = self.place(lon)
            return AnyView(HStack(spacing: 0) { Text(p.sign).frame(width: 30, alignment: .leading); Text(p.degrees).frame(width: 104, alignment: .leading) })
        }
        return page(number, title: "Chandra, Navamsha and Bhava") {
            Text("Moon Chart").font(Ink.times(13.5)).foregroundColor(Ink.maroon).centred(from: 64, to: 290, y: 76)
            NorthPanel(firstSign: moonSign, houses: moonHouses, codeSize: 13).frame(width: 226, height: 174).at(64, 93)
            Text("Navamsha").font(Ink.times(13.5)).foregroundColor(Ink.maroon).centred(from: 312, to: 534, y: 76)
            NorthPanel(firstSign: chart.asc.navamsa, houses: navamsaHouses, codeSize: 13).frame(width: 222, height: 174).at(312, 93)
            Text("Bhava (Sripati)").font(Ink.times(13.5)).foregroundColor(Ink.maroon).centred(from: 154, to: 444, y: 287)
            NorthPanel(firstSign: chart.asc.sign, houses: bhavaHouses, codeSize: 13).frame(width: 290, height: 174).at(154, 304)
            Text("Bhava Spashta - Sripati System").font(Ink.times(13.5)).foregroundColor(Ink.maroon).centred(from: 50, to: 548, y: 491)
            tableBand(y: 513, height: 30)
            HStack(alignment: .top, spacing: 0) {
                Text("Bhava Number").frame(width: 100, alignment: .leading)
                Text("Bhava Arambha\nHouse beginning").frame(width: 134, alignment: .leading)
                Text("Bhava Madhya\nMiddle of House").frame(width: 134, alignment: .leading)
                Text("Bhava Antya\nHouse ending").frame(width: 90, alignment: .leading)
            }
            .font(Ink.times(10.8)).bold().at(76, 516)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(chart.bhavas.indices, id: \.self) { index in
                    HStack(spacing: 0) {
                        Text("\(index + 1).  \(ordinals[index])").frame(width: 100, alignment: .leading)
                        cell(chart.bhavas[index].start)
                        cell(chart.bhavas[index].mid)
                        cell(chart.bhavas[index].end)
                    }
                    .frame(height: 13.9)
                }
            }
            .font(Ink.times(10.8)).at(76, 549)
            Rectangle().fill(Ink.rule).frame(width: 468, height: 0.7).at(65, 720)
        }
    }

    var pages: [AnyView] {
        var makers: [(Int) -> AnyView] = [{ _ in cover }, particulars, glancePage, birthChart, bhavaPage]
        makers += vargaPages
        makers += strengthPages
        makers += wordPages
        makers += housePages
        makers.append(jaiminiPage)
        makers += dashaPages
        makers += kpPages
        makers += transitPages
        makers.append(voicePage)
        return makers.enumerated().map { $1($0 + 1) }
    }

    /// Write the report as a vector PDF, one US Letter page per view.
    func write(to url: URL) -> Bool {
        var box = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else { return false }
        for page in pages {
            ImageRenderer(content: page).render { _, draw in
                pdf.beginPDFPage(nil)
                draw(pdf)
                pdf.endPDFPage()
            }
        }
        pdf.closePDF()
        return true
    }
}
