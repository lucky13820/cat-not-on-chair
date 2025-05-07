import Foundation
import Combine

#if canImport(ActivityKit)
import ActivityKit
#endif

#if canImport(FamilyControls)
import FamilyControls
#endif

// Import local files using the Swift module structure
// The BlockingMode enum is available because it's in the same module

// MARK: - Timer State & Session Type

public enum PomodoroSessionType: String, Codable {
    case focus
    case shortBreak
    case longBreak
}

public enum PomodoroTimerState: String, Codable {
    case idle
    case running
    case paused
    case finished
    case failed
}

// MARK: - ViewModel

@MainActor
public final class PomodoroTimerViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var timerState: PomodoroTimerState = .idle
    @Published private(set) var sessionType: PomodoroSessionType = .focus
    @Published private(set) var remainingTime: TimeInterval = 0
    @Published private(set) var totalTime: TimeInterval = 0
    @Published var blockingMode: BlockingMode {
        didSet {
            AppBlockingService.shared.blockingMode = blockingMode
        }
    }
    
    // MARK: - Timer Config
    var focusDuration: TimeInterval = 25 * 60 // 25 min default
    var shortBreakDuration: TimeInterval = 5 * 60 // 5 min default
    var longBreakDuration: TimeInterval = 15 * 60 // 15 min default
    var sessionsBeforeLongBreak: Int = 4
    
    // MARK: - Private
    private var timerTask: Task<Void, Never>?
    private var completedFocusSessions = 0
    #if canImport(ActivityKit)
    private var activity: Activity<PomodoroActivityAttributes>?
    #endif
    private let appBlockingService = AppBlockingService.shared

    // MARK: - Initialization
    
    init() {
        self.blockingMode = appBlockingService.blockingMode
        setupBlockingMode()
    }
    
    private func setupBlockingMode() {
        // Synchronize view model with service
        appBlockingService.blockingMode = blockingMode
    }
    
    // MARK: - Public Methods
    func start() {
        switch sessionType {
        case .focus:
            totalTime = focusDuration
            // Start app blocking if in focus mode
            Task {
                await appBlockingService.startBlocking()
            }
        case .shortBreak:
            totalTime = shortBreakDuration
            // Disable app blocking during breaks
            appBlockingService.stopBlocking()
        case .longBreak:
            totalTime = longBreakDuration
            // Disable app blocking during breaks
            appBlockingService.stopBlocking()
        }
        remainingTime = totalTime
        timerState = .running
        startTimer()
        startLiveActivity()
    }
    
    func stop() {
        timerTask?.cancel()
        timerTask = nil
        if timerState == .running && sessionType == .focus {
            timerState = .failed // Focus session interrupted
        } else {
            timerState = .idle
        }
        endLiveActivity()
        
        // Remove app blocking when stopping the timer
        appBlockingService.stopBlocking()
    }
    
    func reset() {
        stop()
        remainingTime = totalTime
        timerState = .idle
    }
    
    func skipBreak() {
        if sessionType != .focus {
            nextSession()
        }
    }
    
    // App Selection for whitelist mode
    func selectAllowedApps() async {
        await appBlockingService.selectApps()
    }
    
    // Check if we have family controls permission
    func hasFamilyControlsPermission() -> Bool {
        return appBlockingService.hasPermission
    }
    
    func requestFamilyControlsPermission() async -> Bool {
        return await appBlockingService.requestAuthorization()
    }
    
    // MARK: - Private Methods
    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            guard let self = self else { return }
            let startDate = Date()
            while self.remainingTime > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let elapsed = Date().timeIntervalSince(startDate)
                self.remainingTime = max(self.totalTime - elapsed, 0)
                if self.remainingTime == 0 {
                    self.timerState = .finished
                    self.handleSessionCompletion()
                }
                self.updateLiveActivity()
            }
        }
    }
    
    private func handleSessionCompletion() {
        if sessionType == .focus {
            completedFocusSessions += 1
            if completedFocusSessions % sessionsBeforeLongBreak == 0 {
                sessionType = .longBreak
            } else {
                sessionType = .shortBreak
            }
            // Disable app blocking after focus session
            appBlockingService.stopBlocking()
        } else {
            sessionType = .focus
        }
        timerState = .idle
        endLiveActivity()
        // Optionally: Save session result to persistence here
    }
    
    private func nextSession() {
        handleSessionCompletion()
    }
    
    func startLiveActivity() {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            let attributes = PomodoroActivityAttributes(
                totalTime: totalTime,
                sessionType: sessionTypeText
            )
            let contentState = PomodoroActivityAttributes.ContentState(
                remainingTime: remainingTime,
                sessionType: sessionTypeText
            )
            do {
                activity = try Activity<PomodoroActivityAttributes>.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
            } catch {
                print("Failed to start Live Activity: \(error)")
            }
        }
        #endif
    }
    
    func updateLiveActivity() {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            let contentState = PomodoroActivityAttributes.ContentState(
                remainingTime: remainingTime,
                sessionType: sessionTypeText
            )
            Task {
                await activity?.update(using: contentState)
            }
        }
        #endif
    }
    
    func endLiveActivity() {
        #if canImport(ActivityKit)
        if #available(iOS 16.2, *) {
            Task {
                await activity?.end(dismissalPolicy: .immediate)
            }
        }
        #endif
    }
    
    private var sessionTypeText: String {
        switch sessionType {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
} 