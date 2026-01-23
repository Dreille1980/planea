//
//  PlaneaSegmentedControlStyle.swift
//  Planea
//
//  Created by Cline on 2026-01-22.
//  Custom Segmented Control Style - Underline bleu ardoise pour onglet actif
//

import SwiftUI

/// Modifier pour styliser un Picker en segmented control avec underline
struct PlaneaSegmentedPickerStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .pickerStyle(.segmented)
            .tint(.planeaPrimary) // Underline et highlight en bleu ardoise
    }
}

extension View {
    /// Applique le style Planea au segmented control
    func planeaSegmentedStyle() -> some View {
        modifier(PlaneaSegmentedPickerStyle())
    }
}
