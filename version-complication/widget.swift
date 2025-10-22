//
//  widget.swift
//  widget
//
//  Created by Elia Salerno on 09.10.2025.
//

import SwiftUI
import WidgetKit

struct Provider: AppIntentTimelineProvider {
  private var appVersion: String {
    var bundle = Bundle.main

    if bundle.bundleURL.pathExtension == "appex" {
      let url = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
      if let appBundle = Bundle(url: url) {
        bundle = appBundle
      }
    }

    return bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
  }

  private var deviceId: String {
    let sharedDefaults = UserDefaults(suiteName: "group.fokus.w")
    let uuid = sharedDefaults?.string(forKey: "deviceUUID")
    #if DEBUG
    print("📱 Widget reading deviceUUID: \(uuid ?? "nil")")
    #endif
    return uuid?.prefix(6).uppercased() ?? "NO ID"
  }

  func placeholder(in context: Context) -> SimpleEntry {
    SimpleEntry(date: Date(), version: appVersion, deviceId: deviceId)
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry
  {
    SimpleEntry(date: Date(), version: appVersion, deviceId: deviceId)
  }

  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<
    SimpleEntry
  > {
    let entry = SimpleEntry(date: Date(), version: appVersion, deviceId: deviceId)
    return Timeline(entries: [entry], policy: .never)
  }

  func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
    [AppIntentRecommendation(intent: ConfigurationAppIntent(), description: "App Version")]
  }
}

struct SimpleEntry: TimelineEntry {
  let date: Date
  let version: String
  let deviceId: String
}

struct widgetEntryView: View {
  var entry: Provider.Entry

  var body: some View {
    VStack(spacing: 2) {
      Text("\(entry.version) - \(entry.deviceId)")
        .font(.title3)
        .fontWeight(.bold)
    }
  }
}

@main
struct widget: Widget {
  let kind: String = "widget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) {
      entry in
      widgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
  }
}

#Preview(as: .accessoryRectangular) {
  widget()
} timeline: {
  SimpleEntry(date: .now, version: "1.0", deviceId: "ABCDEF")
  SimpleEntry(date: .now, version: "2.5", deviceId: "GHIJKL")
}
