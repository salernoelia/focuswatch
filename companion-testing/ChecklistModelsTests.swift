import Foundation
import Testing

@testable import focuswatch_companion

@Suite("Checklist Models")
struct ChecklistModelsTests {
        @Test("ChecklistItem round-trips")
        func checklistItemRoundTrips() throws {
            let item = ChecklistItem(title: "Test Item", imageName: "img")
            let data = try JSONEncoder().encode(item)
            let decoded = try JSONDecoder().decode(ChecklistItem.self, from: data)
            #expect(decoded.title == item.title)
            #expect(decoded.imageName == item.imageName)
        }

        @Test("Checklist with all fields round-trips")
        func checklistWithAllFieldsRoundTrips() throws {
            let checklist = Checklist(
                name: "Test",
                emoji: "T",
                tag: "tag",
                description: "desc",
                items: [ChecklistItem(title: "A", imageName: "a")],
                xpReward: 75,
                resetConfiguration: ChecklistResetConfiguration(interval: .daily, hour: 8, minute: 30),
                swipeMapping: .collectLeftDelayRight
            )
            let data = try JSONEncoder().encode(checklist)
            let decoded = try JSONDecoder().decode(Checklist.self, from: data)
            #expect(decoded.name == checklist.name)
            #expect(decoded.emoji == checklist.emoji)
            #expect(decoded.tag == checklist.tag)
            #expect(decoded.xpReward == checklist.xpReward)
            #expect(decoded.items.count == 1)
            #expect(decoded.swipeMapping == checklist.swipeMapping)
        }

        @Test("Checklist decodes with missing optional fields using defaults")
        func checklistDecodesWithMissingOptionalFields() throws {
            let json = Data("{\"name\": \"Minimal\"}".utf8)
            let decoded = try JSONDecoder().decode(Checklist.self, from: json)
            #expect(decoded.name == "Minimal")
            #expect(decoded.emoji == "")
            #expect(decoded.tag == "")
            #expect(decoded.items.isEmpty)
            #expect(decoded.xpReward == 50)
            #expect(decoded.swipeMapping == .collectRightDelayLeft)
        }

        @Test("ChecklistResetConfiguration clamps hour to 0-23")
        func checklistResetConfigurationClampsHour() {
            let low = ChecklistResetConfiguration(hour: -1)
            #expect(low.hour == 0)
            let high = ChecklistResetConfiguration(hour: 25)
            #expect(high.hour == 23)
            let valid = ChecklistResetConfiguration(hour: 12)
            #expect(valid.hour == 12)
        }

        @Test("ChecklistResetConfiguration clamps minute to 0-59")
        func checklistResetConfigurationClampsMinute() {
            let low = ChecklistResetConfiguration(minute: -5)
            #expect(low.minute == 0)
            let high = ChecklistResetConfiguration(minute: 60)
            #expect(high.minute == 59)
        }

        @Test("ChecklistResetConfiguration clamps weekday to 1-7")
        func checklistResetConfigurationClampsWeekday() {
            let low = ChecklistResetConfiguration(weekday: 0)
            #expect(low.weekday == 1)
            let high = ChecklistResetConfiguration(weekday: 8)
            #expect(high.weekday == 7)
        }

        @Test("ChecklistData default contains one checklist")
        func checklistDataDefaultContainsOneChecklist() {
            #expect(ChecklistData.default.checklists.count == 1)
        }

        @Test("ChecklistData round-trips")
        func checklistDataRoundTrips() throws {
            let original = ChecklistData.default
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(ChecklistData.self, from: data)
            #expect(decoded.checklists.count == original.checklists.count)
            #expect(decoded.checklists.first?.name == original.checklists.first?.name)
        }
}
