import SwiftUI



struct AppCard: View {
    let app: PrototypeApp
    
    var body: some View {
        if #available(watchOS 9.0, *) {
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
        
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            // Fallback on earlier versions
        }
    }
}
