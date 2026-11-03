import EventKit
import SwiftUI

struct PopoverView: View {
    @Environment(Clock.self) private var clock
    @AppStorage(Pref.firstWeekday) private var firstWeekday = 0
    @AppStorage(Pref.showWeekNumbers) private var showWeekNumbers = false
    @AppStorage(Pref.highlightWeekends) private var highlightWeekends = true
    @AppStorage(Pref.upcomingDays) private var upcomingDays = 7
    @AppStorage(Pref.hiddenCalendarIDs) private var hiddenCalendarIDs = ""
    @AppStorage(Pref.worldClocks) private var worldClocks = ""

    @State private var displayedMonth = Date.now
    /// `nil` means today, so the selection follows the date across midnight.
    @State private var selectedDay: Date?
    @State private var showDateTools = false

    private var calendar: Calendar { CalendarMath.calendar(firstWeekday: firstWeekday) }

    var body: some View {
        let hidden = Set(hiddenCalendarIDs.listItems)
        let zones = worldClocks.listItems

        VStack(spacing: 0) {
            MonthView(
                displayedMonth: $displayedMonth,
                selectedDay: $selectedDay,
                showDateTools: $showDateTools,
                calendar: calendar,
                showWeekNumbers: showWeekNumbers,
                highlightWeekends: highlightWeekends,
                hiddenCalendarIDs: hidden
            )
            .padding(12)

            Divider()
            // A constant height keeps the popover from changing size: the menu bar window grows to fit
            // taller content but doesn't shrink back, which left gaps around shorter content.
            Group {
                if showDateTools {
                    DateToolsView(calendar: calendar, goTo: goTo)
                } else {
                    EventSection(start: selectedDay ?? clock.today, days: upcomingDays, calendar: calendar, hiddenCalendarIDs: hidden)
                }
            }
            .frame(height: 320, alignment: .top)

            if !zones.isEmpty {
                Divider()
                WorldClocksView(identifiers: zones)
            }

            Divider()
            FooterView()
        }
        .frame(width: 300)
        .onAppear {
            displayedMonth = .now
            selectedDay = nil
            showDateTools = false
        }
    }

    private func goTo(_ date: Date) {
        displayedMonth = date
        selectedDay = calendar.isDate(date, inSameDayAs: clock.today) ? nil : calendar.startOfDay(for: date)
        showDateTools = false
    }
}

// MARK: - Month

struct MonthView: View {
    @Environment(Clock.self) private var clock
    @Environment(CalendarStore.self) private var store
    @Binding var displayedMonth: Date
    @Binding var selectedDay: Date?
    @Binding var showDateTools: Bool
    let calendar: Calendar
    let showWeekNumbers: Bool
    let highlightWeekends: Bool
    let hiddenCalendarIDs: Set<String>

    var body: some View {
        let days = CalendarMath.monthGrid(for: displayedMonth, calendar: calendar)
        let eventDays = store.eventsByDay(from: days[0], days: days.count, calendar: calendar, hiddenCalendarIDs: hiddenCalendarIDs)

        VStack(spacing: 8) {
            header

            // No vertical spacing, so weekend tints join into continuous columns.
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    ForEach(Array(CalendarMath.weekdaySymbols(calendar: calendar).enumerated()), id: \.offset) { column, symbol in
                        Text(symbol)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 3)
                            .background { if isWeekend(days[column]) { WeekendTint() } }
                    }
                }
                ForEach(0..<6, id: \.self) { week in
                    GridRow {
                        ForEach(week * 7 ..< week * 7 + 7, id: \.self) { index in
                            let day = days[index]
                            DayCell(
                                day: day,
                                isInMonth: calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month),
                                isToday: calendar.isDate(day, inSameDayAs: clock.today),
                                isSelected: selectedDay.map { calendar.isDate(day, inSameDayAs: $0) } ?? false,
                                isWeekend: isWeekend(day),
                                dotColors: calendarColors(eventDays[index].events)
                            ) {
                                select(day)
                            }
                            .overlay(alignment: .topLeading) {
                                if showWeekNumbers && index == week * 7 {
                                    weekNumber(for: day)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /// Drawn in the popover's 12pt side padding, left of each week's first day, so turning week numbers on
    /// doesn't move the calendar. The frame and offset line it up with the day number in `DayCell`.
    private func weekNumber(for day: Date) -> some View {
        Text("\(calendar.component(.weekOfYear, from: day))")
            .font(.caption2)
            .monospacedDigit()
            .foregroundStyle(.tertiary)
            .frame(width: 20, height: 24)
            .offset(x: -12, y: 2)
            .allowsHitTesting(false)
    }

    private var header: some View {
        HStack(spacing: 2) {
            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
            Spacer()
            headerButton(showDateTools ? "plusminus.circle.fill" : "plusminus.circle", help: "Go to Date and Date Calculator") {
                showDateTools.toggle()
            }
            headerButton("chevron.left", help: "Previous Month") { shiftMonth(by: -1) }
            headerButton("circle.fill", help: "Today", size: 6) {
                displayedMonth = clock.today
                selectedDay = nil
            }
            headerButton("chevron.right", help: "Next Month") { shiftMonth(by: 1) }
        }
    }

    private func headerButton(_ symbol: String, help: String, size: CGFloat = 12, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .semibold))
                .frame(width: 24, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .help(help)
    }

    private func shiftMonth(by months: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: months, to: displayedMonth) ?? displayedMonth
    }

    private func select(_ day: Date) {
        selectedDay = calendar.isDate(day, inSameDayAs: clock.today) ? nil : day
        if !calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = day
        }
    }

    /// Weekend days follow the user's region (Saturday and Sunday in most places).
    private func isWeekend(_ day: Date) -> Bool {
        highlightWeekends && calendar.isDateInWeekend(day)
    }

    /// Up to three distinct calendar colors, in the order their events occur.
    private func calendarColors(_ events: [EKEvent]) -> [Color] {
        var calendars: [EKCalendar] = []
        for event in events where !calendars.contains(event.calendar) {
            calendars.append(event.calendar)
        }
        return calendars.prefix(3).map { Color(cgColor: $0.cgColor) }
    }
}

struct DayCell: View {
    let day: Date
    let isInMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let isWeekend: Bool
    let dotColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(day.formatted(.dateTime.day()))
                    .font(.system(size: 12, weight: isToday ? .semibold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(textStyle)
                    .frame(width: 24, height: 24)
                    .background {
                        if isToday {
                            Circle().fill(Color.accentColor)
                        } else if isSelected {
                            Circle().fill(.quaternary)
                        }
                    }
                HStack(spacing: 2) {
                    ForEach(dotColors.indices, id: \.self) { index in
                        Circle().fill(dotColors[index]).frame(width: 4, height: 4)
                    }
                }
                .frame(height: 4)
                .opacity(isInMonth ? 1 : 0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .background { if isWeekend { WeekendTint() } }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var textStyle: AnyShapeStyle {
        if isToday { return AnyShapeStyle(.white) }
        return isInMonth ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary)
    }
}

struct WeekendTint: View {
    var body: some View {
        Rectangle().fill(Color.primary.opacity(0.06))
    }
}

// MARK: - Events

struct EventSection: View {
    @Environment(CalendarStore.self) private var store
    let start: Date
    let days: Int
    let calendar: Calendar
    let hiddenCalendarIDs: Set<String>

    var body: some View {
        if store.hasAccess {
            let eventDays = store.eventsByDay(from: start, days: days, calendar: calendar, hiddenCalendarIDs: hiddenCalendarIDs)
            // Always show the first (selected) day, then only days that have events.
            let shown = eventDays.prefix(1) + eventDays.dropFirst().filter { !$0.events.isEmpty }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(shown) { eventDay in
                        EventDayView(eventDay: eventDay, calendar: calendar)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
            .scrollBounceBehavior(.basedOnSize)
        } else {
            CalendarAccessPrompt()
                .padding(12)
                .frame(maxWidth: .infinity)
        }
    }
}

struct EventDayView: View {
    let eventDay: EventDay
    let calendar: Calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(title).fontWeight(.semibold)
                Text(eventDay.day.formatted(.dateTime.month(.abbreviated).day()))
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            if eventDay.events.isEmpty {
                Text("No events")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(eventDay.events, id: \.calendarItemIdentifier) { event in
                    EventRow(event: event)
                }
            }
        }
    }

    private var title: String {
        let day = eventDay.day
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInTomorrow(day) { return "Tomorrow" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide))
    }
}

struct EventRow: View {
    @Environment(Clock.self) private var clock
    let event: EKEvent

    var body: some View {
        Button(action: openNotionCalendar) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color(cgColor: event.calendar.cgColor))
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.title ?? "")
                        .font(.callout)
                        .lineLimit(1)
                    Text(timeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .fixedSize(horizontal: false, vertical: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Open Notion Calendar")
        .opacity(event.endDate < clock.now ? 0.45 : 1)
    }

    private var timeText: String {
        if event.isAllDay { return "All day" }
        return (event.startDate..<max(event.startDate, event.endDate)).formatted(.interval.hour().minute())
    }
}

struct CalendarAccessPrompt: View {
    @Environment(CalendarStore.self) private var store

    var body: some View {
        VStack(spacing: 8) {
            if store.status == .notDetermined {
                Text("See your upcoming events here.")
                    .foregroundStyle(.secondary)
                Button("Allow Calendar Access") { store.requestAccess() }
            } else {
                Text("Datograph doesn’t have access to your calendars.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Open Privacy Settings") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
                }
            }
        }
        .font(.callout)
    }
}

// MARK: - Date tools

struct DateToolsView: View {
    let calendar: Calendar
    let goTo: (Date) -> Void

    private enum Mode { case between, add }

    @State private var query = ""
    @State private var mode = Mode.between
    @State private var start = Date.now
    @State private var end = Date.now
    @State private var amount = 1
    @State private var unit = Calendar.Component.day
    @State private var subtracting = false

    var body: some View {
        let parsed = CalendarMath.parseDate(query)

        VStack(alignment: .leading, spacing: 10) {
            Text("Go to Date").fontWeight(.semibold)
            HStack {
                TextField("24 Dec, next friday…", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { if let parsed { goTo(parsed) } }
                Button("Go") { if let parsed { goTo(parsed) } }
                    .disabled(parsed == nil)
            }
            if !query.isEmpty {
                Text(parsed?.formatted(date: .complete, time: .omitted) ?? "Not a date")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Text("Date Calculator").fontWeight(.semibold)
            Picker("Mode", selection: $mode) {
                Text("Between Dates").tag(Mode.between)
                Text("Add or Subtract").tag(Mode.add)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            switch mode {
            case .between:
                Grid(alignment: .leading, verticalSpacing: 8) {
                    GridRow {
                        Text("From")
                        DatePicker("From", selection: $start, displayedComponents: .date).labelsHidden()
                    }
                    GridRow {
                        Text("To")
                        DatePicker("To", selection: $end, displayedComponents: .date).labelsHidden()
                    }
                }
                Text(CalendarMath.differenceText(from: start, to: end, calendar: calendar))
                    .fontWeight(.medium)
            case .add:
                DatePicker("Date", selection: $start, displayedComponents: .date)
                HStack {
                    Picker("Operation", selection: $subtracting) {
                        Text("+").tag(false)
                        Text("−").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .fixedSize()
                    TextField("Amount", value: $amount, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 56)
                    Picker("Unit", selection: $unit) {
                        Text("days").tag(Calendar.Component.day)
                        Text("weeks").tag(Calendar.Component.weekOfYear)
                        Text("months").tag(Calendar.Component.month)
                        Text("years").tag(Calendar.Component.year)
                    }
                    .labelsHidden()
                }
                if let result = calendar.date(byAdding: unit, value: subtracting ? -amount : amount, to: start) {
                    HStack {
                        Text(result.formatted(date: .complete, time: .omitted))
                            .fontWeight(.medium)
                        Spacer()
                        Button("Show") { goTo(result) }
                    }
                }
            }
        }
        .font(.callout)
        .datePickerStyle(.field)
        .padding(12)
    }
}

// MARK: - World clocks

struct WorldClocksView: View {
    @Environment(Clock.self) private var clock
    let identifiers: [String]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(identifiers, id: \.self) { identifier in
                if let zone = TimeZone(identifier: identifier) {
                    row(zone)
                }
            }
        }
        .padding(12)
    }

    private func row(_ zone: TimeZone) -> some View {
        let local = TimeZone.autoupdatingCurrent
        let dayDifference = WorldClock.dayDifference(at: clock.now, in: zone, relativeTo: local)
        var timeStyle = Date.FormatStyle(date: .omitted, time: .shortened)
        timeStyle.timeZone = zone

        return HStack(spacing: 6) {
            Text(WorldClock.cityName(for: zone.identifier))
                .lineLimit(1)
            Spacer()
            if dayDifference != 0 {
                Text(dayDifference > 0 ? "Tomorrow" : "Yesterday")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(clock.now.formatted(timeStyle))
                .monospacedDigit()
            Text(WorldClock.offsetText(seconds: zone.secondsFromGMT(for: clock.now) - local.secondsFromGMT(for: clock.now)))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .trailing)
        }
        .font(.callout)
    }
}

// MARK: - Footer

/// Opens the Notion Calendar app. It can't jump to a specific event: its `cron://showEvent` link needs the
/// account's email address, which macOS Calendar doesn't expose for iCloud, subscribed or birthday calendars.
func openNotionCalendar() {
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.cron.electron") {
        NSWorkspace.shared.open(url)
    }
}

struct FooterView: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        HStack {
            Button("Open Notion Calendar", action: openNotionCalendar)
            Spacer()
            Menu {
                Button("Settings…") {
                    NSApp.activate()
                    openSettings()
                }
                Divider()
                Button("Quit Datograph") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "gearshape")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .buttonStyle(.borderless)
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
