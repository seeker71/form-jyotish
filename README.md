# Form Jyotish

A Vedic astrology app for the Mac. The calculation is Form: BML cells run by the
[coherence-kernel](../coherence-kernel)'s `fkwu`. A thin SwiftUI shell collects the birth data and draws
what the engine returns.

## Download

[FormJyotish.zip](https://github.com/seeker71/form-jyotish/releases/latest/download/FormJyotish.zip) is the
latest built app, for Apple Silicon Macs on macOS 14 or later. Unzip it and move Form Jyotish to the
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
- Krishnamurti Paddhati: positions under the KP ayanamsa, Placidus cusps, star, sub and sub-sub lords, the
  significators of houses and grahas, ruling planets and Fortuna. The significator sets are folded in the
  shell (`app/Reading.swift`) from what the engine returns.
- Transits: the sky at any moment set in the houses of the birth lagna.
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
| `engine/chart.bml` | the Jyotish reading and its JSON |
| `engine/chart-run.bml` | the door: one line in, one JSON line out |
| `witness/positions-run.bml` | seven bodies against JPL Horizons, within 0.3 arcsec |
| `witness/swiss-run.bml` | Sun, Moon, lagna and ayanamsa against Swiss Ephemeris, Lahiri and True Chitra, within 0.5 arcsec |
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

Bhava bala, the dasha systems beyond Vimshottari, Jaimini, varshaphala, muhurta, yogas,
compatibility, interpretive text, and an atlas that works offline.
