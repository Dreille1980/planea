import SwiftUI

struct OnboardingFamilyNameView: View {
    @Binding var familyName: String
    @Binding var progress: OnboardingProgress
    let onContinue: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "house.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
            }
            
            // Title
            Text("onboarding.familyname.title".localized)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Text Field
            VStack(alignment: .leading, spacing: 8) {
                TextField("onboarding.familyname.placeholder".localized, text: $familyName)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .focused($isTextFieldFocused)
                    .textContentType(.organizationName)
                    .autocapitalization(.words)
                    .submitLabel(.continue)
                    .onSubmit {
                        if !familyName.isEmpty {
                            saveFamilyName()
                        }
                    }
                    .padding(.horizontal, 32)
                
                if familyName.isEmpty {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                        Text("onboarding.familyname.hint".localized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 32)
                }
            }
            
            Spacer()
            
            // Continue Button
            Button(action: saveFamilyName) {
                Text("action.continue".localized)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(familyName.isEmpty ? Color.gray : Color.blue)
                    .cornerRadius(12)
            }
            .disabled(familyName.isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .onAppear {
            // Auto-focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func saveFamilyName() {
        guard !familyName.isEmpty else { return }
        
        progress.familyName = familyName
        progress.hasCompletedFamilyName = true
        progress.save()
        
        onContinue()
    }
}

#Preview {
    OnboardingFamilyNameView(
        familyName: .constant(""),
        progress: .constant(OnboardingProgress())
    ) {
        print("Continue tapped")
    }
}
