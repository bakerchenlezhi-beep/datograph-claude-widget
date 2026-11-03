# Datograph

A menu bar calendar for macOS 14+, inspired by [Dato](https://sindresorhus.com/dato).

- Date and time in the menu bar, in any [date format pattern](https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table), with an optional icon (date in calendar, date with border, or clock)
- The next event within 12 hours as a separate menu bar item ("Standup in 12 min")
- Month calendar with optional week numbers, highlighted weekends, a configurable first weekday, and dots on days with events
- Upcoming events from macOS Calendar, starting from the selected day; clicking an event opens Notion Calendar
- Go to Date ("24 Dec", "next friday") and a date calculator (days between dates, or add/subtract days, weeks, months, years)
- World clocks showing each zone's offset from local time
- Settings for the menu bar, launch at login, visible calendars, and world clocks

## Build

```sh
./scripts/build-app.sh      # builds and ad-hoc signs build.noindex/Datograph.app
open build.noindex/Datograph.app
swift test                  # runs the unit tests
swift scripts/make-icon.swift  # redraws Resources/AppIcon.icns
```

The app is ad-hoc signed, so macOS may ask for Calendar access again after a rebuild.
To keep it, copy `build.noindex/Datograph.app` to `/Applications`.
