import SwiftUI
import WidgetKit

private let widgetGroupId = "group.tinyminyapps.upsc.wars"

/// Matches Dart `PrelimsCountdown.prelimsDate`: 24 May 2026, 09:30 in the user's current calendar/time zone.
private func prelimsDate() -> Date {
  var calendar = Calendar.current
  calendar.timeZone = TimeZone.current
  return calendar.date(
    from: DateComponents(calendar: calendar, year: 2026, month: 5, day: 24, hour: 9, minute: 30)
  ) ?? .distantFuture
}

/// Matches Dart `PrelimsCountdown.daysLeft` for a positive remaining interval.
private func daysLeft(from now: Date) -> Int {
  let prelims = prelimsDate()
  let diff = prelims.timeIntervalSince(now)
  if diff <= 0 { return 0 }
  let fullDays = Int(floor(diff / 86400.0))
  let remainder = diff - Double(fullDays) * 86400.0
  let hasRemainder = remainder > 0.000001
  return hasRemainder ? fullDays + 1 : fullDays
}

private func nextLocalMidnight(after date: Date) -> Date {
  var calendar = Calendar.current
  calendar.timeZone = TimeZone.current
  let start = calendar.startOfDay(for: date)
  return calendar.date(byAdding: .day, value: 1, to: start) ?? date.addingTimeInterval(86400)
}

struct PrelimsCountdownEntry: TimelineEntry {
  let date: Date
  let daysText: String
  let quote: String
}

struct PrelimsCountdownProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrelimsCountdownEntry {
    PrelimsCountdownEntry(
      date: Date(),
      daysText: "0",
      quote: "The trouble is, you think you have time.\n- Buddha"
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (PrelimsCountdownEntry) -> Void) {
    completion(loadEntry(at: Date(), data: nil))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrelimsCountdownEntry>) -> Void) {
    let now = Date()
    let data = UserDefaults(suiteName: widgetGroupId)
    let debugMinute = (data?.string(forKey: "prelims_debug_minute_refresh") ?? "0") == "1"
    let entry = loadEntry(at: now, data: data)
    let refresh: Date
    if debugMinute {
      refresh = Calendar.current.date(byAdding: .minute, value: 1, to: now) ?? now.addingTimeInterval(60)
    } else {
      refresh = nextLocalMidnight(after: now)
    }
    completion(Timeline(entries: [entry], policy: .after(refresh)))
  }

  private func loadEntry(at date: Date, data: UserDefaults? = nil) -> PrelimsCountdownEntry {
    let data = data ?? UserDefaults(suiteName: widgetGroupId)
    let debugMinute = (data?.string(forKey: "prelims_debug_minute_refresh") ?? "0") == "1"
    let daysText: String
    if debugMinute, let label = data?.string(forKey: "prelims_timer_label"), !label.isEmpty {
      daysText = label
    } else {
      daysText = String(daysLeft(from: date))
    }
    let quote =
      data?.string(forKey: "prelims_quote")
      ?? "The trouble is, you think you have time.\n- Buddha"
    return PrelimsCountdownEntry(
      date: date,
      daysText: daysText,
      quote: quote
    )
  }
}

struct PrelimsCountdownWidgetView: View {
  let entry: PrelimsCountdownProvider.Entry

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("UPSC PRELIMS")
        .font(.caption)
        .fontWeight(.semibold)
      Text("Days")
        .font(.caption2)
        .foregroundStyle(.secondary)
      Text("Days: \(entry.daysText)")
        .font(.title3)
        .fontWeight(.bold)
      Text(entry.quote)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .containerBackground(.background, for: .widget)
  }
}

@main
struct PrelimsCountdownWidget: Widget {
  let kind: String = "PrelimsCountdownWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrelimsCountdownProvider()) { entry in
      PrelimsCountdownWidgetView(entry: entry)
    }
    .configurationDisplayName("UPSC Prelims Countdown")
    .description("Shows days remaining for UPSC Prelims.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
  }
}
