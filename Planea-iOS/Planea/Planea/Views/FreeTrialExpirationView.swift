import SwiftUI

struct FreeTrialExpirationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showSubscriptionView = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Title
                Text("freetrial.expired.title".localized)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Message
                Text("freetrial.expired.message".localized)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showSubscriptionView = true
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("freetrial.expired.subscribe".localized)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("freetrial.expired.continue".localized)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundStyle(.primary)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionPaywallView(limitReached: false)
            }
        }
    }
}

#Preview {
    FreeTrialExpirationView()
}
