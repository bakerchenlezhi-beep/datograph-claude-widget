import SwiftUI

enum MenuBarIcon: String, CaseIterable {
    case none, calendarDate, borderedDate, clock

    var name: String {
        switch self {
        case .none: "None"
        case .calendarDate: "Date in calendar"
        case .borderedDate: "Date with border"
        case .clock: "Clock"
        }
    }
}

struct MenuBarLabel: View {
    let clock: Clock
    let pattern: String
    let icon: MenuBarIcon

    var body: some View {
        let text = pattern.trimmingCharacters(in: .whitespaces).isEmpty
            ? ""
            : MenuBarFormat.string(from: clock.now, pattern: pattern)
        // With neither text nor icon the item would be invisible, so fall back to the calendar icon.
        let shownIcon = text.isEmpty && icon == .none ? .calendarDate : icon

        if shownIcon == .none {
            Text(text)
        } else {
            Image(nsImage: Self.render(icon: shownIcon, day: clock.today.formatted(.dateTime.day()), text: text))
                .renderingMode(.template)
                .accessibilityLabel(text.isEmpty ? clock.today.formatted(date: .complete, time: .omitted) : text)
        }
    }

    /// Draws the icon and text into one template image, so they sit together and take on the menu bar's color.
    private static func render(icon: MenuBarIcon, day: String, text: String) -> NSImage {
        let renderer = ImageRenderer(content: HStack(spacing: 5) {
            MenuBarIconView(icon: icon, day: day)
            if !text.isEmpty {
                Text(text).font(.system(size: NSFont.menuBarFont(ofSize: 0).pointSize))
            }
        }
        .foregroundStyle(.black))
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let image = renderer.nsImage ?? NSImage()
        image.isTemplate = true
        return image
    }
}

struct MenuBarIconView: View {
    let icon: MenuBarIcon
    let day: String

    var body: some View {
        switch icon {
        case .none:
            EmptyView()
        case .calendarDate:
            VStack(spacing: 0) {
                Rectangle().frame(height: 4)
                Text(day)
                    .font(.system(size: 9.5, weight: .bold))
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 18, height: 16)
            .clipShape(RoundedRectangle(cornerRadius: 3.5))
            .overlay(RoundedRectangle(cornerRadius: 3.5).strokeBorder(lineWidth: 1.2))
        case .borderedDate:
            Text(day)
                .font(.system(size: 10, weight: .semibold))
                .frame(minWidth: 18, minHeight: 16)
                .overlay(RoundedRectangle(cornerRadius: 3.5).strokeBorder(lineWidth: 1.2))
        case .clock:
            Image(systemName: "clock")
                .font(.system(size: 14))
        }
    }
}
