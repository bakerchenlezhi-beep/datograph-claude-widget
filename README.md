# Datograph

A menu bar calendar for macOS 14+, inspired by [Dato](https://sindresorhus.com/dato).

Datograph puts the date and time in your menu bar. Click it for a month calendar, your upcoming events from macOS Calendar, world clocks, and a few date tools. It's a native SwiftUI app with no dependencies, and it makes no network requests.

## Features

- **Menu bar clock**: Shows the date and time in any [date format pattern](https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table), with an optional icon: the date in a calendar, the date with a border, or a clock.
- **Next event**: A separate menu bar item for the next timed event starting within 12 hours, such as "Standup in 12 min", "Standup in 1 h 40 min" or "Standup · now".
- **Month calendar**: Optional week numbers, highlighted weekends (following your region), a configurable first weekday, and up to three colored dots on days with events.
- **Upcoming events**: Events from macOS Calendar for the next 1, 3, 7 or 14 days, starting from the day you select. Clicking an event opens [Notion Calendar](https://www.notion.com/product/calendar).
- **Go to Date**: Type "24 Dec", "next friday" or "2027-01-05" to jump to that date.
- **Date calculator**: Count the days between two dates, or add or subtract days, weeks, months or years.
- **World clocks**: Any number of time zones, each with its offset from your local time and a note when it's already tomorrow or still yesterday there.
- **Settings**: Menu bar format and icon, launch at login, visible calendars, and world clocks.

## Requirements

- macOS 14 Sonoma or later
- Swift 6 (Xcode 16 or later, or the Command Line Tools) to build
- [Notion Calendar](https://www.notion.com/product/calendar) (optional), for opening events

## Install

There's no prebuilt release, so build it from source:

```sh
git clone https://github.com/bakerchenlezhi-beep/datograph-claude-widget.git
cd datograph-claude-widget
./scripts/build-app.sh
cp -R build.noindex/Datograph.app /Applications/
open /Applications/Datograph.app
```

Datograph runs only in the menu bar, with no Dock icon. The first time you open it, click **Allow Calendar Access** in the popover to see your events.

## Usage

Click the date in the menu bar to open the popover.

| Control | What it does |
| --- | --- |
| **±** | Switches between the event list and Go to Date with the date calculator |
| **‹** and **›** | Previous and next month |
| **•** | Back to today |
| A day | Lists events starting from that day |
| An event | Opens Notion Calendar |
| **⚙** | Settings and Quit |

### Menu bar format

In **Settings › General**, pick a preset (Time, Time with seconds, Weekday and time, Date and time, or Date) or type your own pattern. The presets adapt to your region's date and time format. Some example patterns, shown for Tuesday 3 November at 18:05:09 in English:

| Pattern | Shows |
| --- | --- |
| `HH:mm` | 18:05 |
| `h:mm a` | 6:05 PM |
| `EEE d MMM  HH:mm` | Tue 3 Nov  18:05 |
| `EEEE, MMMM d` | Tuesday, November 3 |
| `d/M  HH:mm:ss` | 3/11  18:05:09 |
| `'Week' w` | Week 45 |

Put literal text in single quotes. If the pattern is empty and no icon is set, Datograph shows the calendar icon so the item doesn't disappear.

### Settings

- **General**: Menu bar style, format, icon and preview; show next event; launch at login.
- **Calendar**: First day of the week, week numbers, weekend highlighting, how many days of events to show, and which calendars to include, grouped by account.
- **World Clocks**: Add time zones by city or identifier, drag to reorder, and remove them.

## Privacy

Datograph reads your calendars with EventKit, on your Mac only. It makes no network requests and collects no data. Your settings are stored in the app's user defaults.

## Development

```sh
swift build                     # debug build
swift test                      # runs the unit tests
./scripts/build-app.sh          # builds and ad-hoc signs build.noindex/Datograph.app
swift scripts/make-icon.swift   # redraws Resources/AppIcon.icns
```

The app bundle is built into `build.noindex/` because Spotlight skips folders ending in `.noindex`, so the build copy doesn't appear next to the installed app.

| Path | Contents |
| --- | --- |
| `Sources/Datograph/DatographApp.swift` | App entry point, the two menu bar items, and the shared clock |
| `Sources/Datograph/MenuBarLabel.swift` | Menu bar text and icon rendering |
| `Sources/Datograph/PopoverView.swift` | Month calendar, events, date tools, world clocks and footer |
| `Sources/Datograph/SettingsView.swift` | Settings window |
| `Sources/Datograph/CalendarStore.swift` | EventKit access and event queries |
| `Sources/Datograph/CalendarMath.swift` | Date logic: month grid, date parsing, date differences, next event text, world clock offsets, menu bar formats |
| `Tests/DatographTests/` | Unit tests for the date logic |
| `Resources/` | `Info.plist` and the app icon |
| `scripts/` | Build and icon scripts |

## Known limitations

- The app is ad-hoc signed, so macOS may ask for Calendar access again after each rebuild. The copy in `/Applications` keeps its access until you replace it.
- Clicking an event opens Notion Calendar but not the event itself. Notion Calendar's event links need the account's email address, which macOS Calendar doesn't expose for iCloud, subscribed or birthday calendars.
- The next event item ignores all-day events.
