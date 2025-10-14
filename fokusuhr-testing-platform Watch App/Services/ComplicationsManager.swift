import ClockKit
import SwiftUI

class ComplicationsManager: NSObject, CLKComplicationDataSource {
  static let shared = ComplicationsManager()

  private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
  }

  func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
    let descriptors = [
      CLKComplicationDescriptor(
        identifier: "version",
        displayName: "App Version",
        supportedFamilies: [.graphicCircular, .graphicCorner, .graphicRectangular]
      )
    ]
    handler(descriptors)
  }

  func getCurrentTimelineEntry(
    for complication: CLKComplication,
    withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void
  ) {
    guard let template = makeTemplate(for: complication.family) else {
      handler(nil)
      return
    }
    let entry = CLKComplicationTimelineEntry(date: Date(), complicationTemplate: template)
    handler(entry)
  }

  func getLocalizableSampleTemplate(
    for complication: CLKComplication,
    withHandler handler: @escaping (CLKComplicationTemplate?) -> Void
  ) {
    handler(makeTemplate(for: complication.family))
  }

  private func makeTemplate(for family: CLKComplicationFamily) -> CLKComplicationTemplate? {
    switch family {
    case .graphicCircular:
      return CLKComplicationTemplateGraphicCircularStackText(
        line1TextProvider: CLKSimpleTextProvider(text: "FokusUhr"),
        line2TextProvider: CLKSimpleTextProvider(text: appVersion)
      )
    case .graphicCorner:
      return CLKComplicationTemplateGraphicCornerTextImage(
        textProvider: CLKSimpleTextProvider(text: "FokusUhr\(appVersion)"),
        imageProvider: CLKFullColorImageProvider(
          fullColorImage: UIImage(systemName: "app.badge") ?? UIImage())
      )
    case .graphicRectangular:
      return CLKComplicationTemplateGraphicRectangularStandardBody(
        headerTextProvider: CLKSimpleTextProvider(text: "fokusuhr"),
        body1TextProvider: CLKSimpleTextProvider(text: "Version \(appVersion)")
      )
    default:
      return nil
    }
  }
}
