import SwiftUI

@main
struct DatographApp: App {
    @State private var clock = Clock()
    @State private var calendarStore = CalendarStore()
    @AppStorage(Pref.menuBarPattern) private var pattern = MenuBarFormat.defaultPattern
    @AppStorage(Pref.menuBarIcon) private var icon = MenuBarIcon.none
    @AppStorage(Pref.showNextEvent) private var showNextEvent = true
    @AppStorage(Pref.hiddenCalendarIDs) private var hiddenCalendarIDs = ""

    var body: some Scene {
        let nextEvent = showNextEvent
            ? calendarStore.nextEvent(at: clock.minute, hiddenCalendarIDs: Set(hiddenCalendarIDs.listItems))
            : nil
        let hasNextEvent = nextEvent != nil

        MenuBarExtra {
            popover
        } label: {
            MenuBarLabel(clock: clock, pattern: pattern, icon: icon)
        }
        .menuBarExtraStyle(.window)

        // Created after the clock, so macOS places it to the clock's left.
        MenuBarExtra(isInserted: Binding(get: { hasNextEvent }, set: { showNextEvent = $0 })) {
            popover
        } label: {
            Text(nextEvent.map { NextEvent.text(title: $0.title ?? "", start: $0.startDate, now: clock.minute) } ?? "")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(clock)
                .environment(calendarStore)
        }
    }

    private var popover: some View {
        PopoverView()
            .environment(clock)
            .environment(calendarStore)
    }
}

/// The app's single source of time. `now` ticks every second, `minute` once a minute, and `today` only at midnight,
/// so views re-render only as often as what they show changes.
@MainActor @Observable
final class Clock {
    private(set) var now = Date.now
    private(set) var minute = Clock.startOfMinute(.now)
    private(set) var today = Calendar.autoupdatingCurrent.startOfDay(for: .now)

    init() {
        Task { [weak self] in
            while true {
                // Wake just after the next whole second so the menu bar never lags behind.
                let fraction = Date.now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)
                try? await Task.sleep(for: .seconds(1 - fraction))
                guard let self else { return }
                now = .now
                let minute = Clock.startOfMinute(now)
                if minute != self.minute { self.minute = minute }
                let day = Calendar.autoupdatingCurrent.startOfDay(for: now)
                if day != today { today = day }
            }
        }
    }

    private static func startOfMinute(_ date: Date) -> Date {
        Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 60).rounded(.down) * 60)
    }
}
