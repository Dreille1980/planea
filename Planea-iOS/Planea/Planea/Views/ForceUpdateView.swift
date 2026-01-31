//
//  ForceUpdateView.swift
//  Planea
//
//  Full-screen view shown when app needs a forced update
//

import SwiftUI

struct ForceUpdateView: View {
    @ObservedObject var forceUpdateService = ForceUpdateService.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.planeaPrimary.opacity(0.1),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Icon
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.planeaPrimary)
                
                // Title
                Text("force_update.title".localized)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.planeaTextPrimary)
                    .padding(.horizontal, 40)
                
                // Message
                Text("force_update.message".localized)
                    .font(.system(size: 17))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.planeaTextSecondary)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
                
                Spacer()
                
                // Update button
                Button(action: {
                    forceUpdateService.openAppStore()
                }) {
                    HStack {
                        Image(systemName: "arrow.down.app.fill")
                            .font(.system(size: 18, weight: .semibold))
                        
                        Text("force_update.button".localized)
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.planeaPrimary)
                    .cornerRadius(12)
                    .shadow(color: Color.planeaPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
        .interactiveDismissDisabled() // Prevent dismissal
    }
}

#Preview {
    ForceUpdateView()
}
