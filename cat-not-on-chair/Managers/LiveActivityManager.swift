import Foundation
import ActivityKit
import SwiftUI
import Combine

// Define the attributes here to avoid ambiguity
struct TimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
        var endTime: Date
        var isBreakTime: Bool
    }
}

@MainActor
final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    @Published private(set) var isActivityRunning = false
    
    private var activity: Activity<TimerAttributes>?
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Set up app state monitoring
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in self?.appDidEnterBackground() }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.appWillEnterForeground() }
            .store(in: &cancellables)
    }
    
    private func appDidEnterBackground() {
        // When app enters background, make sure update timer keeps running
        if updateTimer != nil {
            DispatchQueue.main.async {
                self.startUpdateTimer()
            }
        }
    }
    
    private func appWillEnterForeground() {
        // App returning to foreground - might need to recalculate things
        if let activity = activity {
            let timeRemaining = max(0, activity.content.state.endTime.timeIntervalSinceNow)
            if timeRemaining > 0 {
                updateLiveActivity(timeRemaining: timeRemaining)
            } else {
                stopLiveActivity()
            }
        }
    }
    
    func startLiveActivity(isBreakTime: Bool, timeRemaining: TimeInterval, endTime: Date) {
        // Check if Activity is supported on this device
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities not supported on this device")
            return
        }
        
        // Stop any existing activity first
        stopLiveActivity()
        
        // Create the activity content state
        let contentState = TimerAttributes.ContentState(
            timeRemaining: timeRemaining,
            endTime: endTime,
            isBreakTime: isBreakTime
        )
        
        // Create the activity attributes
        let attributes = TimerAttributes()
        
        do {
            // Use the simplest API that works across iOS versions
            activity = try Activity<TimerAttributes>.request(
                attributes: attributes,
                contentState: contentState
            )
            
            isActivityRunning = true
            print("Live Activity started successfully with ID: \(activity?.id ?? "unknown")")
            
            // Setup update timer to regularly refresh the widget
            startUpdateTimer()
            
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    private func startUpdateTimer() {
        // Stop existing timer if any
        updateTimer?.invalidate()
        
        // Create a new timer that fires every second to update the activity
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let activity = self.activity else { return }
                
                // Calculate current time remaining based on end time
                let currentTimeRemaining = max(0, activity.content.state.endTime.timeIntervalSinceNow)
                
                if currentTimeRemaining > 0 {
                    // Only update every few seconds to reduce overhead
                    if Int(currentTimeRemaining) % 3 == 0 || currentTimeRemaining < 10 {
                        self.updateLiveActivity(timeRemaining: currentTimeRemaining)
                    }
                } else {
                    // Timer completed
                    self.stopLiveActivity()
                }
            }
        }
        
        // Make sure timer runs when app is in background
        RunLoop.current.add(updateTimer!, forMode: .common)
    }
    
    func updateLiveActivity(timeRemaining: TimeInterval) {
        guard let activity = activity else { 
            print("No active Live Activity to update")
            return
        }
        
        Task {
            // Update with new time remaining
            let updatedState = TimerAttributes.ContentState(
                timeRemaining: timeRemaining,
                endTime: activity.content.state.endTime,
                isBreakTime: activity.content.state.isBreakTime
            )
            
            await activity.update(using: updatedState)
            print("Live Activity updated: \(timeRemaining) seconds remaining")
        }
    }
    
    func stopLiveActivity() {
        guard let activity = activity else { return }
        
        // Stop the update timer
        updateTimer?.invalidate()
        updateTimer = nil
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            self.activity = nil
            isActivityRunning = false
            print("Live Activity ended successfully")
        }
    }
    
    // Get all current Live Activities for this app
    func getAllLiveActivities() -> [Activity<TimerAttributes>] {
        return Activity<TimerAttributes>.activities
    }
    
    // Update all Live Activities at once (useful when app comes back to foreground)
    func updateAllLiveActivities(timeRemaining: TimeInterval, isBreakTime: Bool) {
        let activities = getAllLiveActivities()
        
        if activities.isEmpty {
            print("No active Live Activities found to update")
            return
        }
        
        for activity in activities {
            Task {
                let updatedState = TimerAttributes.ContentState(
                    timeRemaining: timeRemaining,
                    endTime: Date().addingTimeInterval(timeRemaining),
                    isBreakTime: isBreakTime
                )
                
                await activity.update(using: updatedState)
            }
        }
        
        print("Updated \(activities.count) Live Activities")
    }
    
    // End all Live Activities
    func stopAllLiveActivities() {
        let activities = getAllLiveActivities()
        
        for activity in activities {
            Task {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
        
        // Stop the update timer
        updateTimer?.invalidate()
        updateTimer = nil
        
        self.activity = nil
        isActivityRunning = false
        print("Stopped \(activities.count) Live Activities")
    }
} 