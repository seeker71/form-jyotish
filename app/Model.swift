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

    var timeZone: TimeZone? { TimeZone(identifier: zone) }

    /// The birth moment, or nil when the date, time or zone cannot be read.
    var moment: Date? {
        guard let tz = timeZone else { return nil }
        let d = date.split(separator: "-").map { Int($0) }
        let t = time.split(separator: ":").map { Int($0) }
        guard d.count == 3, (2...3).contains(t.count), !d.contains(nil), !t.contains(nil) else { return nil }
        let (month, day, hour, minute, second) = (d[1]!, d[2]!, t[0]!, t[1]!, t.count > 2 ? t[2]! : 0)
        guard (1...12).contains(month), (1...31).contains(day), (0...23).contains(hour), (0...59).contains(minute), (0...59).contains(second) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = tz
        return calendar.date(from: DateComponents(year: d[0]!, month: month, day: day, hour: hour, minute: minute, second: second))
    }

    var julianDay: Double? { moment.map { $0.timeIntervalSince1970 / 86400 + 2440587.5 } }
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
}

struct Graha: Codable, Identifiable {
    var id: String
    var name: String
    var speed: Double
    var retro: Bool
    var lon: Double
    var sign: Int
    var sign_name: String
    var deg: Double
    var nak: Int
    var nak_name: String
    var pada: Int
    var nak_lord: String
    var navamsa: Int
}

struct Period: Codable, Identifiable {
    var lord: String
    var start: Double
    var end: Double
    var antar: [Period]?
    var id: String { "\(lord)-\(start)" }
    func holds(_ jd: Double) -> Bool { start <= jd && jd < end }
}

struct Chart: Codable {
    var jd: Double
    var ayanamsa: Double
    var delta_t: Double
    var node: String
    var asc: Placement
    var mc: Placement
    var grahas: [Graha]
    var dasha: [Period]
}

enum Names {
    static let signs = ["Mesha", "Vrishabha", "Mithuna", "Karka", "Simha", "Kanya", "Tula", "Vrischika", "Dhanu", "Makara", "Kumbha", "Meena"]
    static let signCodes = ["Ar", "Ta", "Ge", "Cn", "Le", "Vi", "Li", "Sc", "Sg", "Cp", "Aq", "Pi"]
    static let lords = ["Su": "Sun", "Mo": "Moon", "Ma": "Mars", "Me": "Mercury", "Ju": "Jupiter", "Ve": "Venus", "Sa": "Saturn", "Ra": "Rahu", "Ke": "Ketu"]

    /// 16.3381 -> 16°20′17″
    static func dms(_ degrees: Double) -> String {
        let total = Int((degrees * 3600).rounded(.down))
        return String(format: "%d°%02d′%02d″", total / 3600, (total / 60) % 60, total % 60)
    }

    static func date(julianDay: Double) -> Date { Date(timeIntervalSince1970: (julianDay - 2440587.5) * 86400) }
}
