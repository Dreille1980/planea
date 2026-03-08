import SwiftUI

struct UsageLimitReachedView: View {
    @Environment(\.dismiss) private var dismiss
    
    let canDismiss: Bool
    let onDismiss: (() -> Void)?
    
    init(canDismiss: Bool = false, onDismiss: (() -> Void)? = nil) {
        self.canDismiss = canDismiss
        self.onDismiss = onDismiss
    }
    
    private var nextResetDate: String {
        let calendar = Calendar.current
        let now = Date()
        
        // Get first day of next month
        var components = calendar.dateComponents([.year, .month], from: now)
        components.month! += 1
        components.day = 1
        
        if let nextMonth = calendar.date(from: components) {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return formatter.string(from: nextMonth)
        }
        
        return ""
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Spacer for top
                    Spacer()
                        .frame(height: 60)
                    
                    // Success Icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green)
                    
                    // Title
                    Text("usage.limit.reached.title".localized)
                        .font(.planeaLargeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Message
                    Text(String(format: "usage.limit.reached.message".localized, nextResetDate))
                        .font(.planeaTitle3)
                        .foregroundColor(.planeaTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    // Divider
                    Divider()
                        .padding(.horizontal, 40)
                    
                    // Info about accessible features
                    VStack(alignment: .leading, spacing: PlaneaSpacing.md) {
                        Text("usage.limit.accessible".localized)
                            .font(.planeaHeadline)
                            .padding(.horizontal)
                        
                        FeatureItem(icon: "calendar", text: "usage.limit.feature.plans".localized)
                        FeatureItem(icon: "cart", text: "usage.limit.feature.shopping".localized)
                        FeatureItem(icon: "heart", text: "usage.limit.feature.favorites".localized)
                        FeatureItem(icon: "clock", text: "usage.limit.feature.history".localized)
                        FeatureItem(icon: "gearshape", text: "usage.limit.feature.settings".localized)
                    }
                    .padding(.vertical)
                    
                    // Action Buttons
                    VStack(spacing: PlaneaSpacing.md) {
                        // Share Button
                        ShareLink(item: "usage.limit.share.message".localized) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("usage.limit.share.button".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                            .fontWeight(.semibold)
                        }
                        .buttonStyle(.plain)
                        
                        // Feedback Button
                        Button(action: sendFeedback) {
                            HStack {
                                Image(systemName: "envelope")
                                Text("usage.limit.feedback.button".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .foregroundColor(.planeaTextPrimary)
                            .cornerRadius(12)
                            .fontWeight(.semibold)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
            
            // Close button (only if dismissible)
            if canDismiss {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            onDismiss?()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.planeaTitle2)
                                .foregroundColor(.planeaTextSecondary)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
        }
    }
    
    private func sendFeedback() {
        let subject = "usage.limit.feedback.subject".localized
        let body = "usage.limit.feedback.body".localized
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(Config.supportEmail)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: PlaneaSpacing.sm) {
            Image(systemName: icon)
                .font(.planeaTitle3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            Text(text)
                .font(.planeaBody)
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    UsageLimitReachedView(canDismiss: true)
}
