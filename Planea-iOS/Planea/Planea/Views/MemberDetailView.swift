import SwiftUI

struct MemberDetailView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @Environment(\.dismiss) var dismiss
    
    let member: Member
    @State private var name: String
    @State private var selectedDiets: Set<String>
    @State private var selectedAllergens: Set<String>
    @State private var customAllergens: [String]
    @State private var dislikes: [String]
    @State private var newDislike: String = ""
    @State private var newCustomAllergen: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    init(member: Member) {
        self.member = member
        _name = State(initialValue: member.displayName)
        _selectedDiets = State(initialValue: Set(member.diets))
        
        // Separate predefined allergens from custom ones
        let predefinedSet = Set(Self.availableAllergens)
        let memberAllergens = Set(member.allergens)
        _selectedAllergens = State(initialValue: memberAllergens.intersection(predefinedSet))
        _customAllergens = State(initialValue: Array(memberAllergens.subtracting(predefinedSet)))
        
        _dislikes = State(initialValue: member.dislikes)
    }
    
    let availableDiets = ["vegetarian", "vegan", "pescatarian", "gluten-free", "dairy-free", "keto", "paleo", "halal", "kosher"]
    static let availableAllergens = ["nuts", "peanuts", "dairy", "eggs", "soy", "wheat", "fish", "shellfish"]
    
    var body: some View {
        Form {
            Section(header: Text("member.name".localized)) {
                TextField("member.memberName".localized, text: $name)
                    .focused($isTextFieldFocused)
            }
            
            Section(header: Text("member.dietaryPreferences".localized)) {
                ForEach(availableDiets, id: \.self) { diet in
                    Toggle("diet.\(diet)".localized, isOn: Binding(
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
            
            Section(header: Text("member.allergens".localized)) {
                ForEach(Self.availableAllergens, id: \.self) { allergen in
                    Toggle("allergen.\(allergen)".localized, isOn: Binding(
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
            
            Section(header: Text("member.customAllergens".localized)) {
                ForEach(customAllergens.indices, id: \.self) { index in
                    HStack {
                        Text(customAllergens[index].capitalized)
                        Spacer()
                        Button(action: {
                            customAllergens.remove(at: index)
                        }) {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                HStack {
                    TextField("member.addCustomAllergen".localized, text: $newCustomAllergen)
                        .focused($isTextFieldFocused)
                    Button(action: {
                        let trimmed = newCustomAllergen.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        if !trimmed.isEmpty && !customAllergens.contains(trimmed) && !selectedAllergens.contains(trimmed) {
                            customAllergens.append(trimmed)
                            newCustomAllergen = ""
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newCustomAllergen.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            
            Section(header: Text("member.dislikes".localized)) {
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
            }
            
            Section {
                Button("action.save".localized) {
                    saveMember()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("member.editMember".localized)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("action.done".localized) {
                    isTextFieldFocused = false
                }
            }
        }
    }
    
    func saveMember() {
        // Combine predefined and custom allergens
        let allAllergens = Array(selectedAllergens) + customAllergens
        
        familyVM.updateMember(
            id: member.id,
            name: name,
            preferences: Array(selectedDiets),
            allergens: allAllergens,
            dislikes: dislikes
        )
        dismiss()
    }
}
