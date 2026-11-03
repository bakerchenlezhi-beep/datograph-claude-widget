import EventKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem { Label("General", systemImage: "gearshape") }
            CalendarSettings()
                .tabItem { Label("Calendar", systemImage: "calendar") }
            WorldClockSettings()
                .tabItem { Label("World Clocks", systemImage: "globe") }
        }
        .frame(width: 460, height: 400)
    }
}

// MARK: - General

struct GeneralSettings: View {
    @Environment(Clock.self) private var clock
    @AppStorage(Pref.menuBarPattern) private var pattern = MenuBarFormat.defaultPattern
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section {
                Picker("Style", selection: presetBinding) {
                    ForEach(MenuBarFormat.presets, id: \.name) { preset in
                        Text(preset.name).tag(preset.name)
                    }
                    Divider()
                    Text("Custom").tag("")
                }
                TextField("Format", text: $pattern)
                LabeledContent("Preview") {
                    if pattern.trimmingCharacters(in: .whitespaces).isEmpty {
                        Image(systemName: "calendar")
                    } else {
                        Text(MenuBarFormat.string(from: clock.now, pattern: pattern))
                    }
                }
            } header: {
                Text("Menu Bar")
            } footer: {
                Link("Date format symbols", destination: URL(string: "https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table")!)
                    .font(.caption)
            }

            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { enabled in
                        try? enabled ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                ))
            }
        }
        .formStyle(.grouped)
    }

    /// The name of the preset matching the current pattern, or "" (Custom) if none does.
    private var presetBinding: Binding<String> {
        Binding(
            get: { MenuBarFormat.presets.first { MenuBarFormat.pattern(fromTemplates: $0.templates) == pattern }?.name ?? "" },
            set: { name in
                if let preset = MenuBarFormat.presets.first(where: { $0.name == name }) {
                    pattern = MenuBarFormat.pattern(fromTemplates: preset.templates)
                }
            }
        )
    }
}

// MARK: - Calendar

struct CalendarSettings: View {
    @Environment(CalendarStore.self) private var store
    @AppStorage(Pref.firstWeekday) private var firstWeekday = 0
    @AppStorage(Pref.showWeekNumbers) private var showWeekNumbers = false
    @AppStorage(Pref.upcomingDays) private var upcomingDays = 7
    @AppStorage(Pref.hiddenCalendarIDs) private var hiddenCalendarIDs = ""

    var body: some View {
        Form {
            Section {
                Picker("First day of week", selection: $firstWeekday) {
                    Text("System Default").tag(0)
                    Divider()
                    ForEach(1...7, id: \.self) { weekday in
                        Text(Calendar.autoupdatingCurrent.weekdaySymbols[weekday - 1]).tag(weekday)
                    }
                }
                Toggle("Show week numbers", isOn: $showWeekNumbers)
                Picker("Show events for", selection: $upcomingDays) {
                    ForEach([1, 3, 7, 14], id: \.self) { days in
                        Text(days == 1 ? "1 day" : "\(days) days").tag(days)
                    }
                }
            }

            if store.hasAccess {
                let sources = Dictionary(grouping: store.calendars) { $0.source.title }
                ForEach(sources.keys.sorted(), id: \.self) { source in
                    Section(source) {
                        ForEach(sources[source]!.sorted { $0.title < $1.title }, id: \.calendarIdentifier) { calendar in
                            Toggle(isOn: isVisible(calendar)) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color(cgColor: calendar.cgColor))
                                        .frame(width: 9, height: 9)
                                    Text(calendar.title)
                                }
                            }
                        }
                    }
                }
            } else {
                Section("Calendars") {
                    CalendarAccessPrompt()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func isVisible(_ calendar: EKCalendar) -> Binding<Bool> {
        Binding(
            get: { !hiddenCalendarIDs.listItems.contains(calendar.calendarIdentifier) },
            set: { visible in
                var hidden = hiddenCalendarIDs.listItems.filter { $0 != calendar.calendarIdentifier }
                if !visible { hidden.append(calendar.calendarIdentifier) }
                hiddenCalendarIDs = hidden.joined(separator: ",")
            }
        )
    }
}

// MARK: - World clocks

struct WorldClockSettings: View {
    @AppStorage(Pref.worldClocks) private var worldClocks = ""
    @State private var isAdding = false

    private var zones: [String] {
        get { worldClocks.listItems }
        nonmutating set { worldClocks = newValue.joined(separator: ",") }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            List {
                ForEach(zones, id: \.self) { identifier in
                    HStack {
                        Text(WorldClock.cityName(for: identifier))
                        Text(identifier).foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            zones.removeAll { $0 == identifier }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                        .help("Remove")
                    }
                }
                .onMove { zones.move(fromOffsets: $0, toOffset: $1) }
            }
            .overlay {
                if zones.isEmpty {
                    Text("No world clocks").foregroundStyle(.secondary)
                }
            }

            Button("Add Time Zone…") { isAdding = true }
                .popover(isPresented: $isAdding, arrowEdge: .bottom) {
                    TimeZonePicker(excluding: zones) { identifier in
                        zones.append(identifier)
                        isAdding = false
                    }
                }
        }
        .padding(20)
    }
}

struct TimeZonePicker: View {
    let excluding: [String]
    let onPick: (String) -> Void
    @State private var query = ""

    var body: some View {
        let matches = TimeZone.knownTimeZoneIdentifiers.filter { identifier in
            !excluding.contains(identifier) && (query.isEmpty
                || identifier.localizedStandardContains(query)
                || WorldClock.cityName(for: identifier).localizedStandardContains(query))
        }

        VStack(spacing: 0) {
            TextField("Search cities", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(8)
            List(matches, id: \.self) { identifier in
                Button {
                    onPick(identifier)
                } label: {
                    HStack {
                        Text(WorldClock.cityName(for: identifier))
                        Spacer()
                        Text(identifier).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 320, height: 300)
    }
}
