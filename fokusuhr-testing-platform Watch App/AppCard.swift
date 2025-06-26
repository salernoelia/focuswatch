import SwiftUI



struct AppCard: View {
    let app: PrototypeApp
    
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
        .background(app.color.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
