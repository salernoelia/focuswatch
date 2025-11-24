import SwiftUI

struct SpeedometerView: View {
  @State private var moodValue: Double = 0.5
  @State private var configuration = WatchConnector.loadAppConfigurations().fokusMeter

  private let appLogger = AppLogger.shared

  var body: some View {
    GeometryReader { geometry in
      let size = min(geometry.size.width, geometry.size.height) * 1.75
      let center = CGPoint(
        x: geometry.size.width / 2, y: geometry.size.height * 0.4)

      VStack(spacing: 8) {
        Text("Wie fühlst du dich?")
          .font(.caption)
          .foregroundColor(.white)
          .multilineTextAlignment(.center)

        ZStack {
          SemicircleSegments()
            .frame(width: size, height: size / 2)
            .position(center)

          SpeedometerNeedleView(value: moodValue, radius: size * 0.4)
            .position(center)

          Circle()
            .fill(Color.white)
            .frame(width: 8, height: 8)
            .position(center)

          Text(moodLabel)
            .font(.title)
            .foregroundColor(.white)
            .position(x: center.x, y: center.y + 35)
        }
        .gesture(
          DragGesture()
            .onChanged { value in
              let dx = value.location.x - center.x
              let radius = size * 0.18

              if abs(dx) <= radius {
                moodValue = (dx + radius) / (2 * radius)
                moodValue = max(0, min(1, moodValue))

                if configuration.enableVibration {
                  WKInterfaceDevice.current().play(configuration.vibrationIntensity.hapticType)
                }
              }
            }
        )
        .focusable()
        .digitalCrownRotation(
          $moodValue, from: 0.0, through: 1.0, by: 0.01,
          sensitivity: .low,
          isHapticFeedbackEnabled: configuration.enableVibration)
      }
    }
    .onAppear {
      appLogger.logViewLifecycle(appName: "tachometer", event: "open")
      setupConfigurationObserver()
    }
    .onDisappear {
      appLogger.logViewLifecycle(appName: "tachometer", event: "close")
    }
  }

  private func setupConfigurationObserver() {
    NotificationCenter.default.addObserver(
      forName: .appConfigurationsUpdated,
      object: nil,
      queue: .main
    ) { [self] notification in
      guard let configurations = notification.object as? AppConfigurations else { return }
      configuration = configurations.fokusMeter

      #if DEBUG
        print("✅ FokusMeter: Applied configuration from iOS")
      #endif
    }
  }

  private var moodLabel: String {
    switch moodValue {
    case 0.0..<0.33: return "🚜"
    case 0.33..<0.66: return "🚙"
    default: return "🏎️"
    }
  }
}

struct SemicircleSegments: View {
  var body: some View {
    ZStack {
      SemicircleSegment(startAngle: 180, endAngle: 240)
        .fill(Color.orange)

      SemicircleSegment(startAngle: 240, endAngle: 300)
        .fill(Color.green)

      SemicircleSegment(startAngle: 300, endAngle: 360)
        .fill(Color.orange)
    }
  }
}

struct SemicircleSegment: Shape {
  let startAngle: Double
  let endAngle: Double

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let radius = min(rect.width, rect.height) / 2

    path.move(to: center)
    path.addArc(
      center: center,
      radius: radius,
      startAngle: .degrees(startAngle),
      endAngle: .degrees(endAngle),
      clockwise: false
    )
    path.closeSubpath()

    return path
  }
}

struct Triangle: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.closeSubpath()
    return path
  }
}

#Preview {
  SpeedometerView()
}
