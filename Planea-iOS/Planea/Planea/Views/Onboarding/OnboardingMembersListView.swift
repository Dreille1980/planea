import SwiftUI

struct OnboardingMembersListView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @Binding var progress: OnboardingProgress
    let onContinue: () -> Void
    let onConfigureMember: (Member) -> Void
    
    @State private var showingAddMember = false
    @State private var showingAddAnotherPrompt = false
    @State private var newMemberName = ""
    @State private var justAddedFirstMember = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.planeaTertiary.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.planeaTertiary)
                }
                .padding(.top, 32)
                
                Text("onboarding.members.title".localized)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("onboarding.members.subtitle".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(.bottom, 24)
            
            // Members List
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(familyVM.members, id: \.id) { member in
                        MemberCard(
                            member: member,
                            isConfigured: progress.isMemberConfigured(member.id),
                            onTap: {
                                onConfigureMember(member)
                            }
                        )
                    }
                    
                    // Add Member Button
                    Button(action: { showingAddMember = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("onboarding.members.add".localized)
                                .font(.headline)
                        }
                        .foregroundStyle(Color.planeaPrimary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.planeaPrimary, style: StrokeStyle(lineWidth: 2, dash: [5]))
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Continue Button
            if hasAtLeastOneConfiguredMember {
                Button(action: onContinue) {
                    Text("action.continue".localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.planeaTertiary)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .alert("onboarding.members.add".localized, isPresented: $showingAddMember) {
            TextField("member.name".localized, text: $newMemberName)
            Button("action.cancel".localized, role: .cancel) {
                newMemberName = ""
            }
            Button("action.add".localized) {
                addMember()
            }
        }
        .alert("onboarding.members.addanother.title".localized, isPresented: $showingAddAnotherPrompt) {
            Button("onboarding.members.addanother.yes".localized) {
                showingAddMember = true
            }
            Button("onboarding.members.addanother.later".localized, role: .cancel) {
                // Do nothing, user can add more later
            }
            Button("onboarding.members.addanother.no".localized) {
                // Skip to next step
                onContinue()
            }
        } message: {
            Text("onboarding.members.addanother.message".localized)
        }
    }
    
    private var hasAtLeastOneConfiguredMember: Bool {
        familyVM.members.contains { member in
            progress.isMemberConfigured(member.id)
        }
    }
    
    private func addMember() {
        guard !newMemberName.isEmpty else { return }
        
        let newMember = familyVM.addMember(name: newMemberName)
        newMemberName = ""
        
        // Check if this is the first member
        if familyVM.members.count == 1 {
            justAddedFirstMember = true
        }
        
        // Navigate to configure this new member
        onConfigureMember(newMember)
    }
    
    func checkForAddAnotherPrompt() {
        // Show prompt after first member is configured if there's only one member
        if justAddedFirstMember && familyVM.members.count == 1 && hasAtLeastOneConfiguredMember {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingAddAnotherPrompt = true
                justAddedFirstMember = false
            }
        }
    }
}

// MARK: - Member Card

struct MemberCard: View {
    let member: Member
    let isConfigured: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(isConfigured ? Color.planeaTertiary.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    if isConfigured {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.planeaTertiary)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.title3)
                            .foregroundStyle(.gray)
                    }
                }
                
                // Member Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(member.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if isConfigured {
                        HStack(spacing: 4) {
                            if !member.diets.isEmpty {
                                Label("\(member.diets.count)", systemImage: "leaf.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.planeaTertiary)
                            }
                            if !member.allergens.isEmpty {
                                Label("\(member.allergens.count)", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.planeaSecondary)
                            }
                            if !member.dislikes.isEmpty {
                                Label("\(member.dislikes.count)", systemImage: "hand.thumbsdown.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text("onboarding.member.configure".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    OnboardingMembersListView(
        progress: .constant(OnboardingProgress()),
        onContinue: { print("Continue") },
        onConfigureMember: { _ in print("Configure member") }
    )
    .environmentObject(FamilyViewModel())
}
