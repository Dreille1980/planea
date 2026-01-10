import SwiftUI

struct MealPrepComingSoonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 40)
                
                // Icon
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 72))
                    .foregroundColor(.accentColor)
                    .padding(.bottom, 8)
                
                // Title
                Text("mealprep.comingsoon.title".localized)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Subtitle/Description
                Text("mealprep.comingsoon.subtitle".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    MealPrepComingSoonView()
}
