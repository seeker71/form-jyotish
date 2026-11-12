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
        case "Match": return "Two charts side by side by the tradition's eight measures of how two Moons meet. Choose the second chart from those saved in the sidebar. Each measure says what it looks at and what it found."
        case "Annual": return "The year ahead from one birthday to the next: the chart for the moment the Sun returns to its birth place in the zodiac, with Muntha, the year's point of focus. Step through the years, or let it follow the time bar."
        case "Jaimini": return "The sage Jaimini's way of reading: significators chosen by degree, the image each house casts, signs that aspect signs, and periods of signs."
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
        case "sources": return "What the app's numbers and rules rest on, and how it chooses its words."
        case "karakas": return "Jaimini assigns the roles of life to grahas by rank: the graha furthest through its sign is the atmakaraka, the self, and so on down to the darakaraka, the partner. The roles change from chart to chart. Click a row to read about that graha."
        case "arudhas": return "An arudha pada is the image a house casts: count from the house to its lord, then as far again. It shows how a matter appears to the world, beside what it is. Click a row or a mark to pick that sign."
        case "match": return "Ashtakoota, also called guna milan: eight measures, 36 points, read from the two Moons' signs and nakshatras. Each row names what the measure looks at, what each person brings, and the points it gives."
        case "events": return "Dated events of the life, each set against the periods running that day. This is how published readings test a chart against what happened, and how a birth time is checked."
        case "edges": return "Which placements stand close to the edge of a sign or nakshatra, what lies across the edge, and how small a change of birth time or ayanamsa would carry them over. Readings that rest on these placements deserve a second look."
        case "annual": return "Varshaphal: the chart of one year of life, cast for the Sun's return to its birth longitude at the birth place. Muntha moves one sign a year from the birth lagna and marks where the year's attention gathers."
        case "chara-dasha": return "A dasha of signs, not grahas. Each sign has its period, divided into twelve equal sub-periods. Open a period for its sub-periods; click one to go there."
        case "glossary": return "Look up any word used in the app. Each entry says what it is in plain words and, where it applies, what it is in the open chart. Click an entry to pick it; a link opens the workspace where it lives."
        case "guide": return "A chart is read in a settled order. Each step says what to look at and why, and its link shows that very thing in this chart."
        case "reading": return "The main facts of this chart as sentences. Click a name to read about it in the inspector, or a link to open the workspace that examines it."
        case "houses": return "One row per house. A house does well when its lord is strong and well placed, benefics stand in it or look at it, and its bindus are high. Click a row to pick the house."
        case "yogas": return "Named combinations of grahas, grouped by kind. Each line states the rule that was met; schools differ on some rules, so read the rule, not only the name. Click a line to pick the grahas that form it."
        case "aspects": return "Every graha looks fully at the 7th sign from itself; Mars also at the 4th and 8th, Jupiter the 5th and 9th, Saturn the 3rd and 10th. Pick a graha and the signs it aspects are tinted in the birth chart."
        case "avasthas": return "The state each graha is in: its age by degree, its wakefulness by the sign it is in, and its mood by its dignity."
        case "moon": return "The birth chart counted from the Moon's sign in place of the lagna. Read beside the birth chart: what holds from both is firm. “As” still marks the lagna's sign."
        case "birth": return "Type the date and the clock time at the birthplace as you know them (1971-03-11 or 11 Mar 1971; 02:50 or 2:50 am). The date is written as 1971-Mar-11 when you leave the field, so month and day cannot be taken for each other, and the time as 02:50:00. A place you type is looked up when you leave it, and its full name, latitude, longitude and time zone are filled in; a field shown in red cannot be read yet. Every card recalculates as you type."
        case "grahas": return "One row per graha: its sign, its degree within the sign, its nakshatra and pada, its lords and how it is placed. Click a row for the full detail; hover a column heading for what it means."
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
            "Navamsa": "The graha's sign in the D9 chart, and whether it is exalted, in its own sign or debilitated there.",
            "Hemmed": "Kartari: grahas in the signs on both sides. Benefics there support; malefics there press.",
            "Roles": "What the graha becomes in this chart through the houses it rules: lagna lord, yogakaraka, maraka and so on.",
            "Signifies": "What the graha stands for by nature in every chart: its karaka meanings.",
            "Long.": "Longitude: how far the graha has moved through its sign, in degrees and minutes out of 30 degrees. Click the row for the seconds.",
            "Nakshatra · pada": "The lunar mansion the graha is in, one of 27, and which of its four quarters.",
            "Lords": "The lord of the graha's sign, of its nakshatra, and of its sub-division, in that order.",
            "°/day": "Motion in degrees a day. A minus sign is retrograde motion; the graha's name is underlined then.",
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
            "Aspected by": "Grahas looking at the house from elsewhere. Jupiter and Venus ease; Saturn and Mars ask for effort.",
            "What supports it": "Facts of this chart that speak for the graha giving good results.",
            "What asks more of it": "Facts of this chart through which the graha gives by effort, patience or a change of approach.",
            "See it elsewhere": "The other views that examine the same thing.",
            "Sign aspects": "In Jaimini's reading, signs aspect signs: movable signs the fixed ones (but the next), fixed signs the movable ones (but the one before), dual signs each other.",
            "Arudhas here": "The arudha padas that fall in this sign: the images cast by those houses.",
            "Aspects": "The signs this graha looks at in full. Click a sign to read about it.",
            "Yogas it forms": "Named combinations this graha takes part in. Hover a name for the rule.",
            "Avasthas": "The graha's state: age, wakefulness, mood.",
            "Baladi": "Age by degree within the sign: infant, youth, adult (fullest), old, spent (quietest).",
            "Jagradadi": "Awake in its own or exalted sign, dreaming in a friend's or neutral's, asleep in an enemy's or its fall.",
            "Deeptadi": "Mood by dignity: blazing when exalted, at ease in its own sign, down through content, calm, wanting, burdened, to humbled; heated when combust.",
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
        case "Ma": return "Mars: energy, courage, siblings, land, drive and the will to act."
        case "Me": return "Mercury: intellect, speech, learning, trade and skill with detail."
        case "Ju": return "Jupiter: wisdom, teachers, children, fortune and growth."
        case "Ve": return "Venus: love, marriage, comfort, the arts and vehicles."
        case "Sa": return "Saturn: time, discipline, patient work, endurance and maturity."
        case "Ra": return "Rahu, the Moon's north node: ambition, the foreign, the unconventional, appetite for experience."
        case "Ke": return "Ketu, the Moon's south node: detachment, the past, insight, release."
        case "Ur", "Ne", "Pl": return "An outer planet. Classical Jyotish does not use it; it is shown for those who do."
        default: return ""
        }
    }

    /// an avastha's Sanskrit name with its sense
    static func avastha(_ name: String) -> String {
        let senses = ["Bala": "infant", "Kumara": "youth", "Yuva": "adult", "Vriddha": "old", "Mrita": "spent", "Jagrat": "awake", "Swapna": "dreaming", "Sushupti": "asleep",
                      "Deepta": "blazing", "Swastha": "at ease", "Mudita": "content", "Shanta": "calm", "Deena": "wanting", "Dukhita": "burdened", "Vikala": "hindered", "Khala": "humbled", "Kopa": "heated"]
        return senses[name].map { "\(name) (\($0))" } ?? name
    }

    static func sign(_ sign: Int) -> String {
        let elements = ["fire", "earth", "air", "water"], modes = ["movable", "fixed", "dual"]
        return "A \(modes[sign % 3]) \(elements[sign % 4]) sign."
    }

    static let timeBar = "Birth shows the birth chart alone. Now lays today's sky over it. The arrows step by the amount chosen between them; play moves forward steadily at a pace suited to the step, faster or slower with the × beside it. Rectify moves the birth time itself."
}
