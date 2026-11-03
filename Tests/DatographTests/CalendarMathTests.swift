import Foundation
import Testing
@testable import Datograph

private let utc = TimeZone(identifier: "UTC")!

private func calendar(firstWeekday: Int) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = utc
    calendar.locale = Locale(identifier: "en_US")
    calendar.firstWeekday = firstWeekday
    return calendar
}

private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
    calendar(firstWeekday: 1).date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
}

@Test func monthGridStartsOnFirstWeekday() {
    // November 1, 2026 is a Sunday.
    let sundayFirst = CalendarMath.monthGrid(for: date(2026, 11, 17), calendar: calendar(firstWeekday: 1))
    #expect(sundayFirst.count == 42)
    #expect(sundayFirst.first == date(2026, 11, 1))
    #expect(sundayFirst.last == date(2026, 12, 12))

    let mondayFirst = CalendarMath.monthGrid(for: date(2026, 11, 17), calendar: calendar(firstWeekday: 2))
    #expect(mondayFirst.first == date(2026, 10, 26))
    #expect(mondayFirst.last == date(2026, 12, 6))
}

@Test func weekdaySymbolsFollowFirstWeekday() {
    #expect(CalendarMath.weekdaySymbols(calendar: calendar(firstWeekday: 1)) == ["S", "M", "T", "W", "T", "F", "S"])
    #expect(CalendarMath.weekdaySymbols(calendar: calendar(firstWeekday: 2)) == ["M", "T", "W", "T", "F", "S", "S"])
}

@Test func offsetText() {
    #expect(WorldClock.offsetText(seconds: 0) == "+0h")
    #expect(WorldClock.offsetText(seconds: 9 * 3600) == "+9h")
    #expect(WorldClock.offsetText(seconds: -(5 * 3600 + 1800)) == "−5h 30m")
}

@Test func dayDifference() {
    let noon = date(2026, 11, 3, hour: 12)
    let kiritimati = TimeZone(identifier: "Pacific/Kiritimati")! // UTC+14
    let pagoPago = TimeZone(identifier: "Pacific/Pago_Pago")! // UTC−11
    #expect(WorldClock.dayDifference(at: noon, in: kiritimati, relativeTo: utc) == 1)
    #expect(WorldClock.dayDifference(at: noon, in: TimeZone(identifier: "America/Los_Angeles")!, relativeTo: utc) == 0)
    #expect(WorldClock.dayDifference(at: noon, in: pagoPago, relativeTo: kiritimati) == -1)
}

@Test func cityName() {
    #expect(WorldClock.cityName(for: "America/Argentina/Buenos_Aires") == "Buenos Aires")
    #expect(WorldClock.cityName(for: "UTC") == "UTC")
}
