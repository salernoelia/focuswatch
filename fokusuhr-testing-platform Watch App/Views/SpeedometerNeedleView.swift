import SwiftUI

struct SpeedometerNeedleView: View {
    let value: Double
    let radius: CGFloat

    var needleAngle: Double {
        return 270 + (value * 180)
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: 3, height: radius * 0.6)
                .offset(y: -radius * 0.3)
                .rotationEffect(.degrees(needleAngle))

            Triangle()
                .fill(Color.white)
                .frame(width: 12, height: 8)
                .offset(y: -radius * 0.55)
                .rotationEffect(.degrees(needleAngle))
        }
    }
}
