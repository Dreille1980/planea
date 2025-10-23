import SwiftUI

struct FamilyManagementView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @State private var newMemberName: String = ""
    @State private var showingAddMember = false
    
    var body: some View {
        Form {
            Section(header: Text("onboarding.family".localized)) {
                TextField("onboarding.familyName".localized, text: $familyVM.family.name)
                    .onChange(of: familyVM.family.name) {
                        familyVM.saveData()
                    }
            }
            
            Section(header: Text("family.members".localized)) {
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
                .onDelete(perform: deleteMembers)
                
                Button(action: { showingAddMember = true }) {
                    Label("family.addMember".localized, systemImage: "plus.circle.fill")
                }
            }
            
            Section {
                Text("onboarding.hint".localized)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("family.management".localized)
        .navigationBarTitleDisplayMode(.inline)
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
    
    private func deleteMembers(at offsets: IndexSet) {
        for index in offsets {
            let member = familyVM.members[index]
            familyVM.removeMember(id: member.id)
        }
    }
}
