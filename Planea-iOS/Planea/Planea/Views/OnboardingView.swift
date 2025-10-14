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
                Section(header: Text(String(localized: "onboarding.family"))) {
                    TextField(String(localized: "onboarding.familyName"), text: $familyVM.family.name)
                        .onChange(of: familyVM.family.name) { _ in
                            familyVM.saveData()
                        }
                }
                
                Section(header: Text(String(localized: "onboarding.members"))) {
                    ForEach(familyVM.members) { member in
                        NavigationLink(destination: MemberDetailView(member: member)) {
                            HStack {
                                Text(member.displayName)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    if !member.diets.isEmpty {
                                        Text("\(member.diets.count) \(String(localized: "count.diets"))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    if !member.allergens.isEmpty {
                                        Text("\(member.allergens.count) \(String(localized: "count.allergens"))")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                    if !member.dislikes.isEmpty {
                                        Text("\(member.dislikes.count) \(String(localized: "count.dislikes"))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    Button(action: { showingAddMember = true }) {
                        Label(String(localized: "family.addMember"), systemImage: "plus.circle.fill")
                    }
                }
                
                Section {
                    Text(String(localized: "onboarding.hint"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Button(action: completeOnboarding) {
                        Text(String(localized: "onboarding.continue"))
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(familyVM.family.name.isEmpty || familyVM.members.isEmpty)
                }
            }
            .navigationTitle(String(localized: "onboarding.welcome"))
            .navigationBarTitleDisplayMode(.large)
            .interactiveDismissDisabled()
            .alert(String(localized: "family.addMember"), isPresented: $showingAddMember) {
                TextField(String(localized: "member.name"), text: $newMemberName)
                Button(String(localized: "action.cancel"), role: .cancel) {
                    newMemberName = ""
                }
                Button(String(localized: "action.add")) {
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
