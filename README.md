# Form Jyotish

A Vedic astrology app for the Mac. The calculation is Form: BML cells run by the
[coherence-kernel](../coherence-kernel)'s `fkwu`. A thin SwiftUI shell collects the birth data and draws
what the engine returns.

## Download

[FormJyotish.zip](https://github.com/seeker71/form-jyotish/releases/latest/download/FormJyotish.zip) is the
latest built app, for Apple Silicon and Intel Macs on macOS 13 or later. Unzip it and move Form Jyotish to the
Applications folder. It carries its own engine and ephemeris; nothing else is needed.

The app is not signed with an Apple Developer ID, so the first time it is opened macOS refuses it. Open
System Settings, Privacy & Security, and choose Open Anyway beside its name.

It keeps itself current: at each start it asks GitHub for the latest release, fetches a newer build in the
background, checks it against its published SHA-256, and says so in a bar at the top. The new build takes
the old one's place the next time the app starts (or at once with Restart now).

## What stands today

- Apparent geocentric positions of Surya to Shani read from NASA JPL's DE440 ephemeris (`data/de440s.bsp`,
  1850 to 2149), with light-time and aberration, on the mean ecliptic of date.
- Lahiri (Chitrapaksha) ayanamsa; Rahu and Ketu by the mean or the true (osculating) node.
- Lagna and midheaven for the birth place.
- Rasi, degree, nakshatra, pada, nakshatra lord and navamsa for the lagna and each graha; daily motion and
  retrogression.
- Vimshottari mahadashas and antardashas (a dasha year is 365.25 days).
- Rasi and navamsa charts in South and North Indian form, the graha table and the dasha list; births are
  saved in `~/Library/Application Support/FormJyotish/charts.json`; a place name can be looked up for its
  latitude, longitude and time zone (the name goes to Apple's geocoder).

- A second ayanamsa, True Chitra (Spica held at 180°), beside Lahiri; Uranus, Neptune and Pluto; the Bhrigu
  point; rasi, nakshatra, sub and sub-sub lords; dignity (exalted, debilitated, own, or the compound
  friendship with the sign's lord) and combustion; Sripati bhavas; tithi, yoga and karana at birth; sunrise
  and sunset.
- The sixteen vargas of Parashara (D1 to D60) for the lagna and every graha.
- Vimshottari to four levels: mahadasha, antardasha, pratyantardasha and sookshma dasha.
- The engine reads each graha's latitude, whether a combust graha is closing on the Sun or leaving it, and the
  moment each limb of the day ends. A planetary war goes to the higher latitude, as Light on Life gives the
  rule; a mahapurusha yoga says which of the three lagnas it recurs from; and a card gives the five limbs of
  the day the time bar stands at, with the rising sign, weighed in the birth chart for choosing a time.
- Light on Life is the main reference for the rules of reading. The Strength desk opens on the sky at birth,
  drawn from the chart: the Moon new, dark, bright or full and waxing or waning, whether the birth fell on a
  solar or lunar eclipse, and which planets are retrograde, combust (graded by degrees from the Sun) or at
  war. Then the rules of graha strength and weakness: a table of own sign, exaltation, directional strength, retrogression, debilitation,
  combustion and planetary war with this chart's grahas marked in it; the primary and secondary factors each
  graha meets; the natural relationships and whose guest each graha is; and three charts of rulership,
  exaltation and dig bala on the chart's own lagna.
- The desks follow the order the book teaches: Guide (the zodiac and its ayanamsa, graha significations, the
  houses), Strength, Overview, Yogas, Dasha, Transits, Vargas. Methods the book does not teach (Jaimini, KP,
  the annual chart, matching, shadbala, ashtakavarga, other dasha systems) stand last and are marked as
  additions.
- The houses and grahas as the book teaches them: the classes of houses (kendra, trikona, trik, dusthana,
  maraka, upachaya) and the four aims of life as four trines, drawn on the chart's lagna with its grahas
  counted in each aim; every significator of each house and where it stands; what each house and each graha
  stands for. Every karaka of a house is weighed as a limb when the house is judged.
- The twelve houses judged by three limbs, the house, its lord and its karaka, after Hart de Fouw and Robert
  Svoboda's Light on Life (Phaladipika 15): what supports each limb beside what asks more of it, and where
  the three agree. Dispositors, period lords in transit, and transits counted from the Moon with vedha.
- The running period read by what a dasha activates (yogas, houses ruled, occupied and aspected, company,
  dispositor, karaka), and the two period lords read for confluence or conflict. The panchanga of the birth
  day with weekday and hour lords. Mulatrikona, directional strength, avastha measures, planetary war, gandanta.
- Jaimini: the seven chara karakas and the karakamsa, the twelve arudha padas (with a pada chart), sign
  aspects, and the Chara dasha after K.N. Rao with its twelve equal sub-periods.
- Nine more nakshatra dashas with their sub-periods: Ashtottari, Yogini, Shodashottari, Dwadashottari,
  Panchottari, Shatabdika, Chaturashiti-sama, Dwisaptati-sama and Shat-trimsha-sama, each shown with the
  condition under which the classics apply it and whether the chart meets it.
- Krishnamurti Paddhati: positions under the KP ayanamsa, Placidus cusps, star, sub and sub-sub lords, the
  significators of houses and grahas, ruling planets and Fortuna. The significator sets are folded in the
  shell (`app/Reading.swift`) from what the engine returns.
- Transits: the sky at any moment set in the houses of the birth lagna.
- Transit dates: over a month to three years from any moment, each graha's sign ingresses, its stations
  (turning retrograde or direct), and the exact crossings of the birth grahas and lagna by Mars, Jupiter,
  Saturn and the nodes, each timed to under a minute and placed in its house from the birth lagna and
  Moon; Saturn's ingresses name Sade Sati and its passage through the 4th and 8th from the Moon.
- Aspects (which signs each graha looks at in full), the avasthas (baladi, jagradadi, deeptadi), and a first
  set of classical yogas, each stated with the rule it met: the mahapurusha yogas, raja and dhana yogas,
  viparita raja yogas, parivartana, the Moon's and the Sun's yogas, kartari, neecha-bhanga, and the doshas.
- Strength: ashtakavarga (each graha's bindus by sign, and the sarvashtakavarga) and the six-fold shadbala
  after B.V. Raman, row by row, with rupas and the share of what is required. Planetary war is not read.
- A printed report (⌘K, "report"; or `FormJyotish --report out.pdf [--ayanamsa truecitra]`), 24
  pages in the dress of a classical horoscope: cover, birth particulars, birth chart, Chandra, Navamsha
  and Bhava, two pages of divisional charts, shadbala, ashtakavarga, Vimshottari (mahadasha and antardasha, nine pages of
  pratyantardashas, three of sookshma dashas from today), two of Krishnamurti Paddhati, and the transits
  of the day.

## The window

- **A teacher.** The Guide workspace opens first: the eight steps by which a chart is read, each with a link
  that shows that step in this chart; the chart's main facts as plain sentences, every name a link; and the
  twelve houses, each with what it covers, its lord and where the lord stands, who is in it, who looks at
  it, and its bindus. Picking a graha lists what supports it and what strains it, side by side, and what
  its nakshatra stands for. Sample charts can be added from ⌘K. The general understandings live in
  `app/Lore.swift`; they state the factors a reader weighs and leave the judgment to the reader.
- **The running period in context** (Dasha workspace): the maha, antar and pratyantar dashas at the time bar's
  moment with how far through each stands; what each lord rules and where it stands; its supports and
  strains; how the two lords stand to each other; and where Saturn, Jupiter and Rahu are passing, with the
  bindus of those signs.
- **Glossary and search.** A Glossary card on the Guide workspace holds every term the app uses (the basic
  ideas, the grahas, signs, houses, nakshatras, the strength rows, dasha levels and KP terms), searchable,
  each in plain words and, where it applies, with what it is in the open chart. ⌘K answers "what is…" for
  the basic ideas and picks any graha, sign or house by name.
- **Voice.** The app states the conditions a chart shows and the understandings the tradition attaches to
  them. It keeps the tradition's words (dusthana, debilitated, malefic) and gives their constructive
  reading: effort, depth, release, strength gained by use. What supports a graha and what asks more of it
  stand side by side; what is made of them remains with the person. The Sources and voice card says what
  the numbers and rules rest on.
- **One pick.** Click a graha, a sign or a dasha period on any card; the inspector at the right explains
  it and every other card highlights the same thing.
- **One time.** The bar at the bottom moves the whole desk: Birth, Now, step, play. Away from the birth,
  the sky of that moment is drawn beside the birth positions in every chart. Rectify steps the birth time
  itself in seconds and minutes; Apply writes it into the birth data.
- **Workspaces of cards.** Overview, Vargas, Dasha, KP and Transits come filled; cards can be added,
  moved and removed, and the layout is remembered.
- **Help in place.** Each workspace, card and inspector section carries a short explanation in plain words,
  and every control, column heading and chart label has a tooltip. The ? button in the toolbar hides the
  explanations once they are no longer needed; the tooltips stay. The words live in `app/Help.swift`.
- **Type to do anything (⌘K).** "d9", "kp", "north", "true chitra", "now", "report".
- The Vimshottari timeline zooms from 120 years to six weeks, showing finer levels as it narrows; dragging
  along it moves the moment, a click picks the period.

Each reading is a fresh run of the engine (about a twentieth of a second), so nothing on screen is
interpolated.

## Layout

| Path | Holds |
| --- | --- |
| `engine/num.bml` | sine, cosine, arctangent in double precision |
| `engine/spk.bml` | the DAF/SPK reader: segments and Chebyshev states from the file's bytes |
| `engine/sky.bml` | time scales, apparent positions, precession, ayanamsa, node, ascendant |
| `engine/strength.bml` | the sixteen vargas, ashtakavarga and shadbala |
| `engine/yoga.bml` | aspects and the classical yogas |
| `engine/jaimini.bml` | chara karakas, arudha padas, sign aspects, the Chara dasha |
| `engine/chart.bml` | the Jyotish reading and its JSON |
| `engine/chart-run.bml` | the door: one line in, one JSON line out |
| `engine/transit.bml`, `engine/transit-run.bml` | dated transit events, and their door |
| `witness/positions-run.bml` | seven bodies against JPL Horizons, within 0.3 arcsec |
| `witness/swiss-run.bml` | Sun, Moon, lagna and ayanamsa against Swiss Ephemeris, Lahiri and True Chitra, within 0.5 arcsec |
| `witness/transit-run.bml` | an ingress and a station against Swiss Ephemeris, each within a minute |
| `witness/dasha-run.bml`, `witness/jaimini-run.bml` | the nakshatra dashas' and the Jaimini readings' rules |
| `witness/strength-run.bml` | the strength module's invariants: ashtakavarga row sums, varga signs, natural order |
| `app/` | the SwiftUI shell; `app/Report.swift` draws the report |

## Setup

The kernel compiles BML against its own `form/` and `runtime/` trees, read from the working directory. They
stand here as links (the app makes them on first run):

```sh
ln -s ../coherence-kernel/form form
ln -s ../coherence-kernel/runtime runtime
```

The ephemeris is not in git (32 MB, public domain):

```sh
curl -L -o data/de440s.bsp https://naif.jpl.nasa.gov/pub/naif/generic_kernels/spk/planets/de440s.bsp
```

## Run

```sh
printf '2451545.0 28.6139 77.2090 mean\n' | ../coherence-kernel/fkwu engine/chart-run.bml   # the engine alone
../coherence-kernel/fkwu witness/positions-run.bml </dev/null                               # the witness
swift run                                                                                   # the app, from source
./make-app.sh && open FormJyotish.app                                                       # the app, as a self-contained bundle
./release.sh                                                                                # publish this commit as build N on GitHub
```

Run from source, the app finds this folder and the kernel at the paths it was built from; both can be
changed in Settings. The built bundle carries `fkwu`, the engine's compiled image and the ephemeris under
`Contents/Resources/payload` and needs neither.

## Not yet here

Bhava bala, the other rasi dashas (Narayana, Sthira and the rest) and Kalachakra, Jaimini, varshaphala, muhurta, yogas,
compatibility, interpretive text, and an atlas that works offline.
