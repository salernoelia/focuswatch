import Foundation
import Testing

@testable import focuswatch_companion

@Suite("AppConfigurations Codable")
struct AppConfigurationsTests {
        @Test("Default AppConfigurations round-trips")
        func defaultAppConfigurationsRoundTrips() throws {
            let config = AppConfigurations.default
            let data = try JSONEncoder().encode(config)
            let decoded = try JSONDecoder().decode(AppConfigurations.self, from: data)
            #expect(decoded == config)
        }

        @Test("PomodoroConfiguration round-trips with non-default values")
        func pomodoroConfigurationRoundTrips() throws {
            var config = PomodoroConfiguration()
            config.workMinutes = 45
            config.shortBreakMinutes = 10
            config.roundsUntilLongBreak = 6
            let data = try JSONEncoder().encode(config)
            let decoded = try JSONDecoder().decode(PomodoroConfiguration.self, from: data)
            #expect(decoded == config)
        }

        @Test("ColorBreathingConfiguration round-trips with non-default values")
        func colorBreathingConfigurationRoundTrips() throws {
            var config = ColorBreathingConfiguration()
            config.inhaleSeconds = 6
            config.exhaleSeconds = 8
            config.cycleCount = 10
            let data = try JSONEncoder().encode(config)
            let decoded = try JSONDecoder().decode(ColorBreathingConfiguration.self, from: data)
            #expect(decoded == config)
        }

        @Test("FokusMeterConfiguration round-trips")
        func fokusMeterConfigurationRoundTrips() throws {
            let config = FokusMeterConfiguration()
            let data = try JSONEncoder().encode(config)
            let decoded = try JSONDecoder().decode(FokusMeterConfiguration.self, from: data)
            #expect(decoded == config)
        }

        @Test("Partial JSON decodes with defaults for missing keys")
        func partialJSONDecodesWithDefaults() throws {
            let json = Data("{}".utf8)
            let decoded = try JSONDecoder().decode(AppConfigurations.self, from: json)
            let def = AppConfigurations.default
            #expect(decoded == def)
        }

        @Test("ColorBreathing partial JSON uses defaults for missing keys")
        func colorBreathingPartialJSONUsesDefaults() throws {
            let json = Data("{\"inhaleSeconds\": 8}".utf8)
            let decoded = try JSONDecoder().decode(ColorBreathingConfiguration.self, from: json)
            #expect(decoded.inhaleSeconds == 8)
            #expect(decoded.exhaleSeconds == 4)
            #expect(decoded.cycleCount == 5)
        }

        @Test("ChecklistSwipeDirectionMapping collect and delay directions are inverse")
        func checklistSwipeMappingCollectAndDelayAreInverse() {
            for mapping in ChecklistSwipeDirectionMapping.allCases {
                #expect(mapping.collectDirection != mapping.delayDirection)
            }
        }

        @Test("ChecklistSwipeDirectionMapping round-trips")
        func checklistSwipeMappingRoundTrips() throws {
            for mapping in ChecklistSwipeDirectionMapping.allCases {
                let data = try JSONEncoder().encode(mapping)
                let decoded = try JSONDecoder().decode(ChecklistSwipeDirectionMapping.self, from: data)
                #expect(decoded == mapping)
            }
        }
}
