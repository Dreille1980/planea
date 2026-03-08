//
//  PlaneaRadius.swift
//  Planea
//
//  Created by Cline on 2026-03-08.
//  Design System - Corner Radius Scale
//  Phase 1: Quick Wins - UI/UX Improvements
//

import SwiftUI

/// Standardized corner radius scale for consistent rounding throughout the app
/// Usage: Use these values instead of hardcoded numbers for all corner radius
enum PlaneaRadius {
    /// 4pt - Très petit arrondi, pour petits éléments
    static let xs: CGFloat = 4
    
    /// 8pt - Petit arrondi, pour chips et badges
    static let sm: CGFloat = 8
    
    /// 10pt - Arrondi moyen-petit, pour éléments intermédiaires
    static let md: CGFloat = 10
    
    /// 12pt - Arrondi standard, pour cartes et boutons
    static let lg: CGFloat = 12
    
    /// 16pt - Grand arrondi, pour éléments proéminents
    static let xl: CGFloat = 16
    
    /// 20pt - Très grand arrondi, pour effets prononcés
    static let xxl: CGFloat = 20
    
    // MARK: - Semantic Radius (Usage-based aliases)
    
    /// Arrondi standard pour les cartes
    static let card: CGFloat = lg // 12pt
    
    /// Arrondi pour les boutons principaux
    static let button: CGFloat = lg // 12pt
    
    /// Arrondi pour les chips/pills
    static let chip: CGFloat = sm // 8pt
    
    /// Arrondi pour les badges
    static let badge: CGFloat = xs // 4pt
    
    /// Arrondi pour les inputs/textfields
    static let input: CGFloat = sm // 8pt
    
    /// Arrondi pour les sheets/modals
    static let sheet: CGFloat = xl // 16pt
}

// MARK: - View Extension for Easy Access

extension View {
    /// Applique le corner radius standard pour une carte
    func planeaCardStyle() -> some View {
        self.cornerRadius(PlaneaRadius.card)
    }
    
    /// Applique le corner radius standard pour un bouton
    func planeaButtonStyle() -> some View {
        self.cornerRadius(PlaneaRadius.button)
    }
    
    /// Applique le corner radius standard pour un chip/pill
    func planeaChipStyle() -> some View {
        self.cornerRadius(PlaneaRadius.chip)
    }
}
