//
//  PlaneaTypography.swift
//  Planea
//
//  Created by Cline on 2026-03-08.
//  Design System - Typography Scale with Dynamic Type Support
//  Phase 2: Accessibility Improvements
//

import SwiftUI

/// Typography scale with Dynamic Type support for accessibility
/// All text styles automatically adapt to user's preferred text size
extension Font {
    // MARK: - Display Styles (Large Headings)
    
    /// Display Large - For hero sections (34pt base)
    static let planeaDisplayLarge = Font.system(.largeTitle, design: .default, weight: .bold)
    
    /// Display Medium - For section headers (28pt base)
    static let planeaDisplayMedium = Font.system(.title, design: .default, weight: .bold)
    
    // MARK: - Title Styles
    
    /// Title 1 - Main titles (28pt base)
    static let planeaTitle1 = Font.system(.title, design: .default, weight: .semibold)
    
    /// Title 2 - Section titles (22pt base)
    static let planeaTitle2 = Font.system(.title2, design: .default, weight: .semibold)
    
    /// Title 3 - Subsection titles (20pt base)
    static let planeaTitle3 = Font.system(.title3, design: .default, weight: .semibold)
    
    // MARK: - Body Styles
    
    /// Headline - Important body text (17pt base, semibold)
    static let planeaHeadline = Font.system(.headline, design: .default, weight: .semibold)
    
    /// Body - Standard body text (17pt base, regular)
    static let planeaBody = Font.system(.body, design: .default, weight: .regular)
    
    /// Body Emphasized - Emphasized body text (17pt base, medium)
    static let planeaBodyEmphasized = Font.system(.body, design: .default, weight: .medium)
    
    /// Callout - Secondary body text (16pt base)
    static let planeaCallout = Font.system(.callout, design: .default, weight: .regular)
    
    // MARK: - Supporting Styles
    
    /// Subheadline - Labels, secondary text (15pt base)
    static let planeaSubheadline = Font.system(.subheadline, design: .default, weight: .regular)
    
    /// Footnote - Tertiary info (13pt base)
    static let planeaFootnote = Font.system(.footnote, design: .default, weight: .regular)
    
    /// Caption 1 - Small supporting text (12pt base)
    static let planeaCaption1 = Font.system(.caption, design: .default, weight: .regular)
    
    /// Caption 2 - Extra small text (11pt base)
    static let planeaCaption2 = Font.system(.caption2, design: .default, weight: .regular)
}

// MARK: - Text Style Extension

extension Text {
    /// Applique le style Display Large avec Dynamic Type
    func planeaDisplayLarge() -> Text {
        self.font(.planeaDisplayLarge)
    }
    
    /// Applique le style Display Medium avec Dynamic Type
    func planeaDisplayMedium() -> Text {
        self.font(.planeaDisplayMedium)
    }
    
    /// Applique le style Title 1 avec Dynamic Type
    func planeaTitle1() -> Text {
        self.font(.planeaTitle1)
    }
    
    /// Applique le style Title 2 avec Dynamic Type
    func planeaTitle2() -> Text {
        self.font(.planeaTitle2)
    }
    
    /// Applique le style Title 3 avec Dynamic Type
    func planeaTitle3() -> Text {
        self.font(.planeaTitle3)
    }
    
    /// Applique le style Headline avec Dynamic Type
    func planeaHeadline() -> Text {
        self.font(.planeaHeadline)
    }
    
    /// Applique le style Body avec Dynamic Type
    func planeaBody() -> Text {
        self.font(.planeaBody)
    }
    
    /// Applique le style Body Emphasized avec Dynamic Type
    func planeaBodyEmphasized() -> Text {
        self.font(.planeaBodyEmphasized)
    }
    
    /// Applique le style Callout avec Dynamic Type
    func planeaCallout() -> Text {
        self.font(.planeaCallout)
    }
    
    /// Applique le style Subheadline avec Dynamic Type
    func planeaSubheadline() -> Text {
        self.font(.planeaSubheadline)
    }
    
    /// Applique le style Footnote avec Dynamic Type
    func planeaFootnote() -> Text {
        self.font(.planeaFootnote)
    }
    
    /// Applique le style Caption 1 avec Dynamic Type
    func planeaCaption1() -> Text {
        self.font(.planeaCaption1)
    }
    
    /// Applique le style Caption 2 avec Dynamic Type
    func planeaCaption2() -> Text {
        self.font(.planeaCaption2)
    }
}

// MARK: - View Modifier for Dynamic Type Limits

struct DynamicTypeSizeLimits: ViewModifier {
    let minimum: DynamicTypeSize
    let maximum: DynamicTypeSize
    
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(minimum...maximum)
    }
}

extension View {
    /// Limite la taille du Dynamic Type pour éviter les layouts cassés
    /// Par défaut: .small à .xxxLarge (permet zoom jusqu'à 310%)
    func planeaDynamicTypeSize(
        min: DynamicTypeSize = .small,
        max: DynamicTypeSize = .xxxLarge
    ) -> some View {
        self.modifier(DynamicTypeSizeLimits(minimum: min, maximum: max))
    }
}

// MARK: - Usage Guide
/*
 Usage dans les vues:
 
 // Avec extension Text:
 Text("Titre principal")
     .planeaTitle1()
 
 // Avec Font directement:
 Text("Contenu")
     .font(.planeaBody)
 
 // Avec limite de Dynamic Type:
 VStack {
     Text("Contenu")
         .font(.planeaBody)
 }
 .planeaDynamicTypeSize(min: .medium, max: .xxLarge)
 
 Bénéfices:
 - ✅ Adaptation automatique aux préférences utilisateur
 - ✅ Support complet de l'accessibilité iOS
 - ✅ Tests faciles avec simulateur (Settings > Accessibility > Larger Text)
 - ✅ Cohérence typographique garantie
 */
