//
//  PlaneaAnimation.swift
//  Planea
//
//  Created by Cline on 2026-03-08.
//  Design System - Animation Utilities with Reduce Motion Support
//  Phase 2: Accessibility Improvements
//

import SwiftUI

/// Animation utilities that respect user's Reduce Motion setting
/// Automatically adapts animations for users with motion sensitivity
extension View {
    /// Applique une animation uniquement si Reduce Motion est désactivé
    /// Sinon, change immédiat sans animation
    /// - Parameters:
    ///   - animation: L'animation à appliquer si Reduce Motion est off
    ///   - value: La valeur qui déclenche l'animation
    /// - Returns: View avec animation conditionnelle
    func planeaAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        self.modifier(ReduceMotionModifier(animation: animation, value: value))
    }
    
    /// Applique une animation de spring respectueuse de Reduce Motion
    /// Spring standard: response 0.3, dampingFraction 0.7
    func planeaSpring<V: Equatable>(value: V) -> some View {
        self.planeaAnimation(.spring(response: 0.3, dampingFraction: 0.7), value: value)
    }
    
    /// Applique une animation fluide respectueuse de Reduce Motion
    /// Easing standard: 0.3 secondes
    func planeaEaseInOut<V: Equatable>(value: V, duration: Double = 0.3) -> some View {
        self.planeaAnimation(.easeInOut(duration: duration), value: value)
    }
}

// MARK: - Reduce Motion Modifier

private struct ReduceMotionModifier<V: Equatable>: ViewModifier {
    let animation: Animation?
    let value: V
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        if reduceMotion {
            // Reduce Motion activé: changement immédiat
            content
        } else {
            // Reduce Motion désactivé: animation normale
            content
                .animation(animation, value: value)
        }
    }
}

// MARK: - Transition Utilities

extension AnyTransition {
    /// Transition slide respectueuse de Reduce Motion
    /// Avec Reduce Motion: opacity uniquement
    /// Sans: slide + opacity
    static var planeaSlide: AnyTransition {
        get {
            let reduceMotion = UIAccessibility.isReduceMotionEnabled
            if reduceMotion {
                return .opacity
            } else {
                return .slide
            }
        }
    }
    
    /// Transition scale respectueuse de Reduce Motion
    /// Avec Reduce Motion: opacity uniquement
    /// Sans: scale + opacity
    static var planeaScale: AnyTransition {
        get {
            let reduceMotion = UIAccessibility.isReduceMotionEnabled
            if reduceMotion {
                return .opacity
            } else {
                return .scale.combined(with: .opacity)
            }
        }
    }
}

// MARK: - withAnimation Alternative

/// Version de withAnimation qui respecte Reduce Motion
/// - Parameters:
///   - animation: Animation à utiliser si Reduce Motion est off
///   - body: Closure contenant les changements d'état
func withPlaneaAnimation<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result {
    if UIAccessibility.isReduceMotionEnabled {
        // Reduce Motion activé: exécution immédiate
        return try body()
    } else {
        // Reduce Motion désactivé: animation normale
        return try withAnimation(animation, body)
    }
}

// MARK: - Usage Guide
/*
 Usage dans les vues:
 
 // Au lieu de .animation():
 Text("Hello")
     .planeaAnimation(.spring(), value: isExpanded)
 
 // Au lieu de .transition():
 if showDetails {
     DetailsView()
         .transition(.planeaScale)
 }
 
 // Au lieu de withAnimation {}:
 Button("Toggle") {
     withPlaneaAnimation(.spring()) {
         isExpanded.toggle()
     }
 }
 
 // Spring prédéfini:
 Text("Hello")
     .planeaSpring(value: count)
 
 Bénéfices:
 - ✅ Respecte automatiquement Reduce Motion
 - ✅ Améliore l'expérience pour utilisateurs sensibles au mouvement
 - ✅ Conformité WCAG 2.1 - Guideline 2.3 (Seizures)
 - ✅ Pas besoin de vérifier manuellement le setting
 */
