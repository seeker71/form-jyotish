import Foundation

/// Charts of public figures as published readings give them, with dated events of their lives: for testing
/// the app against readings a reader can look up, and for learning from them.
enum PublicCharts {
    struct Entry {
        let key: String
        let birth: Birth
        /// where the birth data comes from
        let source: String
    }

    private static func events(_ list: [(String, String)]) -> [LifeEvent] { list.map { LifeEvent(date: $0.0, note: $0.1) } }

    /// Local mean time is written as a fixed offset to the minute: Ulm stands 40 minutes east of Greenwich,
    /// Calcutta 5 hours 54 minutes. Where the place's offset has odd seconds they are moved onto the clock
    /// time (Porbandar is 4 h 39 m 16 s east, so 7:45:00 is entered as 07:44:44).
    static let all: [Entry] = [
        Entry(key: "einstein",
              birth: Birth(name: "Albert Einstein (Raman)", date: "1879-03-14", time: "11:30:00", zone: "GMT+0040", place: "Ulm, Germany", latitude: 48.4, longitude: 10.0,
                           events: events([("1902-06-23", "Begins work at the Patent Office in Bern"), ("1903-01-06", "Marriage to Mileva Marić"),
                                           ("1911-04-01", "Professor of physics in Prague"), ("1914-04-01", "Berlin: director of the Kaiser Wilhelm Institute"),
                                           ("1922-11-09", "Nobel Prize in Physics announced"), ("1933-10-17", "Arrives in Princeton"), ("1955-04-18", "Death")])),
              source: "B.V. Raman, Notable Horoscopes, No. 45: 14 March 1879, 11:30 a.m. local mean time, 48°24′ N, 10° E"),
        Entry(key: "gandhi",
              birth: Birth(name: "Mahatma Gandhi (Raman)", date: "1869-10-02", time: "07:44:44", zone: "GMT+0439", place: "Porbandar, India", latitude: 21.6167, longitude: 69.8167,
                           events: events([("1920-08-01", "Non-cooperation movement launched"), ("1922-03-10", "Arrested; imprisoned"), ("1930-03-12", "The Salt March begins"),
                                           ("1942-08-09", "Arrested after the Quit India call"), ("1947-08-15", "Independence of India"), ("1948-01-30", "Assassinated")])),
              source: "B.V. Raman, Notable Horoscopes, No. 41: 2 October 1869, 7:45 a.m. local mean time, 21°37′ N, 69°49′ E"),
        Entry(key: "tagore",
              birth: Birth(name: "Rabindranath Tagore (Raman)", date: "1861-05-07", time: "02:51:00", zone: "GMT+0554", place: "Calcutta, India", latitude: 22.6667, longitude: 88.5,
                           events: events([("1878-09-20", "First voyage to England"), ("1883-12-09", "Marriage to Mrinalini Devi"), ("1901-12-22", "Founds the school at Santiniketan"),
                                           ("1902-11-23", "Death of his wife"), ("1905-01-19", "Death of his father"), ("1913-11-13", "Nobel Prize in Literature announced"), ("1941-08-07", "Death")])),
              source: "B.V. Raman, Notable Horoscopes, No. 35: 7 May 1861, 2:51 a.m. local mean time, 22°40′ N, 88°30′ E"),
        Entry(key: "vivekananda",
              birth: Birth(name: "Swami Vivekananda (Raman)", date: "1863-01-12", time: "06:33:00", zone: "GMT+0554", place: "Calcutta, India", latitude: 22.6667, longitude: 88.5,
                           events: events([("1884-02-25", "Death of his father"), ("1886-08-16", "Passing of Sri Ramakrishna"), ("1893-05-31", "Sails for America"),
                                           ("1893-09-11", "Address at the Parliament of Religions, Chicago"), ("1899-06-20", "Second journey to the West"), ("1902-07-04", "Death")])),
              source: "B.V. Raman, Notable Horoscopes, No. 36: 12 January 1863, 6:33 a.m. local mean time, 22°40′ N, 88°30′ E"),
        Entry(key: "ford",
              birth: Birth(name: "Henry Ford (Raman)", date: "1863-07-30", time: "14:00:20", zone: "GMT-0532", place: "Dearborn, Michigan", latitude: 42.0833, longitude: -83.0833,
                           events: events([("1888-04-11", "Marriage to Clara Bryant"), ("1896-06-04", "Completes his first motor car, the Quadricycle"),
                                           ("1903-06-16", "Ford Motor Company founded"), ("1908-10-01", "The Model T goes on sale"), ("1947-04-07", "Death")])),
              source: "B.V. Raman, Notable Horoscopes, No. 38: 30 July 1863, 2 p.m. local mean time, 42°5′ N, 83°5′ W"),
        Entry(key: "aurobindo",
              birth: Birth(name: "Sri Aurobindo (Raman)", date: "1872-08-15", time: "05:16:40", zone: "GMT+0553", place: "Calcutta, India", latitude: 22.5, longitude: 88.3333,
                           events: events([("1879-06-01", "Taken to England for schooling"), ("1893-02-06", "Returns to India; joins the Baroda service"), ("1907-08-16", "Arrested for sedition"),
                                           ("1908-05-02", "Arrested in the Alipore case; a year in jail"), ("1910-04-04", "Arrives in Pondicherry"), ("1950-12-05", "Death")])),
              source: "B.V. Raman, Notable Horoscopes, No. 43: 15 August 1872, 5:17 a.m. local mean time, 22°30′ N, 88°20′ E"),    ]

    /// `FormJyotish --save-public`: add every public chart that is not yet among the saved charts, and leave.
    /// Settings are not touched.
    static func saveAll() -> Int {
        let file = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("FormJyotish/charts.json")
        var saved = (try? JSONDecoder().decode([Birth].self, from: Data(contentsOf: file))) ?? []
        let missing = all.filter { entry in !saved.contains { $0.name == entry.birth.name } }
        saved += missing.map { var b = $0.birth; b.id = UUID(); return b }
        guard !missing.isEmpty, let data = try? JSONEncoder().encode(saved) else { return 0 }
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: file, options: .atomic)
        return missing.count
    }
}
