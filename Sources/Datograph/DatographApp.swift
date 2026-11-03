import SwiftUI

@main
struct DatographApp: App {
    @State private var clock = Clock()
    @State private var calendarStore = CalendarStore()
    @AppStorage(Pref.menuBarPattern) private var pattern = MenuBarFormat.defaultPattern

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environment(clock)
                .environment(calendarStore)
        } label: {
            MenuBarLabel(clock: clock, pattern: pattern)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(clock)
                .environment(calendarStore)
        }
    }
}

struct MenuBarLabel: View {
    let clock: Clock
    let pattern: String

    var body: some View {
        if pattern.trimmingCharacters(in: .whitespaces).isEmpty {
            Image(systemName: "calendar")
        } else {
            Text(MenuBarFormat.string(from: clock.now, pattern: pattern))
        }
    }
}

/// The app's single source of time. `now` ticks every second; `today` changes only at midnight,
/// so views that just need the date don't re-render every second.
@MainActor @Observable
final class Clock {
    private(set) var now = Date.now
    private(set) var today = Calendar.autoupdatingCurrent.startOfDay(for: .now)

    init() {
        Task { [weak self] in
            while true {
                // Wake just after the next whole second so the menu bar never lags behind.
                let fraction = Date.now.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1)
                try? await Task.sleep(for: .seconds(1 - fraction))
                guard let self else { return }
                now = .now
                let day = Calendar.autoupdatingCurrent.startOfDay(for: now)
                if day != today { today = day }
            }
        }
    }
}
