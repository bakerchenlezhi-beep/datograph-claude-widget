# Datograph

A menu bar calendar for macOS 14+, inspired by [Dato](https://sindresorhus.com/dato).

- Date and time in the menu bar, in any [date format pattern](https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table), or a calendar icon if the format is empty
- Month calendar with optional week numbers, a configurable first weekday, and dots on days with events
- Upcoming events from macOS Calendar, starting from the selected day
- World clocks showing each zone's offset from local time
- Settings for menu bar format, launch at login, visible calendars, and world clocks

## Build

```sh
./scripts/build-app.sh      # builds and ad-hoc signs build/Datograph.app
open build/Datograph.app
swift test                  # runs the unit tests
```

The app is ad-hoc signed, so macOS may ask for Calendar access again after a rebuild.
To keep it, copy `build/Datograph.app` to `/Applications`.
