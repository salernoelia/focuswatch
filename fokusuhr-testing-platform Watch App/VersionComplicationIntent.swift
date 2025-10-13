import AppIntents
import WidgetKit

struct VersionComplicationIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "App Version" }
  static var description: IntentDescription { "Display FokusUhr app version" }
}
