import SwiftUI

struct MemberDetailView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @Environment(\.dismiss) var dismiss
    
    let member: Member
    @State private var name: String
    @State private var selectedDiets: Set<String>
    @State private var selectedAllergens: Set<String>
    @State private var dislikes: [String]
    @State private var newDislike: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    init(member: Member) {
        self.member = member
        _name = State(initialValue: member.displayName)
        _selectedDiets = State(initialValue: Set(member.diets))
        _selectedAllergens = State(initialValue: Set(member.allergens))
        _dislikes = State(initialValue: member.dislikes)
    }
    
    let availableDiets = ["vegetarian", "vegan", "pescatarian", "gluten-free", "dairy-free", "keto", "paleo"]
    let availableAllergens = ["nuts", "peanuts", "dairy", "eggs", "soy", "wheat", "fish", "shellfish"]
    
    var body: some View {
        Form {
            Section(header: Text(String(localized: "member.name"))) {
                TextField(String(localized: "member.memberName"), text: $name)
                    .focused($isTextFieldFocused)
            }
            
            Section(header: Text(String(localized: "member.dietaryPreferences"))) {
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
            }
            
            Section(header: Text(String(localized: "member.allergens"))) {
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
            }
            
            Section(header: Text(String(localized: "member.dislikes"))) {
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
                    TextField(String(localized: "member.addDislike"), text: $newDislike)
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
            }
            
            Section {
                Button(String(localized: "action.save")) {
                    saveMember()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle(String(localized: "member.editMember"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(String(localized: "action.done")) {
                    isTextFieldFocused = false
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
        dismiss()
    }
}
