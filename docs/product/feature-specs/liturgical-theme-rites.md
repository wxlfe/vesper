# Liturgical Theme Rites

Vesper can sync its accent color to a selected liturgical rite or tradition. This is a theme-color approximation, not a complete liturgical calendar engine.

## Supported Defaults

- Roman: Roman Rite, General Roman Calendar, Ordinary Form, using civil Gregorian dates.
- Anglican: Anglican/Episcopal Western calendar in the BCP 1979/Common Worship family, using civil Gregorian dates.
- Lutheran: Revised Common Lectionary / Lutheran Service Book style Western calendar, using civil Gregorian dates.
- Byzantine: Byzantine Rite with Gregorian civil-date fixed feasts and Orthodox Pascha for movable feasts, following common Greek/Antiochian color practice.
- Russian: Russian Orthodox practice with Julian fixed feasts mapped to Gregorian civil dates and Orthodox Pascha for movable feasts.
- Coptic: Coptic Orthodox color practice, with Coptic fixed feasts and Coptic fasts mapped to Gregorian civil dates.

## Color Mapping

- Purple: Advent, Lent, Great Lent, Nativity Fast, and penitential fasting seasons.
- Gold: Christmas/Nativity, Easter/Pascha/Resurrection, and bright major feasts.
- Blue: Marian/Theotokos emphasis where the tradition commonly uses blue.
- Red: Pentecost in Western and Coptic usage, and Cross/Passion emphasis where applicable.
- Black: Good Friday or Great Friday.
- Green: Ordinary/default growth seasons and Byzantine Pentecost.

## Precedence

When multiple rules could apply on one date, Vesper uses this order:

1. Good Friday / Great Friday.
2. Easter, Pascha, Resurrection, Christmas, Nativity, and bright major feasts.
3. Marian/Theotokos fixed feasts.
4. Pentecost.
5. Lent, Great Lent, Advent, Nativity Fast, and other fasting seasons.
6. Ordinary/default season.

## Known Limits

- Local parish, diocesan, synodal, and monastic customs can differ.
- Vesper does not currently calculate complete sanctoral calendars or transferred observances.
- The Russian fixed-feast mapping uses the current 13-day Julian-to-Gregorian offset for contemporary dates.
- Coptic fixed-date conversion is intentionally scoped to theme fixtures and common season ranges used by the app.
