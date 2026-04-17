import SwiftUI
import WidgetKit

private let widgetGroupId = "group.practice.upsc.indiaapps.com.upscmcqpractice.upscWars"

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
    completion(loadEntry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrelimsCountdownEntry>) -> Void) {
    let entry = loadEntry()
    let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }

  private func loadEntry() -> PrelimsCountdownEntry {
    let data = UserDefaults(suiteName: widgetGroupId)
    return PrelimsCountdownEntry(
      date: Date(),
      daysText: data?.string(forKey: "prelims_timer_label") ?? "0",
      quote: data?.string(forKey: "prelims_quote") ?? "The trouble is, you think you have time.\n- Buddha"
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
