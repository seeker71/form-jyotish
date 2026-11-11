import Foundation

/// What each yoga is taken to mean. Two parts for every yoga: what the classical texts say of it, stated
/// plainly and attributed to them, and how it can be read as a condition a person works with.
/// The results follow Mantreswara's Phaladipika (chapter 6) and Parashara, retold in this app's own words.
struct YogaMeaning {
    var tradition: String
    var reading: String
    var line: String { "Tradition: \(tradition) Read as: \(reading)" }
}

extension Lore {
    /// The principle the yogas are read under: a yoga gives in the measure of its grahas' standing.
    static let yogaPrinciple = "A yoga gives in the measure of its grahas. A supportive yoga shows fully when its grahas stand strong (own or exalted sign, free of combustion); a point of attention weighs most when its grahas stand weak, and lightly when they stand strong. Each row states the rule met, the tradition's reading, and a reading to work with."

    private static func m(_ tradition: String, _ reading: String) -> YogaMeaning { YogaMeaning(tradition: tradition, reading: reading) }

    private static let meanings: [String: YogaMeaning] = [
        // ---- the five mahapurusha yogas ----
        "Ruchaka yoga": m("courage, command and wealth won by bold deeds; fame by merit; the texts add pride.", "drive that leads from the front. It asks that force be joined with regard for others."),
        "Bhadra yoga": m("a long life, intelligence, a clean mind and body, eloquence, prosperity and the praise of the learned.", "a clear mind and skilled speech, which grow through study and honest exchange."),
        "Hamsa yoga": m("an honoured standing in public life, virtue, a graceful body and the respect of good people.", "wisdom and generosity that others trust. It grows by teaching and by fairness."),
        "Malavya yoga": m("strength, prosperity, a happy household, good vehicles, learning, renown and steady senses.", "a gift for beauty, relationship and ease. It asks that comfort also serve others."),
        "Shasha yoga": m("wide acclaim, good helpers, strength and authority over a village or more; the texts also warn of taking what belongs to others.", "endurance and organising power. It asks for integrity in the use of authority."),
        // ---- yogas of status and wealth ----
        "Dharma-karma-adhipati raja yoga": m("a rise in one's field of endeavour; a raja yoga.", "purpose (the trine) joined with action (the angle). It shows most in the periods of these two grahas; a link through the 7th lord is the mildest."),
        "Dharma-karmadhipati yoga (9th and 10th)": m("the foremost raja yoga: fortune and work joined, giving standing and achievement.", "what a person believes in and what they do become one path."),
        "Yogakaraka": m("one graha that alone carries a raja yoga for this lagna.", "the graha whose periods most readily bring purpose and action together."),
        "Dhana yoga": m("it brings wealth.", "the houses of self and fortune linked with those of income and gain. Resources grow where effort follows these grahas' periods."),
        "Dhana yoga (placed)": m("it brings wealth.", "a lord of self, fortune or income seated in a house of wealth: a steady support for earning and keeping."),
        "Viparita raja yoga": m("great prosperity; the texts say a king of kings.", "difficulty set against difficulty: gains that come out of adversity, often after a reversal. Strong standing of the graha helps it show."),
        "Lakshmi yoga": m("wealth, nobility and good fortune.", "fortune that stands on its own feet. It grows with generosity and right conduct."),
        "Maha-Lakshmi yoga": m("the favour of Lakshmi: wealth, brilliance, health, fine conveyances, generosity, a noble partner and capable, protective leadership.", "fortune and enjoyment both well placed. It asks that abundance be shared and well governed."),
        "Vasumati yoga": m("great wealth, and a life that stays in its own home or land.", "benefics in the houses that grow with time: resources that build steadily through effort."),
        "Su-shubha yoga": m("learning, wealth, eloquent speech and the blessing of family.", "a kindly influence on speech, food, family and savings."),
        "Amala yoga": m("virtue, faith, happiness, good fortune, an amiable nature, lands, wealth, fame and wisdom; a spotless name.", "work done cleanly. The reputation follows the conduct."),
        "Shubha-mala yoga": m("an administrator or high official, honoured, generous, helpful, devoted to kin, brave, with a virtuous partner and children.", "the benefics gathered around partnership and service: a talent for working with and for people."),
        "Ashubha-mala yoga": m("the texts speak sternly here: waywardness, unhappiness, quarrels, timidity, ingratitude, unpopularity.", "the benefics work in the houses of effort and release. Their gifts come through service, healing and letting go, and ask for patience with others."),
        "Mahabhagya yoga": m("wide popularity, generosity, a very high reputation, rulership, a life of about eighty years and a spotless character; for a woman, great good fortune and gracious manners.", "the lagna and both lights in accord with the hour of birth: a nature at one with itself, which others readily follow."),
        "Pushkala yoga": m("honour from those in power, renown, wealth, fine dress, good fortune, leadership of many and a high status.", "mind and self in friendly company, with the lagna supported: standing that comes through goodwill."),
        "Parvata yoga": m("lasting wealth and happiness, works of lasting public benefit (rest houses, hospitals, temples, reservoirs) and leadership.", "the lagna lord well hosted: a life with firm backing, inclined to build what serves others."),
        "Parvata yoga (benefics in angles)": m("wealth, eloquence, generosity, learning and fame (Parashara's form of Parvata).", "benefics hold the angles while the houses of strain stay clear: a well-supported life."),
        "Kahala yoga": m("prosperity, nobility, benevolence, kindness and great popularity with the public.", "a chain of good hosting behind the lagna lord: support that arrives from further back than is seen."),
        "Kahala yoga (4th and 9th lords)": m("boldness, energy and leadership of a group or force (Parashara's form of Kahala).", "home and fortune working together: daring that has ground under it."),
        "Shankha yoga": m("long life, virtue, learning, comforts, kindness and a good family.", "intelligence and effort working in step."),
        "Chatussagara yoga": m("fame reaching the four oceans, wealth and standing equal to a ruler.", "all four pillars of the chart occupied: an active life in body, home, partnership and work."),
        "Chamara yoga (lagna lord exalted)": m("honour from rulers, learning, eloquence and a long life.", "a strong self under Jupiter's guidance."),
        "Guru-Mangala yoga": m("energy joined with judgment: leadership, wealth and righteous action.", "courage guided by principle."),
        "Saraswati yoga": m("high intelligence; skill in prose, drama, poetry, rhetoric, mathematics and the exposition of sacred texts; wide fame, wealth, family and honour from the great.", "the three benefics well placed: learning and art that ripen with practice and are meant to be shared."),
        "Pravrajya yoga": m("renunciation: an ascetic of the order shown by the strongest of the gathered grahas.", "a life gathered around one calling, with a pull toward simplicity or a dedicated path."),
        "Pravrajya yoga (Moon and Saturn)": m("renunciation in the order signified by Mars.", "a mind schooled by Saturn: detachment, discipline and a taste for the essential."),
        // ---- the Moon ----
        "Kesari yoga": m("lion-like against opposition; wise and noble speech in assembly; a passionate temperament; long life, high reputation, intelligence, and success by one's own valour.", "wisdom in an angle to the mind: confidence that rests on understanding."),
        "Gaja-Kesari yoga": m("splendour, wealth, intelligence, many praiseworthy virtues and the favour of those in authority.", "Kesari in its full form, with Jupiter supported and unweakened: good judgment that people rely on."),
        "Gauri yoga": m("a graceful body, a distinguished family, friendship of those in authority, good qualities, children, and praise for successes.", "a strong, well-placed mind blessed by Jupiter: emotional fullness that draws goodwill."),
        "Adhi yoga": m("a commander, minister or ruler; renown, prosperity, long life and a large soul.", "benefic support facing the Moon: steadiness that lets a person carry responsibility."),
        "Lagnadhi yoga": m("a commander, minister or ruler; renown, prosperity, long life and a large soul (Adhi yoga counted from the lagna).", "benefic support facing the lagna: help arrives through partners and allies."),
        "Chandra-Mangala yoga": m("wealth; gains through women, hospitality, liquids and things from the sea.", "feeling joined with drive: earning power and enterprise. It asks for quick reactions to be cooled before they are acted on."),
        "Sunapha yoga": m("a ruler or the equal of one, with self-earned property, respected for intellect and wealth.", "the mind has something to build on ahead of it: resources made by one's own effort."),
        "Anapha yoga": m("power, good health, a sweet temperament, fame, worldly comforts, good dress and contentment.", "the mind has support behind it: ease, presence and a liking for a well-kept life."),
        "Durudhara yoga": m("the comforts of a ruler, abundant wealth and vehicles, generosity and faithful helpers.", "the mind is accompanied on both sides: support in earning and in letting go."),
        "Kemadruma yoga": m("the texts are severe: obscurity, want and dependence, even for one born to rank.", "a mind that stands alone. It asks for chosen company and steady routines, and grows self-reliance."),
        "Kemadruma bhanga": m("the severity of Kemadruma does not apply.", "the Moon is unflanked but held by grahas in the angles: independence with support near at hand."),
        "Shakata yoga": m("fortune that rises and fades like a turning wheel; an ordinary life without lasting fame; unhappiness.", "it asks for steadiness through rises and dips, and teaches resilience."),
        "Visha yoga": m("heaviness of mind and sorrow.", "feeling held under weight. It asks for kindness toward oneself, and gives emotional maturity."),
        // ---- the Sun ----
        "Budhaditya yoga": m("intelligence, learning, and skill in calculation and analysis.", "the mind close to the self: quick understanding. Mercury clear of combustion gives it more independence of thought."),
        "Vesi yoga": m("the result follows the grahas ahead of the Sun: benefics give good looks, merit and leadership, malefics rough company and unfair speech.", "a mixed company ahead of the Sun: read each graha by its own standing."),
        "Shubha-vesi yoga": m("good looks, happiness, merit, valour, virtue and leadership.", "benefics go ahead of the Sun: what the self undertakes next is well received."),
        "Papa-vesi yoga": m("the texts say: speaking ill of others unfairly, plain looks, and the company of rough people.", "firm grahas go ahead of the Sun. It asks for fairness in speech and care in the choice of company, and gives grit."),
        "Vasi yoga": m("the result follows the grahas behind the Sun: benefics give renown and prosperity, malefics harsh speech and rough company.", "a mixed company behind the Sun: read each graha by its own standing."),
        "Shubha-vasi yoga": m("renown, the affection of all, wealth and prosperity.", "benefics stand behind the Sun: the self is backed by goodwill and learning."),
        "Papa-vasi yoga": m("the texts say: dishonesty, harsh and abusive speech, and rough company.", "firm grahas stand behind the Sun. It asks for truthfulness and gentleness in speech, and gives toughness."),
        "Ubhayachari yoga": m("the result follows the grahas on both sides of the Sun.", "the Sun is accompanied on both sides by a mixed company: read each graha by its own standing."),
        "Shubha-ubhayachari yoga": m("an attractive body, soft speech, the power to delight people, eloquence, renown and wealth.", "the self is carried by benefics on both sides."),
        "Papa-ubhayachari yoga": m("the texts say: mental suffering through public dishonour, and want of wealth and fortune.", "the Sun is hemmed by firm grahas. It asks for a reputation built slowly on reliable acts, and gives endurance."),
        // ---- the lagna ----
        "Shubha-kartari yoga": m("a long life, fearlessness, health and freedom from enemies.", "the lagna is kept between benefics: protection and help at hand."),
        "Papa-kartari yoga": m("the texts say: unhappiness, loss in family life, weak limbs and a shorter life.", "a lagna held between firm influences. It asks for clear boundaries and care of the body, and builds resilience."),
        // ---- exchange ----
        "Maha-parivartana yoga": m("the grace of Shri: fine clothes and ornaments, honour and authority from those in power, children, wealth and conveyances.", "two houses work as one: each graha looks after the other's affairs."),
        "Dainya-parivartana yoga": m("the texts say: foolish and wrongful acts, harsh speech, an unsteady mind, trouble from opponents and obstacles in every venture.", "one house's affairs are tied to a house of strain: its gains come through effort. It asks for steadiness and care in speech."),
        "Khala-parivartana yoga": m("changeable fortune and temper: at times haughty, at times sweet; prosperity alternating with want.", "initiative that runs in bursts. It asks for an even pace."),
        // ---- cancellation ----
        "Neecha-bhanga raja yoga": m("a rise to power, fame and great wealth, with virtuous deeds.", "a weakness met and turned to strength: what was hard early becomes the ground of achievement. The more of the six conditions hold, the fuller the turn."),
        // ---- points of attention ----
        "Kala-sarpa yoga": m("a pivotal life of great rises and falls; difficulty at the start that can later bloom like the lotus; intensity, ambition and drive.", "a life drawn strongly along one axis. It asks for patience with its turns, and gives focus."),
        "Guru-Chandala yoga": m("judgment clouded, or tradition set aside.", "wisdom meeting the unconventional. It asks for discernment about teachers, and can renew what is handed down."),
        "Grahana yoga": m("an eclipsed light: doubt about oneself or unrest of mind.", "a light that is eclipsed and returns. It asks for patience with self-doubt, and gives depth of insight."),
        "Angaraka yoga": m("anger, haste and conflict.", "drive that runs hot. It asks for a worthy outlet for its force, and gives daring."),
        "Shrapit yoga": m("delays and burdens carried from the past.", "it asks for perseverance and service, and gives endurance."),
        "Dur yoga (the lords reversed)": m("the texts say: poverty, illness, suffering and exclusion.", "strength sits with the houses of strain while the lords of self, home, fortune and work are withdrawn. It asks for rebuilding from within, humility and good allies."),
        // ---- nabhasa: the yogas of number ----
        "Veena yoga": m("fondness for dance, song and musical instruments, and wealth.", "the grahas spread over seven signs: many interests, each given its own voice."),
        "Dama yoga": m("generosity; a benefactor and a leader.", "the grahas in six signs: broad means, readily shared."),
        "Pasha yoga": m("enjoyment of life, wealth, good conduct and many relatives.", "the grahas in five signs: a life well tied into family and company."),
        "Kedara yoga": m("wealth and cultivated land from birth.", "the grahas in four signs: productive, patient work that feeds others."),
        "Shula yoga": m("the texts say: quick to anger, sharp in disposition, and poor.", "the grahas gathered in three signs: concentrated force. It asks for a cause worthy of its edge."),
        "Yuga yoga": m("the texts say: unorthodox in belief, and without wealth.", "the grahas in two signs: a person who goes their own way. It asks for grounding in livelihood."),
        "Gola yoga": m("the texts say: indolence, a short life, want, low company and no skill in a craft.", "all the grahas in one sign: an intense single focus. It asks for breadth, company chosen with care, and a skill built step by step."),
        "Mala yoga": m("comfort, vehicles, fine dress and enjoyment.", "the benefics hold the angles: a well-furnished life."),
        "Sarpa yoga": m("the tradition reads this shape sternly: hardship and harshness.", "its teachers also read it as strength gained through sustained effort."),
        // ---- nabhasa: the shapes (Parashara) ----
        "Rajju yoga": m("love of travel, charm, and earning in other lands.", "all the grahas in movable signs: a life that grows by moving."),
        "Nala yoga": m("skill, resourcefulness and care in gathering means.", "all the grahas in dual signs: adaptability; it asks for one thing finished at a time."),
        "Gada yoga": m("steady effort to earn, skill in sacred learning and song, and wealth.", "the grahas in two neighbouring angles: effort concentrated where it counts."),
        "Shakata (nabhasa) yoga": m("the texts say: a living by carts or carrying, ill health and modest means.", "the grahas divided between self and partner: a life worked out in relationship."),
        "Vihaga yoga": m("love of roaming; a messenger or go-between; the texts add quarrels.", "the grahas divided between home and work: a life that carries things between places."),
        "Shringataka yoga": m("a fighting spirit, happiness, the regard of those in power, a good partner and wealth.", "all the grahas in the trines: purpose runs through everything."),
        "Hala yoga": m("the texts say: a farmer's toil, a large appetite, and want.", "the grahas in one set of trines away from the lagna: patient, practical work."),
        "Vajra yoga": m("happiness at the start and the end of life, valour and charm.", "benefics hold self and partner, firm grahas home and work."),
        "Yava yoga": m("vows kept, happiness in the middle of life, wealth and charity.", "firm grahas hold self and partner, benefics home and work."),
        "Kamala yoga": m("virtue, long life, fame and a great many good deeds; rulership.", "every angle occupied: a full and visible life."),
        "Vapi yoga": m("skill in gathering wealth, and lasting means and happiness.", "the grahas away from the angles: quiet accumulation."),
        "Yupa yoga": m("spiritual knowledge, vows, strength and a good partner.", "the grahas from the lagna to the 4th: a life built from the self outward."),
        "Shara yoga": m("the texts say: a maker of arrows, a keeper of prisoners, a hunter.", "the grahas from the 4th to the 7th: aim and precision. It asks for a kind use of them."),
        "Shakti yoga": m("the texts say: want and little success, with long life, firmness and skill in contest.", "the grahas from the 7th to the 10th: strength spent for others. It asks for rest and fair return."),
        "Danda yoga": m("the texts say: distance from family, want, and service under hard masters.", "the grahas from the 10th to the lagna: a life of duty. It asks for warmth kept alive beside the work."),
        "Nauka yoga": m("a living connected with water, wealth, fame and ambition; the texts add thrift to a fault.", "one graha in each house from the lagna to the 7th: a full first half of the sky."),
        "Kuta yoga": m("the texts say: a keeper of prisons or strongholds, cunning and harshness.", "one graha in each house from the 4th to the 10th: guarded strength. It asks for openness."),
        "Chhatra yoga": m("help to one's own people, kindness, the regard of rulers, intelligence, long life, and happiness early and late.", "one graha in each house from the 7th to the lagna: a sheltering nature."),
        "Chapa yoga": m("the texts say: a keeper of secrets and a wanderer, happiest in the middle of life.", "one graha in each house from the 10th to the 4th: a private, far-ranging life."),
        "Ardha-chandra yoga": m("command of a force, a splendid body, the regard of rulers, strength, gems and gold.", "seven houses in a row away from the angles: a broad and well-furnished life."),
        "Chakra yoga": m("an emperor, to whom other rulers bow.", "the six odd houses filled: initiative in every direction."),
        "Samudra yoga": m("many gems, wealth, enjoyment, the love of people, children and steady means.", "the six even houses filled: depth and holding power."),
        // ---- Phaladipika's bhava yogas: the lord well placed ----
        "Chamara yoga": m("prosperity that grows like the waxing Moon, good conduct, wealth, renown, long life and leadership.", "the lord of the self well placed and well regarded: vitality and standing that increase with time."),
        "Dhenu yoga": m("gold, grain, wealth and precious stones in plenty.", "the lord of resources well placed: earning and keeping come naturally."),
        "Shaurya yoga": m("devoted and successful younger siblings, courage, the admiration of others, a part in public affairs, affection and renown.", "the lord of initiative well placed: courage that wins allies."),
        "Jaladhi yoga": m("cattle and grain, a fine home full of relatives, a good partner, gems, vehicles, high status, lasting happiness, devotion, and wells and reservoirs made for others.", "the lord of home well placed: a deep base, from which giving is easy."),
        "Chatra yoga": m("a happy family life, joy from children, wealth, eloquent speech, a sharp intellect, a counsellor to those in power, and honour.", "the lord of intelligence well placed: learning that advises and creates."),
        "Astra yoga": m("victory over powerful opponents and a strong body; the texts add harshness, pride, quarrels and bruised limbs.", "the lord of contest well placed: fighting strength. It asks to be used for protection and for healing."),
        "Kama yoga": m("faithfulness in marriage, good qualities that surpass the father's, and prosperity.", "the lord of partnership well placed: desire that is loyal and constructive."),
        "Asura yoga": m("the texts say: meddling in others' work, tale-bearing, selfishness, want, forbidden cravings and suffering from one's own acts.", "the lord of the hidden made prominent: strong private drives. It asks for honesty with oneself and discretion, and turns well to research, depth work and transformation."),
        "Bhagya yoga": m("fine conveyances with music and honours, lasting wealth, righteous conduct, devotion, a family made illustrious and a good heart.", "the lord of fortune well placed: meaning and luck that support each other."),
        "Khyati yoga": m("a ruler who protects by a code approved by all; children, friends, a partner, wealth, prosperity and fame.", "the lord of work well placed: achievement that earns a name."),
        "Suparijata yoga": m("always a reason to celebrate; leadership, stored wealth, a large family, love of the songs of the great, learning and auspicious occasions.", "the lord of gains well placed: hopes fulfilled in company."),
        "Musala yoga": m("wealth gathered with difficulty and unstable; humiliation; spending only on rightful purposes; a slow or unsteady mind; heaven after death.", "the lord of release prominent: it asks for patience with money, and guides spending by principle."),
        "Musala (nabhasa) yoga": m("steadiness, standing, wealth and holding to a course.", "all the grahas in fixed signs: staying power."),
        // ---- Phaladipika's bhava yogas: the lord in the 6th, 8th or 12th ----
        "Ava yoga": m("the texts say: obscurity, poverty, a short life, humiliation, poor company, and an unsteady position.", "the lord of the self withdrawn. It asks that health and standing be built deliberately; vitality grows in service, healing and retreat."),
        "Nissva yoga": m("the texts say: harsh speech, childlessness, poor company, trouble with teeth and eyes, want of learning and power, and wealth lost to opponents.", "the lord of resources in a house of strain. It asks for care with speech, money and eyesight; resources are built through service."),
        "Mriti yoga": m("the texts say: overcome by opponents; without siblings, modesty, strength or wealth; tired by unfit acts; excitable.", "courage that tires. It asks for chosen battles and steady habits."),
        "Kuhu yoga": m("the texts say: loss of mother, vehicles, friends, happiness, ornaments and relations; without work or a home.", "home and belonging found the hard way. It asks a person to make their own roots, and gives inner shelter."),
        "Pamara yoga": m("the texts say: a hard living, want of discrimination, untruth, loss of children or none, poor company, no faith, and gluttony.", "intelligence working under strain. It asks for discernment, honesty and something to believe in; creativity comes through discipline."),
        "Harsha yoga": m("happiness, good fortune, a strong constitution, victory over enemies, reluctance to do wrong, eminent friends, wealth, splendour, fame and children.", "the lord of contest kept within the houses of strain: difficulty contained, and joy in overcoming it."),
        "Dushkriti yoga": m("the texts say: separation from the partner, involvement with others' partners, wandering unnoticed, venereal disease, penalty from authority and the dislike of relations.", "partnership under strain. It asks for fidelity, clear agreements and care of sexual health."),
        "Sarala yoga": m("a long life, resolve, fearlessness, prosperity, learning, children, wealth, success in ventures, victory over opponents and celebrity.", "the lord of the hidden kept within the houses of strain: crisis met with a level head."),
        "Nirbhagya yoga": m("the texts say: loss of paternal property, disregard for elders and good people, irreligion, worn clothes and poverty.", "fortune that is made, not inherited. It asks for respect toward teachers and a path of meaning found for oneself."),
        "Dur yoga": m("the texts say: fruitless effort, unimportance, disloyalty and selfishness; a life away from home, abroad.", "work that finds its place far from where it began. It asks for persistence and loyalty."),
        "Daridra yoga": m("the texts say: constant debt, trouble with the ears, want of good siblings and friends, harsh acts, coarse speech and menial work.", "gains that come by a harder road. It asks for care with debt and with hearing, and grows resourcefulness."),
        "Vimala yoga": m("frugality, skill in saving, good behaviour, happiness, independence, a respectable profession and a name for good qualities.", "the lord of release kept within the houses of strain: loss contained, and freedom through simple living."),
    ]

    private static let kuja: [Int: String] = [
        1: "in the 1st: injury to the body and, in the texts, a shorter life.",
        2: "in the 2nd: strain on looks, speech and wealth; tears; service under others.",
        4: "in the 4th: strain around mother, friends, happiness, vehicles and land.",
        7: "in the 7th: impulsive acts, illness, and strain on the partner's health.",
        8: "in the 8th: illness, loss of wealth, blame from others and, in the texts, a shorter life.",
        12: "in the 12th: gossip and harshness, separation from the partner, and trouble with the eyes."
    ]

    /// The meaning of a yoga by its name alone.
    static func yogaMeaning(_ name: String) -> YogaMeaning? {
        if let exact = meanings[name] { return exact }
        if name.hasPrefix("Kuja dosha") { return m("Mars in these houses is read as heat in marriage and the home.", "strong drive in partnership. It asks for a partner of matching energy and for directness handled with care.") }
        if name.hasSuffix("parivartana yoga") { return meanings["Maha-parivartana yoga"] }
        return nil
    }

    /// The meaning of a yoga as it stands in this chart: Kuja dosha is read by the house Mars holds.
    static func yogaMeaning(_ yoga: Yoga, in chart: Chart) -> YogaMeaning? {
        guard yoga.name.hasPrefix("Kuja dosha"), let mars = chart.graha("Ma") else { return yogaMeaning(yoga.name) }
        let from = yoga.name.hasSuffix("Moon") ? chart.graha("Mo")?.sign : yoga.name.hasSuffix("Venus") ? chart.graha("Ve")?.sign : chart.asc.sign
        let house = ((mars.sign - (from ?? chart.asc.sign) + 12) % 12) + 1
        return m("Mars \(kuja[house] ?? "in a house of partnership and home.")", "strong drive in partnership. It asks for a partner of matching energy and for directness handled with care; counted from the lagna first, then the Moon, then Venus.")
    }

    static func yogaNote(_ name: String) -> String? { yogaMeaning(name)?.line }

    /// How the grahas that form a yoga stand: the measure of what it gives.
    static func yogaStanding(_ yoga: Yoga, in chart: Chart) -> String? {
        let notes: [String] = yoga.grahas.compactMap { code in
            guard let g = chart.graha(code) else { return nil }
            var marks: [String] = []
            if g.status == "Exalt." { marks.append("exalted") } else if g.status == "Own" { marks.append("in its own sign") } else if g.status == "Debil." { marks.append("debilitated") }
            if g.combust == true { marks.append("combust") }
            return marks.isEmpty ? nil : "\(Names.lords[code] ?? code) \(marks.joined(separator: " and "))"
        }
        return notes.isEmpty ? nil : "Standing of its grahas: " + notes.joined(separator: "; ") + "."
    }
}
