import SwiftUI

struct AppCardView: View {
  let app: AppInfo

  var body: some View {
    HStack(spacing: 12) {


      VStack(alignment: .leading, spacing: 2) {
        Text(app.title)
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(.white)
          .lineLimit(1)

        Text(app.description)
          .font(.system(size: 12))
          .foregroundColor(.white.opacity(0.7))
          .lineLimit(2)
      }

      Spacer(minLength: 0)

      Image(systemName: "chevron.right")
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(.white.opacity(0.5))
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.white.opacity(0.1))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(app.color.opacity(0.3), lineWidth: 1)
    )
  }
}
