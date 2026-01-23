//
//  PlaneaColors.swift
//  Planea
//
//  Created by Cline on 2026-01-22.
//  Design System - Color Palette "Version moins pastel / plus pro"
//

import SwiftUI

extension Color {
    // MARK: - Planea Brand Colors
    
    /// Bleu ardoise - Couleur primaire pour actions principales
    /// Usage STRICT : Bouton "Générer le plan", icône active bottom tab, underline segmented control
    static let planeaPrimary = Color(hex: "#4E6FAE")
    
    /// Orange brûlé - Couleur secondaire pour accents et chaleur
    /// Usage : Mot clé dans titre ("Planifiez"), chip sélectionné (fond léger), icône ✨
    static let planeaSecondary = Color(hex: "#E38A3F")
    
    /// Vert sauge foncé - Couleur tertiaire pour structure
    /// Usage : Barre verticale gauche des cartes jour (4px, 100% opacité)
    static let planeaTertiary = Color(hex: "#7FA19B")
    
    // MARK: - Neutrals
    
    /// Fond principal de l'application
    static let planeaBackground = Color(hex: "#F2F3F7")
    
    /// Fond des cartes
    static let planeaCard = Color.white
    
    /// Texte principal (titres, contenu important)
    static let planeaTextPrimary = Color(hex: "#1C1C1E")
    
    /// Texte secondaire (descriptions, labels)
    static let planeaTextSecondary = Color(hex: "#6B7280")
    
    /// Bordures légères
    static let planeaBorder = Color(hex: "#E5E7EB")
    
    /// Fond chips par défaut (non sélectionné)
    static let planeaChipDefault = Color(hex: "#F1F2F6")
    
    // MARK: - Helper
    
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
}
