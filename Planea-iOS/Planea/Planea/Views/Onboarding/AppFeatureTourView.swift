import SwiftUI

struct AppFeatureTourView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0
    @State private var showInteractiveElements = false
    
    let isOnboarding: Bool
    var onComplete: (() -> Void)?
    
    init(isOnboarding: Bool = true, onComplete: (() -> Void)? = nil) {
        self.isOnboarding = isOnboarding
        self.onComplete = onComplete
    }
    
    private let slides: [TourSlide] = [
        TourSlide(
            icon: "sparkles",
            title: "tour.welcome.title",
            description: "tour.welcome.description",
            color: .planeaPrimary,
            illustration: .welcome
        ),
        TourSlide(
            icon: "calendar",
            title: "tour.mealplans.title",
            description: "tour.mealplans.description",
            color: .planeaTertiary,
            illustration: .mealPlans
        ),
        TourSlide(
            icon: "calendar.badge.checkmark",
            title: "tour.mealprep.title",
            description: "tour.mealprep.description",
            color: .planeaSecondary,
            illustration: .mealPrep
        ),
        TourSlide(
            icon: "wand.and.stars",
            title: "tour.adhoc.title",
            description: "tour.adhoc.description",
            color: .planeaPrimary,
            illustration: .adHoc
        ),
        TourSlide(
            icon: "bubble.left.and.bubble.right.fill",
            title: "tour.aichat.title",
            description: "tour.aichat.description",
            color: .planeaTertiary,
            illustration: .aiChat
        ),
        TourSlide(
            icon: "cart.fill",
            title: "tour.shopping.title",
            description: "tour.shopping.description",
            color: .planeaSecondary,
            illustration: .shopping
        ),
        TourSlide(
            icon: "heart.fill",
            title: "tour.favorites.title",
            description: "tour.favorites.description",
            color: .planeaPrimary,
            illustration: .favorites
        ),
        TourSlide(
            icon: "tag.fill",
            title: "tour.flyers.title",
            description: "tour.flyers.description",
            color: .planeaSecondary,
            illustration: .flyers
        ),
        TourSlide(
            icon: "rocket.fill",
            title: "tour.getstarted.title",
            description: "tour.getstarted.description",
            color: .planeaTertiary,
            illustration: .getStarted
        )
    ]
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [slides[currentPage].color.opacity(0.1), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < slides.count - 1 {
                        Button(action: skipTour) {
                            Text("tour.skip".localized)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                    }
                }
                
                // Carousel
                TabView(selection: $currentPage) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        TourSlideView(
                            slide: slides[index],
                            isActive: currentPage == index,
                            showInteractive: showInteractiveElements
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                // Bottom button
                Button(action: handleNextAction) {
                    Text(currentPage < slides.count - 1 ? "tour.next".localized : "tour.start".localized)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(slides[currentPage].color)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .interactiveDismissDisabled(isOnboarding)
        .onChange(of: currentPage) { _, _ in
            // Animate interactive elements when page changes
            showInteractiveElements = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showInteractiveElements = true
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    showInteractiveElements = true
                }
            }
        }
    }
    
    private func handleNextAction() {
        if currentPage < slides.count - 1 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeTour()
        }
    }
    
    private func skipTour() {
        if isOnboarding {
            // Jump to last slide
            withAnimation {
                currentPage = slides.count - 1
            }
        } else {
            dismiss()
        }
    }
    
    private func completeTour() {
        if isOnboarding {
            onComplete?()
        } else {
            dismiss()
        }
    }
}

// MARK: - Tour Slide Model

struct TourSlide {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let illustration: IllustrationType
    
    enum IllustrationType {
        case welcome, mealPlans, mealPrep, adHoc, aiChat, shopping, favorites, flyers, getStarted
    }
}

// MARK: - Tour Slide View

struct TourSlideView: View {
    let slide: TourSlide
    let isActive: Bool
    let showInteractive: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(slide.color.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: slide.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(slide.color)
            }
            .scaleEffect(isActive && showInteractive ? 1.0 : 0.8)
            .opacity(isActive && showInteractive ? 1.0 : 0.5)
            
            // Illustration area
            illustrationView
                .frame(height: 200)
                .opacity(showInteractive ? 1.0 : 0)
            
            // Title
            Text(slide.title.localized)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .offset(y: showInteractive ? 0 : 20)
            
            // Description
            Text(slide.description.localized)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
                .offset(y: showInteractive ? 0 : 20)
            
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    private var illustrationView: some View {
        switch slide.illustration {
        case .welcome:
            WelcomeIllustration(isActive: isActive)
        case .mealPlans:
            MealPlansIllustration(isActive: isActive)
        case .mealPrep:
            MealPrepIllustration(isActive: isActive)
        case .adHoc:
            AdHocIllustration(isActive: isActive)
        case .aiChat:
            AIChatIllustration(isActive: isActive)
        case .shopping:
            ShoppingIllustration(isActive: isActive)
        case .favorites:
            FavoritesIllustration(isActive: isActive)
        case .flyers:
            FlyersIllustration(isActive: isActive)
        case .getStarted:
            GetStartedIllustration(isActive: isActive)
        }
    }
}

// MARK: - Illustration Components

struct WelcomeIllustration: View {
    let isActive: Bool
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.planeaPrimary.opacity(0.3), lineWidth: 2)
                    .frame(width: CGFloat(80 + i * 30), height: CGFloat(80 + i * 30))
                    .rotationEffect(.degrees(rotation + Double(i * 120)))
            }
            
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color.planeaPrimary)
        }
        .onAppear {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct MealPlansIllustration: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { day in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.planeaTertiary.opacity(0.2))
                        .frame(width: 60, height: 20)
                    
                    ForEach(0..<3) { meal in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.planeaTertiary.opacity(0.6 - Double(meal) * 0.15))
                            .frame(width: 60, height: 40)
                    }
                }
                .scaleEffect(isActive ? 1.0 : 0.9)
                .animation(.spring(response: 0.6).delay(Double(day) * 0.1), value: isActive)
            }
        }
    }
}

struct AdHocIllustration: View {
    let isActive: Bool
    @State private var showCamera = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Text input
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(lineWidth: 2)
                    .foregroundStyle(Color.planeaPrimary.opacity(0.5))
                    .frame(width: 100, height: 80)
                    .overlay(
                        VStack(spacing: 4) {
                            ForEach(0..<3) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.planeaPrimary.opacity(0.3))
                                    .frame(width: 80, height: 8)
                            }
                        }
                    )
                
                Text("text")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Text("ou")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Camera
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.planeaPrimary.opacity(0.2))
                    .frame(width: 100, height: 80)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.planeaPrimary)
                            .scaleEffect(showCamera ? 1.0 : 0.8)
                    )
                
                Text("photo")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                showCamera = true
            }
        }
    }
}

struct ShoppingIllustration: View {
    let isActive: Bool
    @State private var checkedItems: Set<Int> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<4) { index in
                HStack {
                    Image(systemName: checkedItems.contains(index) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(checkedItems.contains(index) ? .planeaTertiary : .gray)
                        .font(.title3)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.planeaSecondary.opacity(0.3))
                        .frame(width: 150, height: 24)
                        .opacity(checkedItems.contains(index) ? 0.5 : 1.0)
                }
                .onTapGesture {
                    withAnimation {
                        if checkedItems.contains(index) {
                            checkedItems.remove(index)
                        } else {
                            checkedItems.insert(index)
                        }
                    }
                }
            }
        }
    }
}

struct FavoritesIllustration: View {
    let isActive: Bool
    @State private var likedItems: Set<Int> = [0, 2]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(0..<6) { index in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.planeaSecondary.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: likedItems.contains(index) ? "heart.fill" : "heart")
                                    .foregroundStyle(likedItems.contains(index) ? .planeaSecondary : .gray)
                                    .font(.title3)
                                    .padding(8)
                            }
                        }
                    )
                    .scaleEffect(isActive ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6).delay(Double(index) * 0.05), value: isActive)
            }
        }
    }
}

struct FlyersIllustration: View {
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                ForEach(0..<3) { index in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.planeaSecondary.opacity(0.3))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "cart.fill")
                                    .foregroundStyle(Color.planeaSecondary)
                            )
                        
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.caption2)
                            Text("-\(25 + index * 10)%")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(Color.planeaDanger)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.planeaDanger.opacity(0.1)))
                    }
                    .scaleEffect(isActive ? 1.0 : 0.9)
                    .animation(.spring(response: 0.6).delay(Double(index) * 0.1), value: isActive)
                }
            }
            
            // Premium badge
            HStack {
                Image(systemName: "star.fill")
                    .font(.caption)
                Text("Premium")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(Color.planeaSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.planeaSecondary.opacity(0.2)))
        }
    }
}

struct MealPrepIllustration: View {
    let isActive: Bool
    @State private var fillProgress: [CGFloat] = [0, 0, 0, 0]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<4) { index in
                VStack(spacing: 4) {
                    // Container with lid
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.planeaSecondary.opacity(0.15))
                            .frame(width: 50, height: 60)
                        
                        // Fill animation
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.planeaSecondary.opacity(0.4))
                            .frame(width: 50, height: 60 * fillProgress[index])
                        
                        // Lid
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.planeaSecondary.opacity(0.6))
                            .frame(width: 54, height: 8)
                            .offset(y: -30)
                    }
                    
                    // Day label
                    Text(["L", "M", "M", "J"][index])
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
                .scaleEffect(isActive ? 1.0 : 0.8)
                .animation(.spring(response: 0.6).delay(Double(index) * 0.15), value: isActive)
            }
        }
        .onAppear {
            if isActive {
                for i in 0..<4 {
                    withAnimation(.easeInOut(duration: 0.8).delay(Double(i) * 0.2)) {
                        fillProgress[i] = 0.7
                    }
                }
            }
        }
    }
}

struct AIChatIllustration: View {
    let isActive: Bool
    @State private var showBubbles: [Bool] = [false, false, false]
    
    var body: some View {
        VStack(spacing: 12) {
            // User bubble (right)
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Text("...")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.planeaTertiary)
                        .cornerRadius(16)
                        .opacity(showBubbles[0] ? 1.0 : 0)
                        .offset(x: showBubbles[0] ? 0 : 20)
                    
                    Circle()
                        .fill(Color.planeaTertiary.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundStyle(Color.planeaTertiary)
                        )
                }
            }
            
            // AI bubble (left)
            HStack {
                Circle()
                    .fill(Color.planeaPrimary.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(Color.planeaPrimary)
                    )
                
                Text("...")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.planeaPrimary)
                    .cornerRadius(16)
                    .opacity(showBubbles[1] ? 1.0 : 0)
                    .offset(x: showBubbles[1] ? 0 : -20)
                
                Spacer()
            }
            
            // User bubble (right)
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Text("...")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.planeaTertiary)
                        .cornerRadius(16)
                        .opacity(showBubbles[2] ? 1.0 : 0)
                        .offset(x: showBubbles[2] ? 0 : 20)
                    
                    Circle()
                        .fill(Color.planeaTertiary.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundStyle(Color.planeaTertiary)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .onAppear {
            if isActive {
                for i in 0..<3 {
                    withAnimation(.easeOut(duration: 0.4).delay(Double(i) * 0.5)) {
                        showBubbles[i] = true
                    }
                }
            }
        }
    }
}

struct GetStartedIllustration: View {
    let isActive: Bool
    @State private var animate = false
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
            Image(systemName: "sparkle")
                .font(.title)
                .foregroundStyle(Color.planeaPrimary)
                .offset(
                        x: animate ? CGFloat.random(in: -40...40) : 0,
                        y: animate ? CGFloat.random(in: -40...40) : 0
                    )
                    .opacity(animate ? 0.3 : 1.0)
            }
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.planeaPrimary)
                .scaleEffect(animate ? 1.2 : 1.0)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

#Preview {
    AppFeatureTourView(isOnboarding: true)
}

#Preview("Non-Onboarding") {
    AppFeatureTourView(isOnboarding: false)
}
