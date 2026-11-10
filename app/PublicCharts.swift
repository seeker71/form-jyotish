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

    /// Local mean time is written as a fixed offset: Ulm stands 40 minutes east of Greenwich, Porbandar
    /// 4 hours 39 minutes 16 seconds (the 16 seconds are taken off the clock time).
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
    ]
}
