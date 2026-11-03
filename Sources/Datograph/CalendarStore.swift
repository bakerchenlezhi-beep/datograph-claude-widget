import EventKit

struct EventDay: Identifiable {
    let day: Date
    let events: [EKEvent]
    var id: Date { day }
}

@MainActor @Observable
final class CalendarStore {
    private let store = EKEventStore()
    private(set) var status = EKEventStore.authorizationStatus(for: .event)
    private(set) var calendars: [EKCalendar] = []
    /// Bumped whenever the event store changes, so views that fetch events re-render.
    private var revision = 0

    var hasAccess: Bool { status == .fullAccess }

    init() {
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.reload() }
        }
        reload()
    }

    func requestAccess() {
        store.requestFullAccessToEvents { [weak self] _, _ in
            Task { @MainActor in self?.reload() }
        }
    }

    private func reload() {
        status = EKEventStore.authorizationStatus(for: .event)
        calendars = hasAccess ? store.calendars(for: .event) : []
        revision += 1
    }

    /// One entry per day for `days` days starting at `start`. Each entry lists the events overlapping that day,
    /// all-day events first.
    func eventsByDay(from start: Date, days: Int, calendar: Calendar, hiddenCalendarIDs: Set<String>) -> [EventDay] {
        _ = revision
        let first = calendar.startOfDay(for: start)
        let boundaries = (0...days).compactMap { calendar.date(byAdding: .day, value: $0, to: first) }
        let visible = calendars.filter { !hiddenCalendarIDs.contains($0.calendarIdentifier) }

        var events: [EKEvent] = []
        if hasAccess, !visible.isEmpty, let end = boundaries.last {
            events = store.events(matching: store.predicateForEvents(withStart: first, end: end, calendars: visible))
                .sorted { a, b in
                    a.isAllDay != b.isAllDay ? a.isAllDay : a.startDate < b.startDate
                }
        }

        return zip(boundaries, boundaries.dropFirst()).map { dayStart, dayEnd in
            EventDay(day: dayStart, events: events.filter {
                $0.startDate < dayEnd && ($0.endDate > dayStart || $0.startDate >= dayStart)
            })
        }
    }
}
