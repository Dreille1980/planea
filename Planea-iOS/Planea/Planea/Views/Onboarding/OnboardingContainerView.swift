import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var familyVM: FamilyViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @Binding var isPresented: Bool
    
    @State private var progress: OnboardingProgress
    @State private var currentStep: OnboardingStep
    @State private var showingMemberDetail: Member?
    @State private var familyName: String = ""
    
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        
        // Load saved progress
        let savedProgress = OnboardingProgress.load()
        _progress = State(initialValue: savedProgress)
        
        // Determine starting step
        if !savedProgress.hasSeenTour {
            _currentStep = State(initialValue: .featureTour)
        } else if !savedProgress.hasCompletedFamilyName {
            _currentStep = State(initialValue: .familyName)
        } else if !savedProgress.hasCompletedPreferences {
            _currentStep = State(initialValue: .membersManagement)
        } else if !savedProgress.isComplete {
            _currentStep = State(initialValue: .completion)
        } else {
            _currentStep = State(initialValue: .featureTour)
        }
        
        _familyName = State(initialValue: savedProgress.familyName)
    }
    
    var body: some View {
        ZStack {
            // Main content based on current step
            Group {
                switch currentStep {
                case .featureTour:
                    AppFeatureTourView(isOnboarding: true) {
                        advanceFromTour()
                    }
                    .transition(.opacity)
                    
                case .familyName:
                    OnboardingFamilyNameView(
                        familyName: $familyName,
                        progress: $progress,
                        onContinue: {
                            // Save family name to FamilyViewModel
                            familyVM.family.name = familyName
                            familyVM.saveData()
                            advanceToMembers()
                        }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    
                case .membersManagement:
                    OnboardingMembersListView(
                        progress: $progress,
                        onContinue: {
                            advanceToPreferences()
                        },
                        onConfigureMember: { member in
                            showingMemberDetail = member
                        }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    
                case .generationPreferences:
                    OnboardingGenerationPreferencesView(
                        progress: $progress,
                        onContinue: {
                            advanceToCompletion()
                        }
                    )
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    
                case .completion:
                    OnboardingCompletionView(
                        progress: $progress,
                        onComplete: {
                            completeOnboarding()
                        }
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
        .sheet(item: $showingMemberDetail) { member in
            OnboardingMemberDetailView(
                member: member,
                progress: $progress,
                onSave: {
                    // Check if we should show "add another member" prompt
                    if let membersListView = findMembersListView() {
                        membersListView.checkForAddAnotherPrompt()
                    }
                }
            )
        }
        .interactiveDismissDisabled()
    }
    
    // MARK: - Navigation Methods
    
    private func advanceFromTour() {
        progress.hasSeenTour = true
        progress.currentStepIndex = OnboardingStep.familyName.rawValue
        progress.save()
        
        withAnimation {
            currentStep = .familyName
        }
    }
    
    private func advanceToMembers() {
        progress.currentStepIndex = OnboardingStep.membersManagement.rawValue
        progress.save()
        
        withAnimation {
            currentStep = .membersManagement
        }
    }
    
    private func advanceToPreferences() {
        progress.currentStepIndex = OnboardingStep.generationPreferences.rawValue
        progress.save()
        
        withAnimation {
            currentStep = .generationPreferences
        }
    }
    
    private func advanceToCompletion() {
        progress.currentStepIndex = OnboardingStep.completion.rawValue
        progress.save()
        
        withAnimation {
            currentStep = .completion
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        OnboardingProgress.reset() // Clear progress for next time
        
        // Start the 7-day free trial
        FreeTrialService.shared.startTrial()
        
        isPresented = false
    }
    
    // Helper to find the members list view (for triggering add another prompt)
    private func findMembersListView() -> OnboardingMembersListView? {
        // This is a workaround since we can't directly access the view
        // The prompt logic is handled within OnboardingMembersListView itself
        return nil
    }
}

#Preview {
    OnboardingContainerView(isPresented: .constant(true))
        .environmentObject(FamilyViewModel())
}
