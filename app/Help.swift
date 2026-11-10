import Foundation

/// Plain words for a newcomer: what each card shows, what each term means, what each graha and sign stands for.
/// Shown in place while help is on, and as tooltips always.
enum Help {
    static func workspace(_ name: String) -> String {
        switch name {
        case "Guide": return "Where to begin. The steps a reader follows, this chart put in plain sentences, and the twelve houses. Every name is a link."
        case "Overview": return "The birth data, the birth chart, the navamsa, the grahas' positions and the dasha timeline. Start here."
        case "Vargas": return "The sixteen divisional charts. Each divides every sign into finer parts and shows one area of life in more detail."
        case "Dasha": return "The Vimshottari periods: which graha's time is running, from the 120-year cycle down to spans of days."
        case "Strength": return "How strong each graha is (shadbala) and how much support each sign holds (ashtakavarga)."
        case "KP": return "Krishnamurti Paddhati: positions under the KP ayanamsa, Placidus house cusps, and which houses each graha signifies."
        case "Yogas": return "The combinations the chart holds, each with the rule it met, and which graha looks at which sign."
        case "Transits": return "The sky of another moment laid over the birth chart. Move the time bar, or press Now."
        default: return ""
        }
    }

    static func card(_ id: String) -> String {
        if id == "chart:0" { return "Where each graha stood at birth. “As” marks the lagna, the sign rising in the east. Click a graha or a sign to read about it. Underlined grahas are retrograde; italic ones show the sky of the moment in the time bar." }
        if id == "chart:5" { return "The navamsa divides each sign into nine parts. It is read beside the birth chart for a graha's inner strength, and for marriage." }
        if id.hasPrefix("chart:"), let index = Int(id.dropFirst(6)) { return "\(Names.vargaCodes[index]) divides each sign into \(Names.vargaCodes[index].dropFirst()) parts and places each graha by the part it falls in. Read for: \(Names.vargas[index])." }
        switch id {
        case "glossary": return "Look up any word used in the app. Each entry says what it is in plain words and, where it applies, what it is in the open chart. Click an entry to pick it; a link opens the workspace where it lives."
        case "guide": return "A chart is read in a settled order. Each step says what to look at and why, and its link shows that very thing in this chart."
        case "reading": return "The main facts of this chart as sentences. Click a name to read about it in the inspector, or a link to open the workspace that examines it."
        case "houses": return "One row per house. A house does well when its lord is strong and well placed, benefics stand in it or look at it, and its bindus are high. Click a row to pick the house."
        case "yogas": return "Named combinations of grahas, grouped by kind. Each line states the rule that was met; schools differ on some rules, so read the rule, not only the name. Click a line to pick the grahas that form it."
        case "aspects": return "Every graha looks fully at the 7th sign from itself; Mars also at the 4th and 8th, Jupiter the 5th and 9th, Saturn the 3rd and 10th. Pick a graha and the signs it aspects are tinted in the birth chart."
        case "avasthas": return "The state each graha is in: its age by degree, its wakefulness by the sign it is in, and its mood by its dignity."
        case "moon": return "The birth chart counted from the Moon's sign in place of the lagna. Read beside the birth chart: what holds from both is firm. “As” still marks the lagna's sign."
        case "birth": return "Date as year-month-day, time on the 24-hour clock at the birthplace. Type a place and press Look up place to fill latitude, longitude and time zone. Every card recalculates as you type."
        case "grahas": return "One row per graha: its sign, its exact degree within the sign, its nakshatra (one of 27 lunar mansions) and how it is placed. Hover a column heading for what it means."
        case "dasha-context": return "Whose time it is at the moment in the time bar, and what that graha is in this chart: the houses it rules and stands in, what supports and strains it, how the period lords stand to each other, and where Saturn, Jupiter and Rahu are passing. Move the time bar and it follows."
        case "other-dashas": return "Nine more ways of dividing life into graha periods, each from the Moon's nakshatra. For each: how it works, the condition under which the classics apply it and whether this chart meets it, and its periods. Open a period for its sub-periods; click one to go there."
        case "timeline": return "Life as a sequence of graha periods. The top row is the mahadasha; the rows below divide it further. The blue line is the moment in the time bar. Narrow the span to see finer periods."
        case "dashas": return "The same periods as a list. Open a period with its arrow to see its nine parts; click a period to read it in the inspector."
        case "transit-dates": return "What the sky does next, with exact times: a graha entering a sign, turning retrograde or direct, or crossing the degree of a birth graha. Each line says which house that is from the birth lagna and Moon. Click a line to move the whole desk to that moment."
        case "transits": return "Where each graha is at the moment in the time bar, and which house that is counted from the birth lagna and from the birth Moon."
        case "shadbala": return "Six kinds of strength, added up. A graha with 1.00 or more in the last row has the strength the tradition asks of it. Hover a row's name for what it measures."
        case "ashtakavarga": return "Each graha gives up to 8 points (bindus) to every sign. More points in a sign mean a graha passing through it, or placed in it, gives better results. The bottom row adds all seven."
        case "kp-grahas": return "Each graha under the KP ayanamsa, with the chain KP reads: the lord of its sign, of its star, of its sub-division and of the division below that."
        case "kp-cusps": return "Where each of the twelve houses begins, by the Placidus system, with the same chain of lords."
        case "kp-houses": return "For each house: the grahas that speak for it, strongest first. Grahas in the stars of its occupants, then its occupants, then grahas in the stars of its lord, then its lord."
        case "kp-planets": return "For each graha: the houses whose matters it can bring about, grouped by how strongly."
        default: return ""
        }
    }

    /// A table heading, a row name or a label, explained.
    static let terms: [String: String] = [
            "Graha": "A planet in the Jyotish sense: the Sun, the Moon, five planets, and the Moon's two nodes Rahu and Ketu.",
            "Rasi": "The sign of the sidereal zodiac the graha is in.",
            "Longitude": "How far the graha has moved through its sign: degrees, minutes, seconds, out of 30 degrees.",
            "Nakshatra": "One of 27 lunar mansions of 13°20′ each. The Moon's nakshatra sets the dasha sequence.",
            "Pada": "The quarter of the nakshatra, 1 to 4. Each pada is 3°20′ and corresponds to one navamsa.",
            "Rasi · star · sub": "The lords of the graha's sign, of its nakshatra, and of its sub-division within the nakshatra.",
            "Rasi lord": "The graha that rules the sign.", "Star lord": "The graha that rules the nakshatra.",
            "Sub lord": "The nakshatra divided again in the dasha proportions; the lord of the part this falls in.",
            "Sub-sub": "The sub-division divided once more.",
            "Dignity": "How comfortable the graha is in its sign: exalted, in its own sign, with a friend, neutral, with an enemy, or debilitated. C marks a graha too close to the Sun (combust).",
            "Motion °/day": "How fast the graha moves along the zodiac in a day. A minus sign and ℞ mean it appears to move backward (retrograde).",
            "From lagna": "The house the graha is passing through, counted from the birth lagna.",
            "From Moon": "The house the graha is passing through, counted from the birth Moon's sign.",
            "House": "A twelfth of the chart counted from a starting sign; the first house is the lagna's sign.",
            "Lagna": "The ascendant: the point of the zodiac rising on the eastern horizon at birth. It sets the first house.",
            "Cusp": "The point where a house begins.", "Cusp lord": "The lord of the sign in which the house begins.",
            "Occupants": "Grahas standing in the house.", "In stars of occupants": "Grahas whose nakshatra is ruled by a graha in the house; KP's strongest significators.",
            "In stars of cusp lord": "Grahas whose nakshatra is ruled by the house's lord.",
            "Very strong": "Reached by three or more routes.", "Strong": "Reached both through occupation and through ownership.",
            "Normal": "Reached through occupation: the graha, or its star lord, stands in the house.", "Weak": "Reached through ownership only.",
            "Bindus": "Points of support, counted by the ashtakavarga rules.",
            "Shadbala": "Six-fold strength in rupas, and as a multiple of what the tradition requires of that graha.",
            "Uccha": "Strength from nearness to the degree of exaltation.", "Saptavargaja": "Strength from dignity in seven divisional charts.",
            "Ojayugma": "Strength from standing in an odd or even sign and navamsa, as suits the graha.",
            "Kendradi": "Strength from standing in an angular (60), succedent (30) or cadent (15) house.",
            "Drekkana": "Strength from the third of the sign that suits the graha's gender.",
            "Sthana bala": "Positional strength: the five rows above, added.",
            "Dig bala": "Directional strength: nearness to the angle where the graha is strongest.",
            "Nata-unnata": "Strength from the time of day: some grahas are strong at noon, some at midnight.",
            "Paksha": "Strength from the Moon's phase: benefics gain as the Moon waxes, malefics as it wanes.",
            "Tribhaga": "Strength to the lord of the third of the day or night in which the birth falls; Jupiter always.",
            "Abda": "Strength to the lord of the year.", "Masa": "Strength to the lord of the month.",
            "Vara": "Strength to the lord of the weekday, counted from sunrise.", "Hora": "Strength to the lord of the planetary hour.",
            "Ayana": "Strength from the graha's declination, north or south of the equator.",
            "Kala bala": "Temporal strength: the eight rows above, added.",
            "Cheshta bala": "Strength of motion: greatest when a planet is retrograde and bright, least when it is with the Sun.",
            "Naisargika bala": "Natural strength, the same in every chart: the Sun strongest, Saturn weakest.",
            "Drik bala": "Strength from aspects: gained from benefics' glances, lost to malefics'.",
            "Total": "All six, in virupas (60 virupas make a rupa).", "Rupas": "The total divided by 60.",
            "Required": "The rupas the tradition asks of each graha.", "Times required": "Rupas divided by what is required; 1.00 or more is strong.",
            "Sarva": "All seven grahas' bindus in the sign, added. About 28 is average; 30 or more is well supported.",
            "Nakshatra lord": "The graha ruling the nakshatra.", "Its lords": "The grahas ruling the sign, the nakshatra and its finer divisions that this graha stands in. Click one to read about it.",
            "In the vargas": "The sign this graha falls in, in each of the sixteen divisional charts.",
            "Its mahadasha": "The years of life ruled by this graha. Click to go there.",
            "Houses it signifies (KP)": "The houses whose matters this graha can bring about, by Krishnamurti's rules.",
            "In the sky of the moment": "Where this graha is at the moment shown in the time bar.",
            "Sign": "The sign that falls on the house, counted from the lagna's sign.",
            "Its lord, and where it stands": "The graha that rules the house's sign, the house that graha is in, and its dignity there. Where the lord goes, the house's matters follow.",
            "Grahas in it": "Grahas standing in the house colour its matters directly.",
            "Aspected by": "Grahas looking at the house from elsewhere. Jupiter and Venus help; Saturn and Mars press.",
            "What supports it": "Facts of this chart that speak for the graha giving good results.",
            "What strains it": "Facts of this chart that make the graha's results harder to come by.",
            "See it elsewhere": "The other views that examine the same thing.",
            "Aspects": "The signs this graha looks at in full. Click a sign to read about it.",
            "Yogas it forms": "Named combinations this graha takes part in. Hover a name for the rule.",
            "Avasthas": "The graha's state: age, wakefulness, mood.",
            "Baladi": "Age by degree within the sign: infant, youth, adult (strongest), old, dead (weakest).",
            "Jagradadi": "Awake in its own or exalted sign, dreaming in a friend's or neutral's, asleep in an enemy's or its fall.",
            "Deeptadi": "Mood by dignity: blazing when exalted, at ease in its own sign, down through content, calm, needy, distressed, to fallen; angry when combust.",
            "Its parts": "The period divided into nine, in the same order and proportions. Click a part to go to its start.",
            "Mahadasha": "A major period: 6 to 20 years ruled by one graha.", "Antardasha": "A sub-period within a mahadasha.",
            "Pratyantardasha": "A sub-period within an antardasha, weeks to months long.", "Sookshma dasha": "A sub-period within a pratyantardasha, days long.",
            "Prana dasha": "The finest division, hours long.",
        ]
    static func term(_ word: String) -> String? { terms[word] }

    static func graha(_ code: String) -> String {
        switch code {
        case "Su": return "The Sun: the self, vitality, the father, authority and standing."
        case "Mo": return "The Moon: the mind and feelings, the mother, the public, daily life. Its nakshatra sets the dashas."
        case "Ma": return "Mars: energy, courage, siblings, land, conflict and the will to act."
        case "Me": return "Mercury: intellect, speech, learning, trade and skill with detail."
        case "Ju": return "Jupiter: wisdom, teachers, children, fortune and growth."
        case "Ve": return "Venus: love, marriage, comfort, the arts and vehicles."
        case "Sa": return "Saturn: time, discipline, labour, delay, endurance and loss turned to depth."
        case "Ra": return "Rahu, the Moon's north node: desire, the foreign, the unconventional, sudden gain."
        case "Ke": return "Ketu, the Moon's south node: detachment, the past, insight, sudden loss."
        case "Ur", "Ne", "Pl": return "An outer planet. Classical Jyotish does not use it; it is shown for those who do."
        default: return ""
        }
    }

    /// an avastha's Sanskrit name with its sense
    static func avastha(_ name: String) -> String {
        let senses = ["Bala": "infant", "Kumara": "youth", "Yuva": "adult", "Vriddha": "old", "Mrita": "dead", "Jagrat": "awake", "Swapna": "dreaming", "Sushupti": "asleep",
                      "Deepta": "blazing", "Swastha": "at ease", "Mudita": "content", "Shanta": "calm", "Deena": "needy", "Dukhita": "distressed", "Vikala": "crippled", "Khala": "fallen", "Kopa": "angry"]
        return senses[name].map { "\(name) (\($0))" } ?? name
    }

    static func sign(_ sign: Int) -> String {
        let elements = ["fire", "earth", "air", "water"], modes = ["movable", "fixed", "dual"]
        return "A \(modes[sign % 3]) \(elements[sign % 4]) sign."
    }

    static let timeBar = "Birth shows the birth chart alone. Now lays today's sky over it. The arrows step by the amount chosen between them; play keeps stepping. Rectify moves the birth time itself."
}
