import SwiftUI

struct GeneratingLoadingView: View {
    let totalItems: Int
    @State private var currentMessageIndex = 0
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    let messages = [
        ("🔍", String(localized: "generating.exploring")),
        ("👨‍🍳", String(localized: "generating.chefs")),
        ("🌍", String(localized: "generating.discovering")),
        ("✨", String(localized: "generating.creating")),
        ("🎯", String(localized: "generating.balancing")),
        ("📝", String(localized: "generating.finishing"))
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Animated icon
            ZStack {
                // Rotating background circles
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.accentColor.opacity(0.3), .accentColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(rotation))
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.accentColor.opacity(0.2), .accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-rotation * 1.5))
                
                // Center icon
                Text(messages[currentMessageIndex].0)
                    .font(.system(size: 50))
                    .scaleEffect(scale)
            }
            .frame(height: 140)
            
            // Message
            VStack(spacing: 8) {
                Text(messages[currentMessageIndex].1)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .bottom))
                    ))
                    .id(currentMessageIndex)
                
                Text("\(String(localized: "plan.creating")) \(totalItems) \(String(localized: "plan.meals"))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(height: 60)
            
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<messages.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentMessageIndex ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: index == currentMessageIndex ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentMessageIndex)
                }
            }
            .padding(.top, 8)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 24)
        .onAppear {
            startAnimations()
        }
    }
    
    func startAnimations() {
        // Rotate animation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Scale pulse animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            scale = 1.2
        }
        
        // Message rotation
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                currentMessageIndex = (currentMessageIndex + 1) % messages.count
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        GeneratingLoadingView(totalItems: 7)
    }
}
