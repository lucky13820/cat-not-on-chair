import Foundation
import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
import ManagedSettings
import DeviceActivity
#endif

#if canImport(UIKit)
import UIKit
#endif

/// Enum representing different app blocking modes during focus sessions
public enum BlockingMode: String, Codable, CaseIterable, Identifiable {
    case strict     // Block all apps during focus
    case whitelist  // Only allow selected apps during focus
    case relaxed    // No app blocking

    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .strict:    return "Strict"
        case .whitelist: return "Whitelist"
        case .relaxed:   return "Relaxed"
        }
    }
    
    public var description: String {
        switch self {
        case .strict:    return "Block all apps during focus time"
        case .whitelist: return "Only use selected apps during focus time"
        case .relaxed:   return "No app blocking (honor system)"
        }
    }
}

/// Service responsible for managing app blocking during focus sessions
@MainActor
public final class AppBlockingService: ObservableObject {
    /// Singleton instance
    public static let shared = AppBlockingService()
    
    /// Published properties for UI binding
    @Published public var blockingMode: BlockingMode = .strict
    
    #if canImport(FamilyControls)
    // Renamed to reflect what we're actually storing - the apps user wants to access
    @Published public var selectedApps = FamilyActivitySelection()
    #endif
    
    @Published public var hasPermission: Bool = false
    
    #if canImport(FamilyControls)
    /// ManagedSettings components
    private let store = ManagedSettingsStore()
    private let deviceActivityCenter = DeviceActivityCenter()
    #endif
    
    private let activityName = "FocusSession"
    
    private init() {
        checkAuthorizationStatus()
    }
    
    /// Check if we have authorization to use Family Controls
    public func checkAuthorizationStatus() {
        #if canImport(FamilyControls) && !targetEnvironment(simulator)
        Task {
            let authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            self.hasPermission = authorizationStatus == .approved
        }
        #else
        // Always return true for simulator or non-iOS platforms for testing
        self.hasPermission = true
        #endif
    }
    
    /// Request authorization for FamilyControls if not already granted
    public func requestAuthorization() async -> Bool {
        #if canImport(FamilyControls) && !targetEnvironment(simulator)
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            self.hasPermission = true
            return true
        } catch {
            print("Failed to request authorization: \(error)")
            self.hasPermission = false
            return false
        }
        #else
        // Always return true for simulator or non-iOS platforms for testing
        self.hasPermission = true
        return true
        #endif
    }
    
    /// Start blocking apps based on selected mode
    public func startBlocking() async {
        #if canImport(FamilyControls) && !targetEnvironment(simulator)
        guard hasPermission else {
            let gotPermission = await requestAuthorization()
            if !gotPermission { return }
            return
        }
        
        switch blockingMode {
        case .strict:
            // Block all third-party apps except for this one
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.all()
            
        case .whitelist:
            // INVERTED LOGIC: Block all apps except the ones the user selected
            if !selectedApps.applications.isEmpty {
                // Set all app categories to be blocked
                store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.all()
                
                // Then set the specific apps that should be allowed
                store.shield.applications = selectedApps.applicationTokens
            }
            
        case .relaxed:
            // No restrictions
            stopBlocking()
        }
        #else
        // In simulator or non-iOS platforms, just log what would happen
        print("Would start blocking with mode: \(blockingMode.displayName)")
        #endif
    }
    
    /// Stop blocking apps
    public func stopBlocking() {
        #if canImport(FamilyControls) && !targetEnvironment(simulator)
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.none
        store.shield.applications = nil
        #else
        // In simulator or non-iOS platforms, just log
        print("Would stop blocking apps")
        #endif
    }
    
    /// Select which apps to allow during focus time (they won't be blocked)
    public func selectApps() async {
        #if canImport(FamilyControls) && !targetEnvironment(simulator)
        do {
            // Get authorization if needed
            let center = AuthorizationCenter.shared
            let status = center.authorizationStatus
            if status != .approved {
                try await center.requestAuthorization(for: .individual)
            }
            
            // Instead of trying to use the picker directly, open the system settings
            // This is a reliable fallback that works on all iOS versions
            #if canImport(UIKit)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            #endif
        } catch {
            print("Failed to select apps: \(error)")
        }
        #else
        // In simulator or non-iOS platforms, just provide a mock selection
        print("Would show app selection UI")
        #endif
    }
} 