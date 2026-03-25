//
//  AppIntent.swift
//  widget
//
//  Created by Elia Salerno on 09.10.2025.
//

import AppIntents
import WidgetKit

struct ConfigurationAppIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource { "App Version" }
  static var description: IntentDescription { "Display FokusUhr app version" }
}
