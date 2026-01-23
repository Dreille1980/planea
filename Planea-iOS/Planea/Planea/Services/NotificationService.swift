import Foundation
import UserNotifications

/// Service responsible for managing local notifications
class NotificationService {
    static let shared = NotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let weeklyReminderIdentifier = "weeklyMealPrepReminder"
    
    private init() {}
    
    // MARK: - Permission Management
    
    /// Request notification permission from the user
    func requestPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error requesting notification permission: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                completion(granted)
            }
        }
    }
    
    /// Check if notification permission is granted
    func checkPermissionStatus(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // MARK: - Weekly Meal Prep Reminder
    
    /// Schedule a weekly meal prep reminder notification
    /// Fires every Saturday at 10:00 AM in the device's local timezone
    func scheduleWeeklyMealPrepReminder() {
        // First, check if we have permission
        checkPermissionStatus { [weak self] isAuthorized in
            guard let self = self else { return }
            
            if !isAuthorized {
                // Request permission if not already granted
                self.requestPermission { granted in
                    if granted {
                        self.createWeeklyReminder()
                    } else {
                        print("Notification permission denied")
                    }
                }
            } else {
                // Already have permission, create reminder
                self.createWeeklyReminder()
            }
        }
    }
    
    /// Internal method to create the weekly reminder notification
    private func createWeeklyReminder() {
        // Cancel any existing reminder first
        cancelWeeklyMealPrepReminder()
        
        // Get a random message body (for future expansion with multiple messages)
        let bodyKey = getRandomMessageBodyKey()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "notification.mealprep.title".localized
        content.body = bodyKey.localized
        content.sound = .default
        content.badge = 0 // No badge
        
        // Add custom data for deep linking
        content.userInfo = ["action": "openRecipesTab"]
        
        // Create trigger: Every Saturday at 10:00 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 7 // Saturday (1 = Sunday, 7 = Saturday)
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: weeklyReminderIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling weekly reminder: \(error.localizedDescription)")
            } else {
                print("Weekly meal prep reminder scheduled successfully")
                // Log to Analytics
                AnalyticsService.shared.logNotificationEnabled(type: "weekly_meal_prep")
            }
        }
    }
    
    /// Cancel the weekly meal prep reminder
    func cancelWeeklyMealPrepReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [weeklyReminderIdentifier])
        print("Weekly meal prep reminder cancelled")
        
        // Log to Analytics
        AnalyticsService.shared.logNotificationDisabled(type: "weekly_meal_prep")
    }
    
    /// Get a random message body key (supports multiple message variants in the future)
    private func getRandomMessageBodyKey() -> String {
        // Currently only one message, but structured to support multiple variants
        let messageKeys = [
            "notification.mealprep.body.1"
            // Future: add more keys like "notification.mealprep.body.2", etc.
        ]
        return messageKeys.randomElement() ?? "notification.mealprep.body.1"
    }
    
    // MARK: - Debug Helpers
    
    /// Get all pending notification requests (useful for debugging)
    func listPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
    
    /// Remove all pending notifications
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("All pending notifications removed")
    }
}
