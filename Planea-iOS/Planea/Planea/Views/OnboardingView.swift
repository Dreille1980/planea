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
                        .onChange(of: familyVM.family.name) {
                            familyVM.saveData()
                        }
                }
                
                Section(header: Text("onboarding.members".localized), footer: Text("onboarding.members.description".localized)) {
                    ForEach(familyVM.members) { member in
                        NavigationLink(destination: MemberDetailView(member: member)) {
                            HStack {
                                Text(member.displayName)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    if !member.diets.isEmpty {
                                        Text("\(member.diets.count) \("count.diets".localized)")
                                            .font(.planeaCaption2)
                                            .foregroundColor(.planeaTextSecondary)
                                    }
                                    if !member.allergens.isEmpty {
                                        Text("\(member.allergens.count) \("count.allergens".localized)")
                                            .font(.planeaCaption2)
                                            .foregroundStyle(.orange)
                                    }
                                    if !member.dislikes.isEmpty {
                                        Text("\(member.dislikes.count) \("count.dislikes".localized)")
                                            .font(.planeaCaption2)
                                            .foregroundColor(.planeaTextSecondary)
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
                        .font(.planeaFootnote)
                        .foregroundColor(.planeaTextSecondary)
                }
                
                // Free Trial Welcome Message
                Section {
                    VStack(spacing: PlaneaSpacing.sm) {
                        HStack {
                            Image(systemName: "star.circle.fill")
                                .font(.planeaTitle1)
                                .foregroundStyle(.yellow)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("subscription.welcome".localized)
                                    .font(.planeaHeadline)
                                    .foregroundColor(.planeaTextPrimary)
                                
                                Text("subscription.welcome.message".localized)
                                    .font(.planeaSubheadline)
                                    .foregroundColor(.planeaTextSecondary)
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
                                .font(.planeaCaption)
                        }
                        Text("•")
                            .font(.planeaCaption)
                            .foregroundColor(.planeaTextSecondary)
                        NavigationLink(destination: LegalDocumentView(documentType: .privacyPolicy)) {
                            Text("subscription.privacy".localized)
                                .font(.planeaCaption)
                        }
                        Spacer()
                    }
                }
                
                Section {
                    Button(action: completeOnboarding) {
                        Text("onboarding.continue".localized)
                            .frame(maxWidth: .infinity)
                            .font(.planeaHeadline)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(familyVM.family.name.isEmpty || familyVM.members.isEmpty)
                    
                    if familyVM.family.name.isEmpty || familyVM.members.isEmpty {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.orange)
                            Text(familyVM.family.name.isEmpty ? 
                                "onboarding.requirement.familyName".localized : 
                                "onboarding.requirement.members".localized)
                                .font(.planeaCaption)
                                .foregroundColor(.planeaTextSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
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
