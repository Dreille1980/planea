import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Binding var isPresented: Bool
    @State private var newMemberName: String = ""
    @State private var showingAddMember = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("onboarding.family".localized)) {
                    TextField("onboarding.familyName".localized, text: $familyVM.family.name)
                        .onChange(of: familyVM.family.name) { _ in
                            familyVM.saveData()
                        }
                }
                
                Section(header: Text("onboarding.members".localized)) {
                    ForEach(familyVM.members) { member in
                        NavigationLink(destination: MemberDetailView(member: member)) {
                            HStack {
                                Text(member.displayName)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    if !member.diets.isEmpty {
                                        Text("\(member.diets.count) \("count.diets".localized)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    if !member.allergens.isEmpty {
                                        Text("\(member.allergens.count) \("count.allergens".localized)")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                    if !member.dislikes.isEmpty {
                                        Text("\(member.dislikes.count) \("count.dislikes".localized)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    Button(action: { showingAddMember = true }) {
                        Label("family.addMember".localized, systemImage: "plus.circle.fill")
                    }
                }
                
                Section {
                    Text("onboarding.hint".localized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                // Free Trial Welcome Message
                Section {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .font(.title)
                                .foregroundStyle(.yellow)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("subscription.welcome".localized)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text("subscription.welcome.message".localized)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Legal Links
                Section {
                    HStack(spacing: 4) {
                        Spacer()
                        NavigationLink(destination: LegalDocumentView(documentType: .termsAndConditions)) {
                            Text("subscription.terms".localized)
                                .font(.caption)
                        }
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        NavigationLink(destination: LegalDocumentView(documentType: .privacyPolicy)) {
                            Text("subscription.privacy".localized)
                                .font(.caption)
                        }
                        Spacer()
                    }
                }
                
                Section {
                    Button(action: completeOnboarding) {
                        Text("onboarding.continue".localized)
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(familyVM.family.name.isEmpty || familyVM.members.isEmpty)
                }
            }
            .navigationTitle("onboarding.welcome".localized)
            .navigationBarTitleDisplayMode(.large)
            .interactiveDismissDisabled()
            .alert("family.addMember".localized, isPresented: $showingAddMember) {
                TextField("member.name".localized, text: $newMemberName)
                Button("action.cancel".localized, role: .cancel) {
                    newMemberName = ""
                }
                Button("action.add".localized) {
                    if !newMemberName.isEmpty {
                        familyVM.addMember(name: newMemberName)
                        newMemberName = ""
                    }
                }
            }
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        isPresented = false
    }
}
