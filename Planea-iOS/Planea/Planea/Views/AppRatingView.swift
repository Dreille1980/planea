import SwiftUI

/// Pop-up personnalisé demandant à l'utilisateur s'il aime l'app
/// Si oui → SKStoreReviewController (App Store rating)
/// Si non → Invitation à envoyer un email de feedback
struct AppRatingView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.planeaTextSecondary.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 24)

            // App icon + titre
            VStack(spacing: 16) {
                // App icon
                Image("PlaneaLogo 1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)

                // Titre et sous-titre
                VStack(spacing: 8) {
                    Text("rating.title".localized)
                        .font(.planeaTitle3)
                        .fontWeight(.bold)
                        .foregroundColor(.planeaTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("rating.subtitle".localized)
                        .font(.planeaBody)
                        .foregroundColor(.planeaTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)

            // Boutons de réponse
            VStack(spacing: 12) {
                // Bouton Oui
                Button(action: handlePositiveResponse) {
                    HStack(spacing: 10) {
                        Text("⭐️")
                            .font(.title3)
                        Text("rating.positive".localized)
                            .font(.planeaBody)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.planeaPrimary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: PlaneaRadius.medium))
                }

                // Bouton Non
                Button(action: handleNegativeResponse) {
                    HStack(spacing: 10) {
                        Text("💬")
                            .font(.title3)
                        Text("rating.negative".localized)
                            .font(.planeaBody)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.planeaTextSecondary.opacity(0.1))
                    .foregroundColor(.planeaTextPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: PlaneaRadius.medium))
                }

                // Bouton Plus tard
                Button(action: handleLaterResponse) {
                    Text("rating.later".localized)
                        .font(.planeaSubheadline)
                        .foregroundColor(.planeaTextSecondary)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color.planeaBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Actions

    private func handlePositiveResponse() {
        AnalyticsService.shared.logRatingPromptPositive()
        AppRatingService.shared.userRespondedPositively()
        isPresented = false
        // La fenêtre native est appelée depuis AppRatingService avec un délai
    }

    private func handleNegativeResponse() {
        AnalyticsService.shared.logRatingPromptNegative()
        AppRatingService.shared.userRespondedNegatively()
        isPresented = false

        // Ouvrir le client mail pour feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            sendFeedback()
        }
    }

    private func handleLaterResponse() {
        // Ne pas changer l'état — on re-vérifiera au prochain lancement
        isPresented = false
    }

    private func sendFeedback() {
        let systemVersion = UIDevice.current.systemVersion
        let deviceModel = UIDevice.current.model
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?")
            + " (" + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?") + ")"

        let subject = "rating.feedback.subject".localized
        let body = String(format: "feedback.body".localized, appVersion, systemVersion, deviceModel)

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let mailtoString = "mailto:dreyerfred+planea@gmail.com?subject=\(encodedSubject)&body=\(encodedBody)"

        if let mailtoURL = URL(string: mailtoString) {
            if UIApplication.shared.canOpenURL(mailtoURL) {
                UIApplication.shared.open(mailtoURL)
            }
        }
    }
}

#Preview {
    Color.black.opacity(0.4)
        .ignoresSafeArea()
        .sheet(isPresented: .constant(true)) {
            AppRatingView(isPresented: .constant(true))
                .presentationDetents([.height(420)])
        }
}
