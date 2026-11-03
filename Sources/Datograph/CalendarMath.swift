import Foundation

/// UserDefaults keys. List values are stored comma-separated.
enum Pref {
    static let menuBarPattern = "menuBarPattern"
    static let menuBarIcon = "menuBarIcon"
    static let showNextEvent = "showNextEvent"
    static let highlightWeekends = "highlightWeekends"
    /// 0 = system default, 1 = Sunday … 7 = Saturday.
    static let firstWeekday = "firstWeekday"
    static let showWeekNumbers = "showWeekNumbers"
    static let upcomingDays = "upcomingDays"
    static let hiddenCalendarIDs = "hiddenCalendarIDs"
    static let worldClocks = "worldClocks"
}

extension String {
    /// The items of a comma-separated preference value.
    var listItems: [String] { split(separator: ",").map(String.init) }
}

enum CalendarMath {
    static func calendar(firstWeekday: Int) -> Calendar {
        var calendar = Calendar.autoupdatingCurrent
        if (1...7).contains(firstWeekday) { calendar.firstWeekday = firstWeekday }
        return calendar
    }

    /// The 42 days (6 weeks) shown for the month containing `date`, starting on the calendar's first weekday.
    static func monthGrid(for date: Date, calendar: Calendar) -> [Date] {
        guard let monthStart = calendar.dateInterval(of: .month, for: date)?.start else { return [] }
        let leadingDays = (calendar.component(.weekday, from: monthStart) - calendar.firstWeekday + 7) % 7
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0 - leadingDays, to: monthStart) }
    }

    /// Single-letter weekday symbols, ordered from the calendar's first weekday.
    static func weekdaySymbols(calendar: Calendar) -> [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// Parses typed dates such as "24 Dec", "next friday" or "2027-01-05".
    static func parseDate(_ text: String) -> Date? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        return detector?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))?.date
    }

    /// The whole days between two dates, with a breakdown when it's longer than a month: "51 days (1 month, 20 days)".
    static func differenceText(from start: Date, to end: Date, calendar: Calendar) -> String {
        let earlier = calendar.startOfDay(for: min(start, end))
        let later = calendar.startOfDay(for: max(start, end))
        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day]
        let days = formatter.string(from: calendar.dateComponents([.day], from: earlier, to: later)) ?? ""
        formatter.allowedUnits = [.year, .month, .day]
        let breakdown = formatter.string(from: calendar.dateComponents([.year, .month, .day], from: earlier, to: later)) ?? ""
        return breakdown == days ? days : "\(days) (\(breakdown))"
    }
}

enum NextEvent {
    /// How far ahead the menu bar looks for the next event.
    static let horizon: TimeInterval = 12 * 3600

    /// "Standup in 12 min", "Standup in 1 h 40 min", "Standup · now"
    static func text(title: String, start: Date, now: Date) -> String {
        let name = title.count > 24 ? String(title.prefix(23)) + "…" : title
        let minutes = Int((start.timeIntervalSince(now) / 60).rounded(.up))
        if minutes <= 0 { return "\(name) · now" }
        if minutes < 60 { return "\(name) in \(minutes) min" }
        let hours = minutes / 60
        let rest = minutes % 60
        return rest == 0 ? "\(name) in \(hours) h" : "\(name) in \(hours) h \(rest) min"
    }
}

enum WorldClock {
    /// "America/Argentina/Buenos_Aires" → "Buenos Aires"
    static func cityName(for identifier: String) -> String {
        (identifier.split(separator: "/").last.map(String.init) ?? identifier)
            .replacingOccurrences(of: "_", with: " ")
    }

    /// 32400 → "+9h", -19800 → "−5h 30m"
    static func offsetText(seconds: Int) -> String {
        let sign = seconds < 0 ? "−" : "+"
        let hours = abs(seconds) / 3600
        let minutes = abs(seconds) % 3600 / 60
        return minutes == 0 ? "\(sign)\(hours)h" : "\(sign)\(hours)h \(minutes)m"
    }

    /// 1 if it's already the next day in `zone`, -1 if it's still the previous day, otherwise 0.
    static func dayDifference(at date: Date, in zone: TimeZone, relativeTo local: TimeZone) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        func ymd(_ timeZone: TimeZone) -> [Int] {
            calendar.timeZone = timeZone
            let c = calendar.dateComponents([.year, .month, .day], from: date)
            return [c.year ?? 0, c.month ?? 0, c.day ?? 0]
        }
        let there = ymd(zone)
        let here = ymd(local)
        if there == here { return 0 }
        return here.lexicographicallyPrecedes(there) ? 1 : -1
    }
}

enum MenuBarFormat {
    /// Presets are skeleton templates, so each one turns into the right pattern for the user's locale.
    /// Date and time are localized separately and joined, because a combined skeleton gives
    /// "Tue, 3 Nov at 18:15", which is too wordy for the menu bar.
    static let presets: [(name: String, templates: [String])] = [
        ("Time", ["jmm"]),
        ("Time with seconds", ["jmmss"]),
        ("Weekday and time", ["EEEjmm"]),
        ("Date and time", ["EEEMMMd", "jmm"]),
        ("Date", ["EEEMMMd"]),
    ]

    static func pattern(fromTemplates templates: [String]) -> String {
        templates
            .map { DateFormatter.dateFormat(fromTemplate: $0, options: 0, locale: .autoupdatingCurrent) ?? $0 }
            .joined(separator: "  ")
    }

    static var defaultPattern: String { pattern(fromTemplates: ["EEEMMMd", "jmm"]) }

    @MainActor private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        return formatter
    }()

    @MainActor static func string(from date: Date, pattern: String) -> String {
        if formatter.dateFormat != pattern { formatter.dateFormat = pattern }
        return formatter.string(from: date)
    }
}
