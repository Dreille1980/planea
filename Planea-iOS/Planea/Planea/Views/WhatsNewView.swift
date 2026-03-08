//
//  WhatsNewView.swift
//  Planea
//
//  Created by Planea on 2026-01-18.
//

import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) var dismiss
    let version: String
    let features: [String]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Title
                Text("whats_new.title".localized)
                    .font(.planeaTitle1)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Version subtitle
                Text(String(format: "whats_new.version".localized, version))
                    .font(.planeaSubheadline)
                    .foregroundColor(.planeaTextSecondary)
                
                // Features list
                VStack(alignment: .leading, spacing: PlaneaSpacing.md) {
                    ForEach(features, id: \.self) { featureKey in
                        HStack(alignment: .top, spacing: PlaneaSpacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.planeaTitle3)
                                .foregroundStyle(.green)
                            
                            Text(featureKey.localized)
                                .font(.planeaBody)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Close button
                Button(action: {
                    WhatsNewService.shared.markVersionAsSeen(version)
                    dismiss()
                }) {
                    Text("whats_new.close".localized)
                        .font(.planeaHeadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        WhatsNewService.shared.markVersionAsSeen(version)
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.planeaTextSecondary)
                    }
                }
            }
        }
    }
}

#Preview {
    WhatsNewView(
        version: "1.2.1",
        features: [
            "whats_new.v1.2.1.feature1",
            "whats_new.v1.2.1.feature2",
            "whats_new.v1.2.1.feature3",
            "whats_new.v1.2.1.feature4"
        ]
    )
}
