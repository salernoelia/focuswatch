import SwiftUI

struct CalendarEventRowView: View {
    let event: Event
    
    private var typeColor: Color {
        switch event.type {
        case .homework:
            return .orange
        case .sports:
            return .green
        case .music:
            return .purple
        case .other:
            return .blue
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(typeColor)
                .frame(width: 4, height: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(event.type.rawValue.capitalized)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(typeColor.opacity(0.15))
                        .foregroundColor(typeColor)
                        .cornerRadius(8)
                    
                    if event.repeatRule != .none {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(timeString(event.startTime)) – \(timeString(event.endTime))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if event.repeatRule != .none {
                    Text(event.repeatRule.rawValue.capitalized)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func timeString(_ date: Date) -> String {
        let df = DateFormatter()
        df.timeStyle = .short
        return df.string(from: date)
    }
}
