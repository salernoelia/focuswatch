import SwiftUI
import WidgetKit

struct VersionEntry: TimelineEntry {
  let date: Date
  let version: String
}

struct VersionComplicationProvider: AppIntentTimelineProvider {
  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
  }

  func placeholder(in context: Context) -> VersionEntry {
    VersionEntry(date: Date(), version: "1.0")
  }

  func snapshot(
    for configuration: VersionComplicationIntent, in context: Context
  ) async -> VersionEntry {
    VersionEntry(date: Date(), version: appVersion)
  }

  func timeline(
    for configuration: VersionComplicationIntent, in context: Context
  ) async -> Timeline<VersionEntry> {
    let entry = VersionEntry(date: Date(), version: appVersion)
    return Timeline(entries: [entry], policy: .never)
  }

  func recommendations() -> [AppIntentRecommendation<VersionComplicationIntent>] {
    [AppIntentRecommendation(intent: VersionComplicationIntent(), description: "App Version")]
  }
}

struct VersionComplicationView: View {
  var entry: VersionEntry

  var body: some View {
    ZStack {
      AccessoryWidgetBackground()
      VStack(spacing: 2) {
        Text("v")
          .font(.caption2)
          .fontWeight(.medium)
        Text(entry.version)
          .font(.caption)
          .fontWeight(.bold)
      }
      .foregroundStyle(.white)
    }
  }
}

struct VersionComplication: Widget {
  let kind: String = "VersionComplication"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: VersionComplicationIntent.self,
      provider: VersionComplicationProvider()
    ) { entry in
      VersionComplicationView(entry: entry)
    }
    .configurationDisplayName("App Version")
    .description("Displays the current app version")
    .supportedFamilies([
      .accessoryCircular,
      .accessoryCorner,
      .accessoryRectangular,
    ])
  }
}
