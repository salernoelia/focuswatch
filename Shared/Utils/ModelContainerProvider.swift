import Foundation
import SwiftData

class ModelContainerProvider {
  static let shared = ModelContainerProvider()

  let container: ModelContainer

  private init() {
    let schema = Schema([
      Event.self,
      LevelProgress.self,
      ActivityStats.self,
      LevelReward.self,
    ])

    let configuration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false
    )

    container =
      (try? ModelContainer(for: schema, configurations: [configuration]))
      ?? {
        fatalError("Failed to create ModelContainer")
      }()
  }
}
