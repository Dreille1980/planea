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
                
                Section(header: Text("Members")) {
                    ForEach(familyVM.members) { member in
                        NavigationLink(destination: MemberDetailView(member: member)) {
                            HStack {
                                Text(member.displayName)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    if !member.diets.isEmpty {
                                        Text("\(member.diets.count) diet(s)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    if !member.allergens.isEmpty {
                                        Text("\(member.allergens.count) allergen(s)")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                    if !member.dislikes.isEmpty {
                                        Text("\(member.dislikes.count) dislike(s)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    Button(action: { showingAddMember = true }) {
                        Label("Add Member", systemImage: "plus.circle.fill")
                    }
                }
                
                Section {
                    Text(String(localized: "onboarding.hint"))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Section {
                    Button(action: completeOnboarding) {
                        Text("Continue")
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(familyVM.family.name.isEmpty || familyVM.members.isEmpty)
                }
            }
            .navigationTitle("Welcome to Planea")
            .navigationBarTitleDisplayMode(.large)
            .interactiveDismissDisabled()
            .alert("Add Member", isPresented: $showingAddMember) {
                TextField("Name", text: $newMemberName)
                Button("Cancel", role: .cancel) { 
                    newMemberName = ""
                }
                Button("Add") {
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
