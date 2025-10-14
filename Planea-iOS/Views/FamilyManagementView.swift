import SwiftUI

struct FamilyManagementView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @State private var newMemberName: String = ""
    @State private var showingAddMember = false
    
    var body: some View {
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
                .onDelete(perform: deleteMembers)
                
                Button(action: { showingAddMember = true }) {
                    Label("Add Member", systemImage: "plus.circle.fill")
                }
            }
            
            Section {
                Text(String(localized: "onboarding.hint"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Family Management")
        .navigationBarTitleDisplayMode(.inline)
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
    
    private func deleteMembers(at offsets: IndexSet) {
        for index in offsets {
            let member = familyVM.members[index]
            familyVM.removeMember(id: member.id)
        }
    }
}
