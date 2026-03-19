
import Foundation
import StoreKit

/// Service gérant la logique d'affichage du prompt de notation App Store
class AppRatingService {
    static let shared = AppRatingService()

    // MARK: - UserDefaults Keys

    private let installDateKey = "appInstallDate"
    private let ratingStateKey = "appRatingPromptState"
    private let lastShownDateKey = "appRatingLastShownDate"

    // MARK: - Constants

    /// Nombre de jours avant le premier affichage
    private let daysBeforeFirstPrompt: Int = 7
    /// Nombre de jours avant de re-demander après un "Non"
    private let daysBeforeRetry: Int = 60

    // MARK: - State

    enum RatingState: String {
        case notShown    = "notShown"
        case shownAndNo  = "shownAndNo"
        case shownAndYes = "shownAndYes"
    }

    private init() {
        registerInstallDateIfNeeded()
    }

    // MARK: - Public Interface

    /// Vérifie si le prompt de notation doit être affiché
    func shouldShowRatingPrompt() -> Bool {
        let state = currentState()

        switch state {
        case .shownAndYes:
            // L'utilisateur a déjà dit oui, ne plus jamais redemander
            return false

        case .notShown:
            // Premier affichage : vérifier si 7 jours se sont écoulés depuis l'installation
            return daysElapsedSinceInstall() >= daysBeforeFirstPrompt

        case .shownAndNo:
            // Re-afficher si 60 jours se sont écoulés depuis le dernier affichage
            guard let lastShown = lastShownDate() else { return false }
            let daysSinceLastShown = Calendar.current.dateComponents(
                [.day], from: lastShown, to: Date()
            ).day ?? 0
            return daysSinceLastShown >= daysBeforeRetry
        }
    }

    /// Enregistre que le prompt a été affiché
    func markPromptShown() {
        UserDefaults.standard.set(Date(), forKey: lastShownDateKey)
    }

    /// Enregistre la réponse positive de l'utilisateur et déclenche la fenêtre native
    func userRespondedPositively() {
        setState(.shownAndYes)
        requestNativeReview()
    }

    /// Enregistre la réponse négative de l'utilisateur
    func userRespondedNegatively() {
        setState(.shownAndNo)
    }

    /// Déclenche la fenêtre de notation native Apple (SKStoreReviewController)
    func requestNativeReview() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }

    // MARK: - Debug / Testing

    /// Réinitialise l'état pour les tests (à utiliser uniquement en debug)
    func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: installDateKey)
        UserDefaults.standard.removeObject(forKey: ratingStateKey)
        UserDefaults.standard.removeObject(forKey: lastShownDateKey)
        registerInstallDateIfNeeded()
    }

    // MARK: - Private Helpers

    private func registerInstallDateIfNeeded() {
        if UserDefaults.standard.object(forKey: installDateKey) == nil {
            UserDefaults.standard.set(Date(), forKey: installDateKey)
        }
    }

    private func currentState() -> RatingState {
        let raw = UserDefaults.standard.string(forKey: ratingStateKey) ?? RatingState.notShown.rawValue
        return RatingState(rawValue: raw) ?? .notShown
    }

    private func setState(_ state: RatingState) {
        UserDefaults.standard.set(state.rawValue, forKey: ratingStateKey)
    }

    private func installDate() -> Date {
        return UserDefaults.standard.object(forKey: installDateKey) as? Date ?? Date()
    }

    private func lastShownDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastShownDateKey) as? Date
    }

    private func daysElapsedSinceInstall() -> Int {
        let components = Calendar.current.dateComponents([.day], from: installDate(), to: Date())
        return components.day ?? 0
    }
}
