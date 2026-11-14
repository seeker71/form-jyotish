import Foundation

/// What a person enters: a moment and a place.
struct Birth: Codable, Identifiable, Hashable {
    var id = UUID()
    var name = "New chart"
    var date = "2000-01-01"
    var time = "12:00:00"
    var zone = TimeZone.current.identifier
    var place = ""
    var latitude = 0.0
    var longitude = 0.0
    /// dated events of the life, entered by the reader
    var events: [LifeEvent]? = nil
    /// this chart's own ayanamsa and node; nil follows the app's default
    var ayanamsa: String? = nil
    var node: String? = nil
    /// where the birth data comes from and how well it is documented
    var source: String? = nil

    var timeZone: TimeZone? { TimeZone(identifier: zone) }

    /// The birth moment, or nil when the date, time or zone cannot be read.
    var moment: Date? {
        guard let tz = timeZone, let d = Birth.readDate(date), let t = Birth.readTime(time) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        return calendar.date(from: DateComponents(year: d.year, month: d.month, day: d.day, hour: t.hour, minute: t.minute, second: t.second))
    }

    private static let months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]

    /// A date as a person types it: 1971-03-11, 11 Mar 1971, March 11, 1971, 11.3.1971, 3/11/1971. With
    /// slashes the day comes first where the Mac's region writes it so, unless the numbers settle it.
    static func readDate(_ words: String) -> (year: Int, month: Int, day: Int)? {
        let parts = words.lowercased().split(whereSeparator: { " ,.-/".contains($0) }).map(String.init)
        guard parts.count == 3 else { return nil }
        func month(_ word: String) -> Int? { word.count >= 3 ? months.firstIndex { word.hasPrefix($0) }.map { $0 + 1 } : nil }
        let n = parts.map { Int($0) }
        var year: Int?, m: Int?, day: Int?
        if let name = parts.firstIndex(where: { month($0) != nil }) {
            let rest = n.enumerated().filter { $0.offset != name }.compactMap { $0.element }
            guard rest.count == 2 else { return nil }
            m = month(parts[name]); (day, year) = rest[0] > 31 ? (rest[1], rest[0]) : (rest[0], rest[1])
        } else {
            guard let a = n[0], let b = n[1], let c = n[2] else { return nil }
            if parts[0].count == 4 || a > 31 { (year, m, day) = (a, b, c) }
            else if words.contains(".") || a > 12 { (day, m, year) = (a, b, c) }
            else if b > 12 || words.contains("-") { (m, day, year) = (a, b, c) }
            else {
                let dayFirst = (DateFormatter.dateFormat(fromTemplate: "yMd", options: 0, locale: .current) ?? "M/d").first == "d"
                (day, m, year) = dayFirst ? (a, b, c) : (b, a, c)
            }
        }
        guard let year, let m, let day, (1...12).contains(m), (1...31).contains(day), parts.contains(where: { $0.count == 4 && Int($0) == year }) else { return nil }
        // the day must exist in that month
        var check = DateComponents(); check.year = year; check.month = m; check.day = day
        guard check.isValidDate(in: Calendar(identifier: .gregorian)) else { return nil }
        return (year, m, day)
    }

    /// A time as a person types it: 02:50, 2:50:30, 2.50 pm, 0250, 14, 2am. Without am or pm it is the 24-hour clock.
    static func readTime(_ words: String) -> (hour: Int, minute: Int, second: Int)? {
        var text = words.lowercased().replacingOccurrences(of: " ", with: "")
        var half: String?
        for mark in ["a.m.", "p.m.", "am", "pm", "a", "p"] where text.hasSuffix(mark) { half = String(mark.first!); text.removeLast(mark.count); break }
        var parts = text.split(whereSeparator: { ":.h".contains($0) }).map { Int($0) }
        if parts.count == 1, text.count >= 3, text.count <= 4, let all = Int(text) { parts = [all / 100, all % 100] }
        guard (1...3).contains(parts.count), !parts.contains(nil) else { return nil }
        var hour = parts[0]!
        let minute = parts.count > 1 ? parts[1]! : 0, second = parts.count > 2 ? parts[2]! : 0
        if let half { guard (1...12).contains(hour) else { return nil }; hour = hour % 12 + (half == "p" ? 12 : 0) }
        guard (0...23).contains(hour), (0...59).contains(minute), (0...59).contains(second) else { return nil }
        return (hour, minute, second)
    }

    /// the date and time in the one form the app writes them, when they can be read
    /// A date is written year, month by name, day (1971-Mar-11), so month and day cannot be taken for each other.
    static func write(_ d: (year: Int, month: Int, day: Int)) -> String { String(format: "%04d-%@-%02d", d.year, months[d.month - 1].capitalized, d.day) }
    static func writtenDate(_ words: String) -> String? { readDate(words).map(write) }
    var writtenDate: String? { Birth.writtenDate(date) }
    /// this birth with its date, and the dates of its life events, in the form the app writes
    var settled: Birth {
        var birth = self
        if let written = writtenDate { birth.date = written }
        birth.events = events?.map { var event = $0; if let written = Birth.writtenDate(event.date) { event.date = written }; return event }
        return birth
    }
    var writtenTime: String? { Birth.readTime(time).map { String(format: "%02d:%02d:%02d", $0.hour, $0.minute, $0.second) } }

    var julianDay: Double? { moment.map { $0.timeIntervalSince1970 / 86400 + 2440587.5 } }

    /// The civil clock's hours east of UTC at the birth moment.
    var zoneHours: Double? {
        guard let moment, let tz = timeZone else { return nil }
        return Double(tz.secondsFromGMT(for: moment)) / 3600
    }
}

/// Where a longitude falls, as the engine reads it. Signs and nakshatras count from 0.
struct Placement: Codable {
    var lon: Double
    var sign: Int
    var sign_name: String
    var deg: Double
    var nak: Int
    var nak_name: String
    var pada: Int
    var nak_lord: String
    var navamsa: Int
    var rasi_lord: String
    var sub_lord: String
    var sub_sub: String
    /// the sign in each of the sixteen vargas, in the order of `Names.vargas`
    var vargas: [Int]
}

struct Graha: Codable, Identifiable {
    var id: String
    var name: String
    var speed: Double
    var retro: Bool
    var status: String?
    var combust: Bool?
    /// degrees north of the ecliptic, and whether the graha is closing on the Sun (the seven grahas only)
    var lat: Double?
    /// distance from the earth in astronomical units (the seven grahas only)
    var dist: Double?
    var nearing: Bool?
    /// the avasthas: by age, by wakefulness, by mood (the seven grahas only)
    var baladi: String?
    var jagradadi: String?
    var deeptadi: String?
    var lon: Double
    var sign: Int
    var sign_name: String
    var deg: Double
    var nak: Int
    var nak_name: String
    var pada: Int
    var nak_lord: String
    var navamsa: Int
    var rasi_lord: String
    var sub_lord: String
    var sub_sub: String
    /// the sign in each of the sixteen vargas, in the order of `Names.vargas`
    var vargas: [Int]
}

struct Period: Codable, Identifiable {
    var lord: String
    var start: Double
    var end: Double
    var antar: [Period]?
    var id: String { "\(lord)-\(start)" }
    func holds(_ jd: Double) -> Bool { start <= jd && jd < end }
}

/// A period of a sign dasha, with its twelve sub-periods.
struct SignPeriod: Codable, Identifiable {
    var sign: Int
    var years: Int?
    var start: Double
    var end: Double
    var antar: [SignPeriod]?
    var id: String { "\(sign)-\(start)" }
    func holds(_ jd: Double) -> Bool { start <= jd && jd < end }
}

/// The Jaimini readings: the seven chara karakas from atma to dara, the twelve arudha padas, the atmakaraka's
/// navamsa sign, what each sign aspects, and the Chara dasha.
struct Jaimini: Codable {
    var karakas: [String]
    var arudhas: [Int]
    var karakamsa: Int
    var glances: [[Int]]
    var forward: Bool
    var chara: [SignPeriod]
}

/// A dasha system beside Vimshottari: its name, the years of its whole cycle, and its periods with their sub-periods.
struct DashaSystem: Codable {
    var name: String
    var years: Int
    var periods: [Period]
}

/// One bhava's beginning, middle and ending, sidereal degrees.
struct Bhava: Codable {
    var start: Double
    var mid: Double
    var end: Double
    func holds(_ lon: Double) -> Bool {
        let span = (end - start + 360).truncatingRemainder(dividingBy: 360)
        return (lon - start + 360).truncatingRemainder(dividingBy: 360) < span
    }
}

/// The day's limbs at birth. Tithi counts 0...29 from Shukla Pratipada, yoga 0...26, karana 0...59.
struct Day: Codable {
    var tithi: Int
    var yoga: Int
    var karana: Int
    /// the moments (UTC Julian days) the running tithi, karana, Moon's nakshatra and yoga end
    var tithi_end: Double?
    var karana_end: Double?
    var nak_end: Double?
    var yoga_end: Double?
    var sunrise_before: Double?
    var sunrise: Double?
    var sunset: Double?
    var sunrise_after: Double?
}

/// The chart under Krishnamurti's ayanamsa with Placidus cusps.
struct KP: Codable {
    var ayanamsa: Double
    var cusps: [Placement]
    var grahas: [Graha]
    var outer: [Graha]
    var fortuna: Placement
}

/// A dated event of the sky: a graha enters a sign, turns, or crosses a birth point.
struct TransitEvent: Decodable, Identifiable {
    var jd: Double
    /// "ingress", "station" or "contact"
    var kind: String
    var graha: String
    /// the sign entered, for an ingress
    var sign: Int?
    /// the birth point crossed, for a contact: a graha's code or "As"
    var natal: String?
    /// moving forward through the zodiac (after the event, for a station)
    var forward: Bool
    var id: String { "\(kind)-\(graha)-\(jd)" }
}

/// One named row of the shadbala, a value for each of the seven grahas in virupas. A name that opens with "=" is a sum.
struct BalaRow: Codable, Identifiable {
    var name: String
    var values: [Double]
    var id: String { name }
    var isSum: Bool { name.hasPrefix("=") }
    var title: String { isSum ? String(name.dropFirst()) : name }
}

/// A yoga the chart holds: its name, its kind, the grahas that form it, and the rule it met.
struct Yoga: Codable, Identifiable {
    var name: String
    var group: String
    var grahas: [String]
    var why: String
    var id: String { name + grahas.joined() }
}

struct Chart: Codable {
    var jd: Double
    var ayanamsa: Double
    var ayanamsa_mode: String
    var delta_t: Double
    var node: String
    var sidereal_time: Double
    var sun_tropical: Double
    var asc: Placement
    var mc: Placement
    var grahas: [Graha]
    var outer: [Graha]
    var bhrigu: Placement
    var bhavas: [Bhava]
    var kp: KP
    /// bindus by graha (Sun to Saturn) and sign
    var ashtakavarga: [[Int]]
    var shadbala: [BalaRow]
    /// the signs each of the seven grahas aspects in full
    var aspects: [[Int]]
    var yogas: [Yoga]
    var day: Day
    var dasha: [Period]
    var dashas: [DashaSystem]
    var jaimini: Jaimini

    func graha(_ id: String) -> Graha? { grahas.first { $0.id == id } }

    /// the signs a graha aspects; none for the nodes and outer planets
    func aspectedSigns(by code: String) -> [Int] { grahas.prefix(7).firstIndex { $0.id == code }.map { aspects[$0] } ?? [] }
    /// the grahas among the seven that aspect a sign
    func aspecting(sign: Int) -> [String] { grahas.prefix(7).enumerated().filter { aspects[$0.offset].contains(sign) }.map { $0.element.id } }

    /// rupas a graha needs to count as strong, Sun to Saturn
    static let requiredRupas = [6.5, 6.0, 5.0, 7.0, 6.5, 5.5, 5.0]
    /// a graha's whole shadbala in rupas, by its place among the seven
    func rupas(_ index: Int) -> Double { (shadbala.first { $0.name == "=Total" }?.values[index] ?? 0) / 60 }
    /// that strength as a multiple of what is required
    func strengthRatio(_ index: Int) -> Double { rupas(index) / Chart.requiredRupas[index] }
    /// the sarvashtakavarga: all seven grahas' bindus in each sign
    var sarva: [Int] { (0..<12).map { sign in ashtakavarga.reduce(0) { $0 + $1[sign] } } }
}

enum Names {
    static let signs = ["Mesha", "Vrishabha", "Mithuna", "Karka", "Simha", "Kanya", "Tula", "Vrischika", "Dhanu", "Makara", "Kumbha", "Meena"]
    static let signCodes = ["Ar", "Ta", "Ge", "Cn", "Le", "Vi", "Li", "Sc", "Sg", "Cp", "Aq", "Pi"]
    static let signsShort = ["Ari", "Tau", "Gem", "Can", "Leo", "Vir", "Lib", "Sco", "Sag", "Cap", "Aqu", "Pis"]
    static let signsWestern = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo", "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
    static let lords = ["Su": "Sun", "Mo": "Moon", "Ma": "Mars", "Me": "Mercury", "Ju": "Jupiter", "Ve": "Venus", "Sa": "Saturn", "Ra": "Rahu", "Ke": "Ketu"]
    static let vargas = ["Lagna", "Hora (wealth)", "Dreshkana (happiness siblings)", "Chaturthamsha (destiny)", "Saptamsha (children)", "Navamsha (spouse)",
                         "Dashamsha (great successes)", "Dwadashamsha (parents)", "Shodashamsha (conveyances)", "Vimshamsha (spiritual progress)",
                         "Chaturvimshamsha (knowledge)", "Saptavimshamsha (strength)", "Trimshamsha (misfortunes)", "Khavedamsha (ausp. inausp. effects)",
                         "Akshavedamsha (all areas)", "Shashtiamsha (all areas)"]
    static let vargaCodes = ["D1", "D2", "D3", "D4", "D7", "D9", "D10", "D12", "D16", "D20", "D24", "D27", "D30", "D40", "D45", "D60"]
    static let lordsThree = ["Su": "Sun", "Mo": "Mon", "Ma": "Mar", "Me": "Mer", "Ju": "Jup", "Ve": "Ven", "Sa": "Sat", "Ra": "Rah", "Ke": "Ket"]
    static let weekdayLords = ["Su", "Mo", "Ma", "Me", "Ju", "Ve", "Sa"]
    static let ayanamsas = ["lahiri": "Lahiri", "truecitra": "True Chitra", "raman": "B.V. Raman"]
    static let tithis = ["Pratipada", "Dwitiya", "Tritiya", "Chaturthi", "Panchami", "Shashthi", "Saptami", "Ashtami", "Navami", "Dashami", "Ekadashi", "Dwadashi", "Trayodashi", "Chaturdashi"]
    static let yogas = ["Vishkambha", "Priti", "Ayushman", "Saubhagya", "Shobhana", "Atiganda", "Sukarma", "Dhriti", "Shula", "Ganda", "Vriddhi", "Dhruva", "Vyaghata", "Harshana", "Vajra", "Siddhi", "Vyatipata", "Variyana", "Parigha", "Shiva", "Siddha", "Sadhya", "Shubha", "Shukla", "Brahma", "Indra", "Vaidhriti"]
    static let movingKaranas = ["Bava", "Balava", "Kaulava", "Taitila", "Gara", "Vanija", "Vishti"]

    static func paksha(_ tithi: Int) -> String { tithi < 15 ? "Shukla" : "Krishna" }
    static func tithi(_ index: Int) -> String {
        index == 14 ? "Shukla Poornima" : index == 29 ? "Krishna Amavasya" : "\(paksha(index)) \(tithis[index % 15])"
    }
    static func karana(_ index: Int) -> String {
        switch index {
        case 0: return "Kimstughna"
        case 57: return "Shakuni"
        case 58: return "Chatushpada"
        case 59: return "Naga"
        default: return movingKaranas[(index - 1) % 7]
        }
    }

    /// 16.3381 -> 16°20′17″
    static func dms(_ degrees: Double) -> String {
        let total = Int((degrees * 3600).rounded(.down))
        return String(format: "%d°%02d′%02d″", total / 3600, (total / 60) % 60, total % 60)
    }

    /// 4.3735 -> 04:22:25, to the nearest second; a negative value keeps its sign.
    static func colons(_ value: Double) -> String {
        let total = Int((abs(value) * 3600).rounded())
        return String(format: "%@%02d:%02d:%02d", value < 0 ? "-" : "", total / 3600, (total / 60) % 60, total % 60)
    }

    static func date(julianDay: Double) -> Date { Date(timeIntervalSince1970: (julianDay - 2440587.5) * 86400) }
}
