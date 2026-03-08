//
//  PlaneaSpacing.swift
//  Planea
//
//  Created by Cline on 2026-03-08.
//  Design System - Spacing Scale
//  Phase 1: Quick Wins - UI/UX Improvements
//

import SwiftUI

/// Standardized spacing scale for consistent layout throughout the app
/// Usage: Use these values instead of hardcoded numbers for all spacing
enum PlaneaSpacing {
    /// 4pt - Très petit espacement, pour éléments très proches
    static let xs: CGFloat = 4
    
    /// 8pt - Petit espacement, entre éléments d'un groupe
    static let sm: CGFloat = 8
    
    /// 12pt - Espacement moyen, standard entre sections
    static let md: CGFloat = 12
    
    /// 16pt - Grand espacement, entre sections importantes
    static let lg: CGFloat = 16
    
    /// 20pt - Très grand espacement, séparation de groupes majeurs
    static let xl: CGFloat = 20
    
    /// 24pt - Extra large, entre sections majeures
    static let xxl: CGFloat = 24
    
    /// 32pt - Maximum, pour séparations très importantes
    static let xxxl: CGFloat = 32
    
    // MARK: - Semantic Spacing (Usage-based aliases)
    
    /// Espacement standard pour le padding de cartes
    static let cardPadding: CGFloat = md // 12pt
    
    /// Espacement entre cartes dans une liste
    static let cardGap: CGFloat = lg // 16pt
    
    /// Espacement horizontal standard pour les écrans
    static let screenHorizontal: CGFloat = lg // 16pt
    
    /// Espacement vertical standard pour les écrans
    static let screenVertical: CGFloat = lg // 16pt
    
    /// Espacement entre sections dans un formulaire
    static let formSectionGap: CGFloat = xxl // 24pt
    
    /// Espacement dans un HStack de boutons
    static let buttonGap: CGFloat = md // 12pt
}

// MARK: - View Extension for Easy Access

extension View {
    /// Ajoute un padding standard pour une carte
    func planeaCardPadding() -> some View {
        self.padding(PlaneaSpacing.cardPadding)
    }
    
    /// Ajoute un padding horizontal standard pour un écran
    func planeaScreenPadding() -> some View {
        self.padding(.horizontal, PlaneaSpacing.screenHorizontal)
            .padding(.vertical, PlaneaSpacing.screenVertical)
    }
}
