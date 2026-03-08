//
//  PlaneaShadows.swift
//  Planea
//
//  Created by Cline on 2026-03-08.
//  Design System - Shadow Presets
//  Phase 1: Quick Wins - UI/UX Improvements
//

import SwiftUI

/// Shadow levels enum for semantic shadow application
enum PlaneaShadowLevel {
    case subtle
    case low
    case medium
    case high
    case veryHigh
}

/// Shadow presets for consistent elevation throughout the app
/// Provides standardized shadow styles for different UI elevations
extension View {
    /// Apply shadow with semantic level
    /// Usage: .planeaShadow(.medium)
    func planeaShadow(_ level: PlaneaShadowLevel) -> some View {
        switch level {
        case .subtle:
            return AnyView(self.planeaSubtleShadow())
        case .low:
            return AnyView(self.planeaButtonShadow())
        case .medium:
            return AnyView(self.planeaElevatedShadow())
        case .high:
            return AnyView(self.planeaHighElevationShadow())
        case .veryHigh:
            return AnyView(self.shadow(color: Color.black.opacity(0.20), radius: 20, x: 0, y: 8))
        }
    }
    
    /// Ombre légère pour les cartes standard
    /// Utilise: Cards, items de liste
    /// Elevation: Basse (0-2dp)
    func planeaCardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
    }
    
    /// Ombre moyenne pour les éléments surélevés
    /// Utilise: Boutons flottants, sheets partiels
    /// Elevation: Moyenne (2-4dp)
    func planeaElevatedShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
    }
    
    /// Ombre prononcée pour les éléments très surélevés
    /// Utilise: Modals, menus contextuels, popovers
    /// Elevation: Haute (4-8dp)
    func planeaHighElevationShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.16), radius: 16, x: 0, y: 6)
    }
    
    /// Ombre subtile pour les éléments légèrement surélevés
    /// Utilise: Chips sélectionnés, badges
    /// Elevation: Très basse (0-1dp)
    func planeaSubtleShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    /// Ombre pour les boutons, avec légère élévation
    /// Utilise: Boutons principaux, CTAs
    /// Elevation: Basse (1-2dp)
    func planeaButtonShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Dark Mode Considerations
// Note: SwiftUI's .shadow() automatically adapts to dark mode by reducing opacity.
// No manual dark mode handling needed for shadows.
