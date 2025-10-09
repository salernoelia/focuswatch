import SwiftUI
import SwiftUICore

// TODO: Factor out
struct AppInfo {
  let title: String
  let description: String
  let color: Color
}

struct AppCardView: View {
  let app: AppInfo

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(app.title)
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.white)

      Text(app.description)
        .font(.caption)
        .foregroundColor(.white.opacity(0.8))
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(app.color)
    )
  }
}
