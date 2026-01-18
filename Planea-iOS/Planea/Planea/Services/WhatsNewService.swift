//
//  WhatsNewService.swift
//  Planea
//
//  Created by Planea on 2026-01-18.
//

import Foundation
import SwiftUI

/// Service to manage "What's New" feature display
class WhatsNewService {
    static let shared = WhatsNewService()
    
    private let lastSeenVersionKey = "lastSeenWhatsNewVersion"
    
    private init() {}
    
    /// Check if the What's New screen should be shown for the given version
    func shouldShowWhatsNew(for version: String) -> Bool {
        let lastSeenVersion = UserDefaults.standard.string(forKey: lastSeenVersionKey)
        
        // Show if no version has been seen, or if the current version is different
        if lastSeenVersion == nil || lastSeenVersion != version {
            return true
        }
        
        return false
    }
    
    /// Mark the version as seen
    func markVersionAsSeen(_ version: String) {
        UserDefaults.standard.set(version, forKey: lastSeenVersionKey)
    }
    
    /// Get the current app version
    func getCurrentVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }
    
    /// Get what's new items for a specific version
    func getWhatsNewItems(for version: String) -> [String] {
        // Always return version 1.2.1 features for now
        // This can be updated when new versions are released
        return [
            "whats_new.v1.2.1.feature1",
            "whats_new.v1.2.1.feature2",
            "whats_new.v1.2.1.feature3",
            "whats_new.v1.2.1.feature4"
        ]
    }
}
