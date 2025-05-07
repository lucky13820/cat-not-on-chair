import Foundation
import Combine
import ActivityKit

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
    @Published var isStrictMode: Bool = true // For blocking mode
    
    // MARK: - Timer Config
    var focusDuration: TimeInterval = 25 * 60 // 25 min default
    var shortBreakDuration: TimeInterval = 5 * 60 // 5 min default
    var longBreakDuration: TimeInterval = 15 * 60 // 15 min default
    var sessionsBeforeLongBreak: Int = 4
    
    // MARK: - Private
    private var timerTask: Task<Void, Never>?
    private var completedFocusSessions = 0
    private var activity: Activity<PomodoroActivityAttributes>?
    private var blockModeService: BlockModeService
    
    // MARK: - Initialization
    
    init(blockModeService: BlockModeService = BlockModeService()) {
        self.blockModeService = blockModeService
    }
    
    // MARK: - Public Methods
    func start() {
        switch sessionType {
        case .focus:
            totalTime = focusDuration
            // Enable block mode if it's a focus session
            if blockModeService.isBlockModeEnabled {
                blockModeService.startBlocking()
            }
        case .shortBreak:
            totalTime = shortBreakDuration
        case .longBreak:
            totalTime = longBreakDuration
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
        
        // Disable block mode when timer is stopped
        if blockModeService.isCurrentlyBlocking {
            blockModeService.stopBlocking()
        }
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
        // If we're finishing a focus session, stop blocking mode
        if sessionType == .focus && blockModeService.isCurrentlyBlocking {
            blockModeService.stopBlocking()
        }
        
        if sessionType == .focus {
            completedFocusSessions += 1
            if completedFocusSessions % sessionsBeforeLongBreak == 0 {
                sessionType = .longBreak
            } else {
                sessionType = .shortBreak
            }
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
            print("Failed to start Live Activity: \\(error)")
        }
    }
    
    func updateLiveActivity() {
        let contentState = PomodoroActivityAttributes.ContentState(
            remainingTime: remainingTime,
            sessionType: sessionTypeText
        )
        Task {
            await activity?.update(using: contentState)
        }
    }
    
    func endLiveActivity() {
        Task {
            await activity?.end(dismissalPolicy: .immediate)
        }
    }
    
    private var sessionTypeText: String {
        switch sessionType {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }
} 