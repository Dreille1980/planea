//
//  ForceUpdateService.swift
//  Planea
//
//  Service to check if app needs a forced update using Firebase Remote Config
//

import Foundation
import UIKit
import FirebaseRemoteConfig
import FirebaseAnalytics
import Combine

class ForceUpdateService: ObservableObject {
    static let shared = ForceUpdateService()
    
    @Published var needsUpdate: Bool = false
    @Published var isChecking: Bool = false
    
    private let remoteConfig: RemoteConfig
    private let minimumVersionKey = "minimum_ios_app_version"
    
    private init() {
        remoteConfig = RemoteConfig.remoteConfig()
        
        // Configure Remote Config settings
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour in production
        
        #if DEBUG
        // In debug, fetch more frequently for testing
        settings.minimumFetchInterval = 0
        #endif
        
        remoteConfig.configSettings = settings
        
        // Set default values
        let defaults: [String: NSObject] = [
            minimumVersionKey: "0.0.0" as NSObject // Very permissive default
        ]
        remoteConfig.setDefaults(defaults)
    }
    
    /// Check if the app needs to be updated
    func checkForUpdate() {
        guard !isChecking else { return }
        
        isChecking = true
        
        // Fetch and activate Remote Config
        remoteConfig.fetch { [weak self] status, error in
            guard let self = self else { return }
            
            if status == .success {
                self.remoteConfig.activate { [weak self] changed, error in
                    guard let self = self else { return }
                    self.evaluateVersion()
                }
            } else {
                // If fetch fails, still evaluate with cached/default values
                print("⚠️ Remote Config fetch failed: \(error?.localizedDescription ?? "unknown error")")
                self.evaluateVersion()
            }
        }
    }
    
    /// Compare current app version with minimum required version
    private func evaluateVersion() {
        defer { isChecking = false }
        
        let minimumVersionValue = remoteConfig.configValue(forKey: minimumVersionKey).stringValue
        let minimumVersion = minimumVersionValue != nil && !minimumVersionValue!.isEmpty ? minimumVersionValue! : "0.0.0"
        let currentVersion = getCurrentAppVersion()
        
        print("📱 Current app version: \(currentVersion)")
        print("📋 Minimum required version: \(minimumVersion)")
        
        let updateNeeded = isVersionLessThan(current: currentVersion, minimum: minimumVersion)
        
        DispatchQueue.main.async {
            self.needsUpdate = updateNeeded
            
            if updateNeeded {
                print("⚠️ UPDATE REQUIRED: App version \(currentVersion) is below minimum \(minimumVersion)")
                
                // Log to Analytics
                Analytics.logEvent("force_update_triggered", parameters: [
                    "current_version": currentVersion,
                    "minimum_version": minimumVersion
                ])
            } else {
                print("✅ App version is up to date")
            }
        }
    }
    
    /// Get current app version from bundle
    private func getCurrentAppVersion() -> String {
        guard let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "0.0.0"
        }
        return version
    }
    
    /// Compare two semantic versions
    /// Returns true if current < minimum
    private func isVersionLessThan(current: String, minimum: String) -> Bool {
        let currentComponents = parseVersion(current)
        let minimumComponents = parseVersion(minimum)
        
        // Compare major
        if currentComponents.major < minimumComponents.major {
            return true
        } else if currentComponents.major > minimumComponents.major {
            return false
        }
        
        // Compare minor
        if currentComponents.minor < minimumComponents.minor {
            return true
        } else if currentComponents.minor > minimumComponents.minor {
            return false
        }
        
        // Compare patch
        return currentComponents.patch < minimumComponents.patch
    }
    
    /// Parse a version string (e.g., "1.2.3") into components
    private func parseVersion(_ version: String) -> (major: Int, minor: Int, patch: Int) {
        let components = version.split(separator: ".").compactMap { Int($0) }
        
        let major = components.count > 0 ? components[0] : 0
        let minor = components.count > 1 ? components[1] : 0
        let patch = components.count > 2 ? components[2] : 0
        
        return (major, minor, patch)
    }
    
    /// Open App Store page for update
    func openAppStore() {
        // Replace with your actual App Store ID
        let appStoreURL = "https://apps.apple.com/app/id6740103773"
        
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
            
            // Log to Analytics
            Analytics.logEvent("force_update_app_store_opened", parameters: nil)
        }
    }
}
