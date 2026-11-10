import Foundation

/// Charts of public figures with dated events of their lives: for testing the app against readings a reader
/// can look up, and for learning from them.
///
/// Each chart says how well its birth time is documented, by the Rodden rating astrologers use: AA from a
/// birth record, A from memory, B from a biography, C uncertain or rectified, DD conflicting sources. Where
/// the best-documented time and the time a published reading uses differ, both charts are given, so a reading
/// can be followed on its own terms and the better record is not lost.
enum PublicCharts {
    struct Entry {
        let key: String
        let birth: Birth
    }

    private static func events(_ list: [(String, String)]) -> [LifeEvent] { list.map { LifeEvent(date: $0.0, note: $0.1) } }

    private static let einstein = events([("1902-06-23", "Begins work at the Patent Office in Bern"), ("1903-01-06", "Marriage to Mileva Marić"),
        ("1911-04-01", "Professor of physics in Prague"), ("1914-04-01", "Berlin: director of the Kaiser Wilhelm Institute"),
        ("1922-11-09", "Nobel Prize in Physics announced"), ("1933-10-17", "Arrives in Princeton"), ("1955-04-18", "Death")])
    private static let vivekananda = events([("1884-02-25", "Death of his father"), ("1886-08-16", "Passing of Sri Ramakrishna"), ("1893-05-31", "Sails for America"),
        ("1893-09-11", "Address at the Parliament of Religions, Chicago"), ("1899-06-20", "Second journey to the West"), ("1902-07-04", "Death")])
    private static let ford = events([("1888-04-11", "Marriage to Clara Bryant"), ("1896-06-04", "Completes his first motor car, the Quadricycle"),
        ("1903-06-16", "Ford Motor Company founded"), ("1908-10-01", "The Model T goes on sale"), ("1947-04-07", "Death")])
    private static let aurobindo = events([("1879-06-01", "Taken to England for schooling"), ("1893-02-06", "Returns to India; joins the Baroda service"), ("1907-08-16", "Arrested for sedition"),
        ("1908-05-02", "Arrested in the Alipore case; a year in jail"), ("1910-04-04", "Arrives in Pondicherry"), ("1950-12-05", "Death")])
    private static let gandhi = events([("1920-08-01", "Non-cooperation movement launched"), ("1922-03-10", "Arrested; imprisoned"), ("1930-03-12", "The Salt March begins"),
        ("1942-08-09", "Arrested after the Quit India call"), ("1947-08-15", "Independence of India"), ("1948-01-30", "Assassinated")])
    private static let tagore = events([("1878-09-20", "First voyage to England"), ("1883-12-09", "Marriage to Mrinalini Devi"), ("1901-12-22", "Founds the school at Santiniketan"),
        ("1902-11-23", "Death of his wife"), ("1905-01-19", "Death of his father"), ("1913-11-13", "Nobel Prize in Literature announced"), ("1941-08-07", "Death")])

    /// Local mean time is written as a fixed offset to the minute; where a place's offset has odd seconds they
    /// are moved onto the clock time (Porbandar is 4 h 39 m 16 s east, so 7:45:00 is entered as 07:44:44).
    /// The best-documented charts come first.
    static let all: [Entry] = [
        Entry(key: "einstein", birth: Birth(name: "Albert Einstein (AA)", date: "1879-03-14", time: "11:30:00", zone: "GMT+0040", place: "Ulm, Germany", latitude: 48.4, longitude: 10.0,
            events: einstein, ayanamsa: "raman", node: "mean",
            source: "Rodden rating AA: 11:30 a.m. local mean time, from the birth record (Astro-Databank, collected by Lois Rodden). B.V. Raman, Notable Horoscopes No. 45, uses the same time; his ayanamsa is set here so his dasha dates can be followed. Under it the engine matches his printed positions to a minute of arc.")),
        Entry(key: "vivekananda", birth: Birth(name: "Swami Vivekananda (AA)", date: "1863-01-12", time: "06:33:00", zone: "GMT+0554", place: "Calcutta, India", latitude: 22.6667, longitude: 88.5,
            events: vivekananda, ayanamsa: "raman", node: "mean",
            source: "Rodden rating AA: 6:33 a.m. local mean time, from the birth record (Astro-Databank, collected by Lois Rodden). B.V. Raman, Notable Horoscopes No. 36, uses the same time; his ayanamsa is set here. Under it the engine matches his printed positions to a minute of arc.")),
        Entry(key: "ford", birth: Birth(name: "Henry Ford (B, 7:00 am)", date: "1863-07-30", time: "06:59:52", zone: "GMT-0533", place: "Greenfield Township, Michigan", latitude: 42.3, longitude: -83.2167,
            events: ford, ayanamsa: "lahiri", node: "mean",
            source: "Rodden rating B: 7:00 a.m. local mean time, from a biography (Astro-Databank, collected by Lois Rodden). This is the best-documented time. B.V. Raman reads a chart for 2 p.m., given as a separate chart.")),
        Entry(key: "aurobindo", birth: Birth(name: "Sri Aurobindo (B, 5:00 am)", date: "1872-08-15", time: "04:59:40", zone: "GMT+0553", place: "Calcutta, India", latitude: 22.5, longitude: 88.3333,
            events: aurobindo, ayanamsa: "lahiri", node: "mean",
            source: "Rodden rating B: 5:00 a.m. local mean time, from Peter Heehs's biography, The Lives of Sri Aurobindo. This is the best-documented time. B.V. Raman reads a chart for 5:17 a.m., given as a separate chart.")),
        Entry(key: "ford-raman", birth: Birth(name: "Henry Ford (Raman, 2 pm)", date: "1863-07-30", time: "14:00:20", zone: "GMT-0532", place: "Dearborn, Michigan", latitude: 42.0833, longitude: -83.0833,
            events: ford, ayanamsa: "raman", node: "mean",
            source: "B.V. Raman, Notable Horoscopes No. 38: 2 p.m. local mean time, marked in print as his own estimate. The documented time is 7:00 a.m. (rating B). This chart is for following his reading; under his ayanamsa the engine matches his printed Sun and Mars to a minute of arc.")),
        Entry(key: "aurobindo-raman", birth: Birth(name: "Sri Aurobindo (Raman, 5:17 am)", date: "1872-08-15", time: "05:16:40", zone: "GMT+0553", place: "Calcutta, India", latitude: 22.5, longitude: 88.3333,
            events: aurobindo, ayanamsa: "raman", node: "mean",
            source: "B.V. Raman, Notable Horoscopes No. 43: 5:17 a.m. local mean time. The biography gives 5:00 a.m. (rating B). This chart is for following his reading; under his ayanamsa the engine matches his printed Sun and Mars to a minute of arc.")),
        Entry(key: "gandhi", birth: Birth(name: "Mahatma Gandhi (C, Raman 7:45 am)", date: "1869-10-02", time: "07:44:44", zone: "GMT+0439", place: "Porbandar, India", latitude: 21.6167, longitude: 69.8167,
            events: gandhi, ayanamsa: "raman", node: "mean",
            source: "Rodden rating C: no birth record is known, and published times run from about 7:08 to 7:45 a.m., all rectified. This is B.V. Raman's 7:45 a.m. (Notable Horoscopes No. 41). The ephemeris places the Moon in Karka and Jupiter in Mesha, where his hand tables print Simha and Vrishabha: read this chart with that in mind.")),
        Entry(key: "tagore", birth: Birth(name: "Rabindranath Tagore (DD, Raman 2:51 am)", date: "1861-05-07", time: "02:51:00", zone: "GMT+0554", place: "Calcutta, India", latitude: 22.6667, longitude: 88.5,
            events: tagore, ayanamsa: "raman", node: "mean",
            source: "Rodden rating DD: sources conflict; Astro-Databank lists 4:02 a.m., B.V. Raman 2:51 a.m. (Notable Horoscopes No. 35). This is Raman's time, for following his reading; under his ayanamsa the engine matches his printed positions to two minutes of arc.")),
    ]

    /// names the first set of public charts was saved under, replaced by the documented set
    private static let earlier = ["Albert Einstein (Raman)", "Mahatma Gandhi (Raman)", "Rabindranath Tagore (Raman)", "Swami Vivekananda (Raman)", "Henry Ford (Raman)", "Sri Aurobindo (Raman)"]

    /// `FormJyotish --save-public`: add every public chart that is not yet among the saved charts, and leave.
    /// Charts saved under the first set's names are replaced. The reader's own charts and settings are not touched.
    static func saveAll() -> Int {
        let file = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("FormJyotish/charts.json")
        var saved = ((try? JSONDecoder().decode([Birth].self, from: Data(contentsOf: file))) ?? []).filter { !earlier.contains($0.name) }
        let missing = all.filter { entry in !saved.contains { $0.name == entry.birth.name } }
        saved += missing.map { var b = $0.birth; b.id = UUID(); return b }
        guard let data = try? JSONEncoder().encode(saved) else { return 0 }
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: file, options: .atomic)
        return missing.count
    }
}
