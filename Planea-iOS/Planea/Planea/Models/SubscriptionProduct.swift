import Foundation
import StoreKit

/// Subscription product identifiers
enum SubscriptionProduct: String, CaseIterable {
    case monthly = "com.planea.subscription.monthly"
    case yearly = "com.planea.subscription.yearly"
    
    var displayName: String {
        switch self {
        case .monthly:
            return String(localized: "subscription.monthly")
        case .yearly:
            return String(localized: "subscription.yearly")
        }
    }
    
    var description: String {
        switch self {
        case .monthly:
            return String(localized: "subscription.monthly.description")
        case .yearly:
            return String(localized: "subscription.yearly.description")
        }
    }
    
    /// Whether this plan shows a savings badge
    var showsSavings: Bool {
        return self == .yearly
    }
}

/// Represents subscription status
enum SubscriptionStatus {
    case active
    case inTrial
    case expired
    case notSubscribed
    case developerAccess
    
    var isActive: Bool {
        switch self {
        case .active, .inTrial, .developerAccess:
            return true
        case .expired, .notSubscribed:
            return false
        }
    }
}

/// Store for subscription-related information
struct SubscriptionInfo: Equatable {
    var status: SubscriptionStatus
    var expirationDate: Date?
    var product: Product?
    var renewalInfo: Product.SubscriptionInfo.RenewalInfo?
    
    static func == (lhs: SubscriptionInfo, rhs: SubscriptionInfo) -> Bool {
        return lhs.status == rhs.status &&
               lhs.expirationDate == rhs.expirationDate &&
               lhs.product?.id == rhs.product?.id
    }
    
    var daysRemainingInTrial: Int? {
        guard status == .inTrial, let expirationDate = expirationDate else {
            return nil
        }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day
        return max(0, days ?? 0)
    }
    
    var shouldShowTrialReminder: Bool {
        guard let daysRemaining = daysRemainingInTrial else {
            return false
        }
        return daysRemaining <= 7 && daysRemaining > 0
    }
}
