import SwiftUI

struct OnboardingMemberDetailView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var progress: OnboardingProgress
    
    let member: Member
    let onSave: () -> Void
    
    @State private var name: String
    @State private var selectedDiets: Set<String>
    @State private var selectedAllergens: Set<String>
    @State private var dislikes: [String]
    @State private var newDislike: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    init(member: Member, progress: Binding<OnboardingProgress>, onSave: @escaping () -> Void) {
        self.member = member
        self._progress = progress
        self.onSave = onSave
        _name = State(initialValue: member.displayName)
        _selectedDiets = State(initialValue: Set(member.diets))
        _selectedAllergens = State(initialValue: Set(member.allergens))
        _dislikes = State(initialValue: member.dislikes)
    }
    
    let availableDiets = ["vegetarian", "vegan", "pescatarian", "gluten-free", "dairy-free", "keto", "paleo"]
    let availableAllergens = ["nuts", "peanuts", "dairy", "eggs", "soy", "wheat", "fish", "shellfish"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("member.name".localized)) {
                    TextField("member.memberName".localized, text: $name)
                        .focused($isTextFieldFocused)
                }
                
                Section {
                    ForEach(availableDiets, id: \.self) { diet in
                        Toggle(diet.capitalized, isOn: Binding(
                            get: { selectedDiets.contains(diet) },
                            set: { isOn in
                                if isOn {
                                    selectedDiets.insert(diet)
                                } else {
                                    selectedDiets.remove(diet)
                                }
                            }
                        ))
                    }
                } header: {
                    Label("member.dietaryPreferences".localized, systemImage: "leaf.fill")
                } footer: {
                    Text("onboarding.member.diets.footer".localized)
                        .font(.caption)
                }
                
                Section {
                    ForEach(availableAllergens, id: \.self) { allergen in
                        Toggle(allergen.capitalized, isOn: Binding(
                            get: { selectedAllergens.contains(allergen) },
                            set: { isOn in
                                if isOn {
                                    selectedAllergens.insert(allergen)
                                } else {
                                    selectedAllergens.remove(allergen)
                                }
                            }
                        ))
                    }
                } header: {
                    Label("member.allergens".localized, systemImage: "exclamationmark.triangle.fill")
                } footer: {
                    Text("onboarding.member.allergens.footer".localized)
                        .font(.caption)
                }
                
                Section {
                    ForEach(dislikes.indices, id: \.self) { index in
                        HStack {
                            Text(dislikes[index])
                            Spacer()
                            Button(action: {
                                dislikes.remove(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("member.addDislike".localized, text: $newDislike)
                            .focused($isTextFieldFocused)
                        Button(action: {
                            if !newDislike.isEmpty {
                                dislikes.append(newDislike)
                                newDislike = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newDislike.isEmpty)
                    }
                } header: {
                    Label("member.dislikes".localized, systemImage: "hand.thumbsdown.fill")
                } footer: {
                    Text("onboarding.member.dislikes.footer".localized)
                        .font(.caption)
                }
            }
            .navigationTitle("onboarding.member.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("action.done".localized) {
                        isTextFieldFocused = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.save".localized) {
                        saveMember()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func saveMember() {
        familyVM.updateMember(
            id: member.id,
            name: name,
            preferences: Array(selectedDiets),
            allergens: Array(selectedAllergens),
            dislikes: dislikes
        )
        
        // Mark member as configured in progress
        progress.markMemberConfigured(member.id)
        progress.save()
        
        onSave()
        dismiss()
    }
}

#Preview {
    let familyVM = FamilyViewModel()
    let testMember = Member(
        familyId: familyVM.family.id,
        displayName: "Jean",
        preferences: []
    )
    
    return OnboardingMemberDetailView(
        member: testMember,
        progress: .constant(OnboardingProgress()),
        onSave: { print("Saved") }
    )
    .environmentObject(familyVM)
}
