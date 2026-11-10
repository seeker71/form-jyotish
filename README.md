# Form Jyotish

A Vedic astrology app for the Mac. The calculation is Form: BML cells run by the
[coherence-kernel](../coherence-kernel)'s `fkwu`. A thin SwiftUI shell collects the birth data and draws
what the engine returns.

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
- A printed report (the Report… button, or `FormJyotish --report out.pdf [--ayanamsa truecitra]`): cover,
  birth particulars, birth chart with Moon and navamsa charts and the graha table, and the Chandra,
  Navamsha and Bhava page, in the dress of a classical horoscope.

## Layout

| Path | Holds |
| --- | --- |
| `engine/num.bml` | sine, cosine, arctangent in double precision |
| `engine/spk.bml` | the DAF/SPK reader: segments and Chebyshev states from the file's bytes |
| `engine/sky.bml` | time scales, apparent positions, precession, ayanamsa, node, ascendant |
| `engine/chart.bml` | the Jyotish reading and its JSON |
| `engine/chart-run.bml` | the door: one line in, one JSON line out |
| `witness/positions-run.bml` | seven bodies against JPL Horizons, within 0.3 arcsec |
| `witness/swiss-run.bml` | Sun, Moon, lagna and ayanamsa against Swiss Ephemeris, Lahiri and True Chitra, within 0.5 arcsec |
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
./make-app.sh && open FormJyotish.app                                                       # the app, as a bundle
```

The app finds this folder and the kernel at the paths it was built from; both can be changed in Settings.

## Not yet here

The other divisional charts, shadbala and ashtakavarga, further dasha systems, transits, muhurta, yogas,
compatibility, printing, and an atlas that works offline.
