import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI

@MainActor
final class FamilyControlsManager {
    static let shared = FamilyControlsManager()
    
    private let store = ManagedSettingsStore()
    private let center = AuthorizationCenter.shared
    private var selection: FamilyActivitySelection?
    
    private init() {}
    
    // Check if we have FamilyControls authorization
    func checkAuthorization() -> Bool {
        return center.authorizationStatus == .approved
    }
    
    // Request authorization using the system UI - directly shows system dialog
    func requestAuthorization() async -> Bool {
        do {
            // Request authorization for individual monitoring
            try await center.requestAuthorization(for: .individual)
            
            // Check and log the status immediately after request
            let isAuthorized = center.authorizationStatus == .approved
            print("FamilyControls authorization status: \(center.authorizationStatus.rawValue)")
            
            // If we got approval, initialize selection if needed
            if isAuthorized && selection == nil {
                selection = FamilyActivitySelection()
            }
            
            return isAuthorized
        } catch {
            print("Failed to request FamilyControls authorization: \(error)")
            return false
        }
    }
    
    // Show the activity selection UI and return true if selection was made
    func showActivitySelection() async -> Bool {
        guard checkAuthorization() else {
            return false
        }
        return true
    }
    
    // Update the selection from FamilyActivityPicker
    func setSelection(_ newSelection: FamilyActivitySelection) {
        self.selection = newSelection
    }
    
    // Get the current selection
    func getSelection() -> FamilyActivitySelection? {
        return selection
    }
    
    // Get the saved selection (same as getSelection for now)
    func getSavedSelection() -> FamilyActivitySelection? {
        return selection
    }
    
    // Block apps based on the selected mode
    func blockApps(mode: Any, selection: FamilyActivitySelection?) {
        // First check if we have authorization
        guard center.authorizationStatus == .approved else {
            print("Cannot block apps: FamilyControls authorization not granted")
            return
        }
        
        // Cast to the app's FocusMode type and handle based on the mode
        if let appMode = mode as? FocusMode {
            print("Blocking apps with mode: \(appMode.rawValue)")
            
            switch appMode {
            case .strict:
                // Block all apps
                print("Strict mode: Blocking all apps")
                store.shield.applicationCategories = .all()
                store.shield.webDomainCategories = .all()
                
            case .whitelist:
                print("Whitelist mode: Checking selection")
                if let selection = selection, !selection.applicationTokens.isEmpty {
                    // Allow only selected apps
                    print("Selection has \(selection.applicationTokens.count) apps - only allowing these")
                    
                    // Clear any existing shields first
                    stopBlocking()
                    
                    // Block all apps by category
                    store.shield.applicationCategories = .all()
                    store.shield.webDomainCategories = .all()
                    
                    // Now set up the selected app tokens
                    // When we set applicationCategories to .all() and then set applications to a specific set,
                    // the API interprets this as "block all categories EXCEPT these specific applications"
                    store.shield.applications = selection.applicationTokens
                } else {
                    // If no selection, show warning and don't block
                    print("Warning: No apps selected for whitelist mode")
                    stopBlocking()
                }
                
            case .relax:
                // Do not block any apps
                print("Relax mode: No blocking")
                stopBlocking()
            }
        }
    }
    
    func stopBlocking() {
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
        store.shield.applications = nil
        store.shield.webDomains = nil
    }
} 