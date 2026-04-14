import SwiftUI

struct AppCardView: View {
    let app: AppInfo

    var body: some View {
        HStack(spacing: 10) {
            if !app.symbol.isEmpty {
                Image(systemName: app.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(app.color)
                    .frame(width: 26, height: 26)
            } else if !app.emoji.isEmpty {
                Text(app.emoji)
                    .font(.system(size: 20))
                    .frame(width: 26, height: 26)
            } else {
                RoundedRectangle(cornerRadius: 3)
                    .fill(app.color)
                    .frame(width: 4, height: 30)
            }

            Text(app.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(app.color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
