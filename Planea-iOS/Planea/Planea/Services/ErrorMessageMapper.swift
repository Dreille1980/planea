//
//  ErrorMessageMapper.swift
//  Planea
//
//  Created by Cline on 2026-03-08.
//  Service - User-Friendly Error Messages
//  Phase 3: UX Polish
//

import Foundation

/// Maps technical errors to user-friendly messages
/// Provides localized, actionable error messages for better UX
struct ErrorMessageMapper {
    
    /// Convert an Error to a user-friendly message
    /// - Parameter error: The error to map
    /// - Returns: Tuple of (title, message, isRecoverable)
    static func map(_ error: Error) -> (title: String, message: String, isRecoverable: Bool) {
        // Check for URLError first
        if let urlError = error as? URLError {
            return mapURLError(urlError)
        }
        
        // Check for custom API errors
        if let errorMessage = error.localizedDescription.lowercased() {
            if errorMessage.contains("quota") || errorMessage.contains("limite") {
                return (
                    title: "Limite atteinte",
                    message: "Vous avez atteint votre limite de génération. Réessayez plus tard ou passez à Premium pour des générations illimitées.",
                    isRecoverable: true
                )
            }
            
            if errorMessage.contains("auth") || errorMessage.contains("token") {
                return (
                    title: "Authentification requise",
                    message: "Veuillez vous reconnecter pour continuer.",
                    isRecoverable: true
                )
            }
            
            if errorMessage.contains("invalid") || errorMessage.contains("malformed") {
                return (
                    title: "Données invalides",
                    message: "Les données envoyées sont invalides. Veuillez réessayer.",
                    isRecoverable: true
                )
            }
        }
        
        // Default generic error
        return (
            title: "Une erreur s'est produite",
            message: "Quelque chose s'est mal passé. Veuillez réessayer dans quelques instants.",
            isRecoverable: true
        )
    }
    
    /// Map URLError to user-friendly message
    private static func mapURLError(_ urlError: URLError) -> (title: String, message: String, isRecoverable: Bool) {
        switch urlError.code {
        case .notConnectedToInternet:
            return (
                title: "Pas de connexion",
                message: "Vous n'êtes pas connecté à Internet. Vérifiez votre WiFi ou vos données cellulaires.",
                isRecoverable: true
            )
            
        case .timedOut:
            return (
                title: "Délai expiré",
                message: "Le serveur met trop de temps à répondre. Vérifiez votre connexion et réessayez.",
                isRecoverable: true
            )
            
        case .cannotFindHost, .cannotConnectToHost:
            return (
                title: "Serveur inaccessible",
                message: "Impossible de contacter le serveur. Vérifiez votre connexion Internet.",
                isRecoverable: true
            )
            
        case .networkConnectionLost:
            return (
                title: "Connexion perdue",
                message: "La connexion a été interrompue. Veuillez réessayer.",
                isRecoverable: true
            )
            
        case .badServerResponse:
            return (
                title: "Erreur serveur",
                message: "Le serveur a renvoyé une réponse invalide. Réessayez dans quelques instants.",
                isRecoverable: true
            )
            
        case .dataNotAllowed:
            return (
                title: "Données cellulaires désactivées",
                message: "Les données cellulaires sont désactivées pour cette app. Activez-les dans Réglages ou connectez-vous au WiFi.",
                isRecoverable: true
            )
            
        default:
            return (
                title: "Erreur réseau",
                message: "Une erreur réseau s'est produite. Vérifiez votre connexion et réessayez.",
                isRecoverable: true
            )
        }
    }
}

// MARK: - Usage in ViewModels

/*
 Exemple d'utilisation dans un ViewModel:
 
 do {
     let result = try await someNetworkCall()
     // Success
 } catch {
     let (title, message, isRecoverable) = ErrorMessageMapper.map(error)
     
     // Afficher l'erreur à l'utilisateur
     self.errorTitle = title
     self.errorMessage = message
     self.showError = true
     
     // Analytics optionnel
     AnalyticsService.shared.logError(title: title, isRecoverable: isRecoverable)
 }
 
 Bénéfices:
 - ✅ Messages compréhensibles pour l'utilisateur
 - ✅ Actions suggérées (vérifier connexion, etc.)
 - ✅ Centralisé et facilement maintenable
 - ✅ Évite les messages techniques effrayants
 */
