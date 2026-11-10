import Foundation

/// Vimshottari below the antardasha: each period divides again in the same nine shares, beginning with its own lord.
enum Vimshottari {
    static let order = ["Ke", "Ve", "Su", "Mo", "Ma", "Ra", "Ju", "Sa", "Me"]
    static let years: [Double] = [7, 20, 6, 10, 7, 18, 16, 19, 17]

    static func parts(of period: Period) -> [Period] {
        var lord = order.firstIndex(of: period.lord) ?? 0, start = period.start
        return (0..<9).map { _ in
            let end = start + (period.end - period.start) * years[lord] / 120
            defer { start = end; lord = (lord + 1) % 9 }
            return Period(lord: order[lord], start: start, end: end, antar: nil)
        }
    }

    /// The periods running at a moment, from mahadasha down `depth` levels.
    static func running(at jd: Double, in mahas: [Period], depth: Int) -> [Period] {
        var path: [Period] = [], level = mahas
        for _ in 0..<depth {
            guard let found = level.first(where: { $0.holds(jd) }) else { break }
            path.append(found)
            level = parts(of: found)
        }
        return path
    }

    /// The mahadashas a Moon longitude gives at a birth moment (used for the balance under another ayanamsa).
    static func balance(moon: Double, at jd: Double) -> (lord: String, days: Double) {
        let span = 360.0 / 27, nak = Int(moon / span), lord = nak % 9
        return (order[lord], (1 - (moon - Double(nak) * span) / span) * years[lord] * 365.25)
    }

    /// 3821 days -> "10y 5m 18d": years, then twelfths of a year, then thirtieths of those.
    static func span(days: Double) -> String {
        let left = days / 365.25, y = Int(left), months = (left - Double(y)) * 12, m = Int(months)
        return "\(y)y \(m)m \(Int((months - Double(m)) * 30))d"
    }
}

/// Krishnamurti's significators, read from the cuspal chart.
struct KPReading {
    let kp: KP
    /// the nine grahas' codes in their usual order
    var codes: [String] { kp.grahas.map(\.id) }

    /// The house (0...11) whose cusp a longitude has passed and whose next cusp it has not reached.
    func house(of lon: Double) -> Int {
        for index in 0..<12 {
            let start = kp.cusps[index].lon, span = (kp.cusps[(index + 1) % 12].lon - start + 360).truncatingRemainder(dividingBy: 360)
            if (lon - start + 360).truncatingRemainder(dividingBy: 360) < span { return index }
        }
        return 0
    }
    func occupants(_ house: Int) -> [String] { kp.grahas.filter { self.house(of: $0.lon) == house }.map(\.id) }
    func inStars(of lords: [String]) -> [String] { kp.grahas.filter { lords.contains($0.nak_lord) }.map(\.id) }
    func owned(by code: String) -> [Int] { (0..<12).filter { kp.cusps[$0].rasi_lord == code } }

    /// For a house: grahas in the stars of its occupants, its occupants, grahas in the stars of its cusp's sign lord, that lord.
    func houseRow(_ house: Int) -> (starsOfOccupants: [String], occupants: [String], starsOfLord: [String], lord: String) {
        let here = occupants(house), lord = kp.cusps[house].rasi_lord
        return (inStars(of: here), here, inStars(of: [lord]), lord)
    }

    /// For a graha, the houses it signifies by strength. A house reached through occupation (its own or its
    /// star lord's) is a normal signification, one reached through ownership a weak one; reached both ways it
    /// is strong, and by three or four routes very strong.
    func signified(by graha: Graha) -> (veryStrong: [Int], strong: [Int], normal: [Int], weak: [Int]) {
        let star = kp.grahas.first { $0.id == graha.nak_lord }
        let occupied = [star.map { house(of: $0.lon) }, house(of: graha.lon)].compactMap { $0 }
        let ownedHouses = owned(by: graha.nak_lord) + owned(by: graha.id)
        var result: (veryStrong: [Int], strong: [Int], normal: [Int], weak: [Int]) = ([], [], [], [])
        for h in 0..<12 {
            let occ = occupied.filter { $0 == h }.count, own = ownedHouses.filter { $0 == h }.count
            if occ + own >= 3 { result.veryStrong.append(h + 1) }
            else if occ >= 1 && own >= 1 { result.strong.append(h + 1) }
            else if occ >= 1 { result.normal.append(h + 1) }
            else if own >= 1 { result.weak.append(h + 1) }
        }
        return result
    }
}
