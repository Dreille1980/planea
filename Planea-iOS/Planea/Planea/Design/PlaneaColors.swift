//
//  PlaneaColors.swift
//  Planea
//
//  Created by Cline on 2026-01-22.
//  Design System - Color Palette "Version moins pastel / plus pro"
//  Dark Mode Support Added - 2026-02-20
//

import SwiftUI

extension Color {
    // MARK: - Planea Brand Colors
    
    /// Bleu ardoise - Couleur primaire pour actions principales
    /// Usage STRICT : Bouton "Générer le plan", icône active bottom tab, underline segmented control
    static let planeaPrimary = Color(light: "#4E6FAE", dark: "#6B8FD1")
    
    /// Orange brûlé - Couleur secondaire pour accents et chaleur
    /// Usage : Mot clé dans titre ("Planifiez"), chip sélectionné (fond léger), icône ✨
    static let planeaSecondary = Color(light: "#E38A3F", dark: "#F5A563")
    
    /// Vert sauge foncé - Couleur tertiaire pour structure
    /// Usage : Barre verticale gauche des cartes jour (4px, 100% opacité)
    static let planeaTertiary = Color(light: "#7FA19B", dark: "#95B8B1")
    
    /// Rouge brique - Couleur pour les actions de suppression
    /// Usage : Bouton supprimer, actions destructives
    static let planeaDanger = Color(light: "#C94A4A", dark: "#E96B6B")
    
    // MARK: - Neutrals
    
    /// Fond principal de l'application
    static let planeaBackground = Color(light: "#F2F3F7", dark: "#000000")
    
    /// Fond des cartes
    static let planeaCard = Color(light: "#FFFFFF", dark: "#1C1C1E")
    
    /// Texte principal (titres, contenu important)
    static let planeaTextPrimary = Color(light: "#1C1C1E", dark: "#FFFFFF")
    
    /// Texte secondaire (descriptions, labels)
    static let planeaTextSecondary = Color(light: "#6B7280", dark: "#98989D")
    
    /// Bordures légères
    static let planeaBorder = Color(light: "#E5E7EB", dark: "#38383A")
    
    /// Fond chips par défaut (non sélectionné)
    static let planeaChipDefault = Color(light: "#F1F2F6", dark: "#2C2C2E")
    
    // MARK: - Helper Initializers
    
    /// Crée une couleur à partir d'un code hexadécimal
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Crée une couleur adaptative pour light/dark mode
    init(light: String, dark: String) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(Color(hex: dark))
            default:
                return UIColor(Color(hex: light))
            }
        })
    }
}
