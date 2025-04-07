import Foundation
import ActivityKit
import SwiftUI

// Define the attributes in this file to avoid ambiguity
struct TimerAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var timeRemaining: TimeInterval
        var endTime: Date
        var isBreakTime: Bool
    }
}

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var activity: Activity<TimerAttributes>?
    private var updateTimer: Timer?
    
    private init() {}
    
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
            // Use basic version of request that works across iOS versions
            activity = try Activity<TimerAttributes>.request(
                attributes: attributes,
                contentState: contentState
            )
            
            print("Live Activity started successfully with ID: \(activity?.id ?? "unknown")")
            
            // Setup update timer to regularly refresh the widget (every 1 second)
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
            // Use Task to switch back to the MainActor context
            Task { @MainActor [weak self] in
                guard let self = self, let activity = self.activity else { return }
                
                // Calculate current time remaining based on end time
                let currentTimeRemaining = max(0, activity.content.state.endTime.timeIntervalSinceNow)
                
                if currentTimeRemaining > 0 {
                    self.updateLiveActivity(timeRemaining: currentTimeRemaining)
                } else {
                    // Timer completed
                    self.stopLiveActivity()
                }
            }
        }
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
        print("Stopped \(activities.count) Live Activities")
    }
} 