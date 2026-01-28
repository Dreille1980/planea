import SwiftUI

struct OnboardingCompletionView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @Binding var progress: OnboardingProgress
    let onComplete: () -> Void
    
    @State private var showCheckmark = false
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success Animation
            ZStack {
                Circle()
                    .fill(.planeaTertiary.opacity(0.1))
                    .frame(width: 150, height: 150)
                    .scaleEffect(showCheckmark ? 1.2 : 0.8)
                    .opacity(showCheckmark ? 1.0 : 0.0)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.planeaTertiary)
                    .scaleEffect(showCheckmark ? 1.0 : 0.3)
                    .opacity(showCheckmark ? 1.0 : 0.0)
            }
            
            // Title
            VStack(spacing: 12) {
                Text("onboarding.completion.title".localized)
                    .font(.title)
                    .fontWeight(.bold)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 20)
                
                Text("onboarding.completion.subtitle".localized)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0.0)
                    .offset(y: showContent ? 0 : 20)
            }
            .padding(.horizontal, 32)
            
            // Summary
            VStack(spacing: 16) {
                SummaryRow(
                    icon: "house.fill",
                    title: "onboarding.completion.family".localized,
                    value: progress.familyName
                )
                
                SummaryRow(
                    icon: "person.3.fill",
                    title: "onboarding.completion.members".localized,
                    value: "\(familyVM.members.count) \(familyVM.members.count == 1 ? "onboarding.completion.member".localized : "onboarding.completion.members.plural".localized)"
                )
                
                SummaryRow(
                    icon: "checkmark.circle.fill",
                    title: "onboarding.completion.configured".localized,
                    value: "\(progress.configuredMemberIds.count)/\(familyVM.members.count)"
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
            .padding(.horizontal, 32)
            .opacity(showContent ? 1.0 : 0.0)
            .offset(y: showContent ? 0 : 30)
            
            Spacer()
            
            // Start Button
            Button(action: completeOnboarding) {
                Text("onboarding.completion.start".localized)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.planeaTertiary, .planeaPrimary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
            .opacity(showContent ? 1.0 : 0.0)
            .scaleEffect(showContent ? 1.0 : 0.9)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showCheckmark = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    showContent = true
                }
            }
        }
    }
    
    private func completeOnboarding() {
        progress.isComplete = true
        progress.save()
        onComplete()
    }
}

// MARK: - Summary Row

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.planeaPrimary)
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    OnboardingCompletionView(
        progress: .constant(OnboardingProgress(
            hasSeenTour: true,
            hasCompletedFamilyName: true,
            familyName: "Famille Tremblay",
            configuredMemberIds: [UUID()],
            hasCompletedPreferences: true,
            currentStepIndex: 4,
            isComplete: false
        )),
        onComplete: { print("Complete") }
    )
    .environmentObject(FamilyViewModel())
}
