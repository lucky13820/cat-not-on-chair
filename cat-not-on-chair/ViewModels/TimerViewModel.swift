import Foundation
import Combine
import FamilyControls
import DeviceActivity
import UIKit
import BackgroundTasks
import ActivityKit

@MainActor
class TimerViewModel: ObservableObject {
    @Published var currentSession: Session?
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning = false
    @Published var focusMode: FocusMode = .relax
    @Published var activitySelection: FamilyActivitySelection?
    
    private var timer: Timer?
    private var _focusDuration: TimeInterval = 25 * 60 // 25 minutes
    private var _breakDuration: TimeInterval = 5 * 60 // 5 minutes
    private let familyControlsManager = FamilyControlsManager.shared
    private let liveActivityManager = LiveActivityManager.shared
    private var sessionEndTime: Date?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    var focusDuration: TimeInterval {
        get { _focusDuration }
        set { _focusDuration = newValue }
    }
    
    var breakDuration: TimeInterval {
        get { _breakDuration }
        set { _breakDuration = newValue }
    }
    
    init() {
        setupNotificationObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotificationObservers() {
        // Register for app state notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appWillResignActive() {
        print("App will resign active")
        // Cancel the foreground timer
        timer?.invalidate()
        
        // Start Live Activity if we have an active session
        if isRunning, let session = currentSession {
            let isBreakTime = session.type != .focus
            sessionEndTime = calculateEndTime(from: timeRemaining)
            
            // First stop any existing activities
            liveActivityManager.stopAllLiveActivities()
            
            // Then start a new one
            liveActivityManager.startLiveActivity(
                isBreakTime: isBreakTime, 
                timeRemaining: timeRemaining, 
                endTime: sessionEndTime!
            )
        }
    }
    
    @objc private func appDidEnterBackground() {
        print("App entered background")
        // Register background task
        registerBackgroundTask()
    }
    
    @objc private func appWillEnterForeground() {
        print("App will enter foreground")
        // End the background task if it's active
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    @objc private func appDidBecomeActive() {
        print("App became active")
        // Update timeRemaining based on the elapsed time if session is active
        if isRunning, let endTime = sessionEndTime {
            let now = Date()
            let newTimeRemaining = max(0, endTime.timeIntervalSince(now))
            
            // If timer reached zero while in background
            if newTimeRemaining <= 0 {
                completeSession()
            } else {
                timeRemaining = newTimeRemaining
                
                // Update any existing Live Activities with the correct time
                if let session = currentSession {
                    let isBreakTime = session.type != .focus
                    liveActivityManager.updateAllLiveActivities(
                        timeRemaining: newTimeRemaining,
                        isBreakTime: isBreakTime
                    )
                }
                
                startTimer() // Restart the foreground timer
            }
        }
        
        // Don't immediately stop the Live Activity when returning to foreground
        // This allows the user to see the activity in the app and have a smoother transition
        // It will be updated with the current time by the code above
    }
    
    private func registerBackgroundTask() {
        // End any existing background task
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }
        
        // Start a new background task
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            // Time expired, end the task
            guard let self = self else { return }
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }
    }
    
    private func calculateEndTime(from remaining: TimeInterval) -> Date {
        return Date().addingTimeInterval(remaining)
    }
    
    func startFocusSession() {
        let newSession = Session(type: .focus, duration: focusDuration)
        currentSession = newSession
        timeRemaining = focusDuration
        isRunning = true
        sessionEndTime = calculateEndTime(from: focusDuration)
        
        // Enable app blocking based on the selected focus mode
        if familyControlsManager.checkAuthorization() {
            familyControlsManager.blockApps(mode: focusMode, selection: activitySelection)
        }
        
        startTimer()
    }
    
    func startBreakSession() {
        let newSession = Session(type: .shortBreak, duration: breakDuration)
        currentSession = newSession
        timeRemaining = breakDuration
        isRunning = true
        sessionEndTime = calculateEndTime(from: breakDuration)
        
        // Don't block apps during break time
        familyControlsManager.stopBlocking()
        
        startTimer()
    }
    
    func stopSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        sessionEndTime = nil
        
        // Stop all Live Activities
        liveActivityManager.stopAllLiveActivities()
        
        // Stop app blocking
        familyControlsManager.stopBlocking()
        
        if let session = currentSession {
            let newStatus: SessionStatus = session.type == .focus ? .failed : .completed
            let updatedSession = Session(
                id: session.id,
                type: session.type,
                duration: session.duration,
                startTime: session.startTime,
                endTime: Date(),
                status: newStatus
            )
            currentSession = updatedSession
            FocusSessionManager.shared.addSession(updatedSession)
        }
    }
    
    private func completeSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        sessionEndTime = nil
        
        // Stop all Live Activities
        liveActivityManager.stopAllLiveActivities()
        
        // Stop app blocking
        familyControlsManager.stopBlocking()
        
        if let session = currentSession {
            let updatedSession = Session(
                id: session.id,
                type: session.type,
                duration: session.duration,
                startTime: session.startTime,
                endTime: Date(),
                status: .completed
            )
            currentSession = updatedSession
            FocusSessionManager.shared.addSession(updatedSession)
        }
    }
    
    func selectAppsForWhitelist() async {
        if focusMode == .whitelist {
            if await familyControlsManager.showActivitySelection() {
                activitySelection = familyControlsManager.getSavedSelection()
            }
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    
                    // Update Live Activity if app is in background
                    if UIApplication.shared.applicationState != .active {
                        self.liveActivityManager.updateLiveActivity(timeRemaining: self.timeRemaining)
                    }
                } else {
                    self.completeSession()
                }
            }
        }
    }
    
    func setFocusDuration(minutes: Int) {
        focusDuration = TimeInterval(minutes * 60)
    }
    
    func setBreakDuration(minutes: Int) {
        breakDuration = TimeInterval(minutes * 60)
    }
    
    // Update activitySelection with a new selection from the FamilyActivityPicker
    func updateActivitySelection(_ selection: FamilyActivitySelection) {
        print("Updating activity selection with \(selection.applicationTokens.count) apps")
        
        // Store the selection in the view model
        activitySelection = selection
        
        // Also update in the manager
        familyControlsManager.setSelection(selection)
        
        // If we're currently running in whitelist mode, apply the changes immediately
        if isRunning && focusMode == .whitelist {
            print("Reapplying app blocking with new selection")
            familyControlsManager.blockApps(mode: focusMode, selection: selection)
        }
    }
    
    // Apply the current focus mode's blocking settings
    func applyCurrentModeBlocking() {
        if isRunning {
            print("Applying blocking for mode: \(focusMode.rawValue)")
            if familyControlsManager.checkAuthorization() {
                familyControlsManager.blockApps(mode: focusMode, selection: activitySelection)
            }
        }
    }
} 