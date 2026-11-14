import Foundation

/// What was seen in the sky: how bright each of the five true planets stood, and the Moon's phase by name.
/// A planetary war is observational: the tradition judges it by latitude or by brightness.
extension Chart {
    /// apparent visual magnitude of one of the five (a lower number is brighter), from its distances to the earth
    /// and the Sun and its phase angle, after Mallama and Hilton (2018); Saturn is given for its globe, without
    /// the rings, so its figure is approximate
    func magnitude(_ g: Graha) -> Double? {
        guard Lore.five.contains(g.id), let sun = graha("Su"), let R = sun.dist, let d = g.dist, let lat = g.lat else { return nil }
        let rad = Double.pi / 180, cosElong = cos(lat * rad) * cos((g.lon - sun.lon) * rad)
        let r = sqrt(max(1e-9, R * R + d * d - 2 * R * d * cosElong))
        let i = acos(max(-1, min(1, (r * r + d * d - R * R) / (2 * r * d)))) / rad, base = 5 * log10(r * d)
        switch g.id {
        case "Me": return -0.613 + base + 6.328e-2 * i - 1.6336e-3 * pow(i, 2) + 3.3644e-5 * pow(i, 3) - 3.4265e-7 * pow(i, 4) + 1.6893e-9 * pow(i, 5) - 3.0334e-12 * pow(i, 6)
        case "Ve": return i < 163.7 ? -4.384 + base - 1.044e-3 * i + 3.687e-4 * pow(i, 2) - 2.814e-6 * pow(i, 3) + 8.938e-9 * pow(i, 4) : 236.05828 + base - 2.81914 * i + 8.39034e-3 * pow(i, 2)
        case "Ma": return i <= 50 ? -1.601 + base + 0.02267 * i - 0.0001302 * pow(i, 2) : -0.367 + base - 0.02573 * i + 0.0003445 * pow(i, 2)
        case "Ju": return -9.395 + base - 3.7e-4 * i + 6.16e-4 * pow(i, 2)
        case "Sa": return -8.914 + base + 0.026 * i
        default: return nil
        }
    }

    /// the second test of a war, said beside the first: `winner` is the graha that prevails by latitude
    func brightnessLine(_ winner: Graha, _ other: Graha) -> String {
        guard let a = magnitude(winner), let b = magnitude(other) else { return "" }
        let name = { (g: Graha) in Names.lords[g.id] ?? g.id }
        let (bright, dim, mb, md) = a <= b ? (winner, other, a, b) : (other, winner, b, a)
        return String(format: " By brightness, the other test of a war, \(name(bright)) (magnitude %+.1f) outshines \(name(dim)) (magnitude %+.1f)", mb, md)
            + (bright.id == winner.id ? ", so both tests agree." : ", so the two tests differ; the app follows the latitude, the rule Light on Life gives.")
            + (winner.id == "Sa" || other.id == "Sa" ? " Saturn's figure leaves out its rings and is approximate." : "")
    }

    /// the Moon's phase as it is named in the sky
    var moonPhase: String {
        let names = ["new Moon", "waxing crescent", "first quarter", "waxing gibbous", "full Moon", "waning gibbous", "last quarter", "waning crescent"]
        return names[Int(((elongation + 22.5).truncatingRemainder(dividingBy: 360)) / 45)]
    }
}
