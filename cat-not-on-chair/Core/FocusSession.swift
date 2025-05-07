import Foundation

// MARK: - FocusSessionType

enum FocusSessionType: String, Codable, CaseIterable {
    case focus
    case shortBreak
    case longBreak
}

// MARK: - FocusSessionStatus

enum FocusSessionStatus: String, Codable {
    case running
    case paused
    case stopped
    case completed
    case failed
}

// MARK: - FocusSession

struct FocusSession: Identifiable, Codable {
    let id: UUID
    let type: FocusSessionType
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval { // seconds
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }
    var status: FocusSessionStatus
    var blockingMode: AppBlockingMode

    init(id: UUID = UUID(),
         type: FocusSessionType,
         startTime: Date = Date(),
         endTime: Date? = nil,
         status: FocusSessionStatus = .running,
         blockingMode: AppBlockingMode = .strict) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.blockingMode = blockingMode
    }
}

// MARK: - AppBlockingMode

enum AppBlockingMode: String, Codable, CaseIterable {
    case strict
    case whitelist
    case relax
}

// MARK: - UserSettings

struct UserSettings: Codable {
    var focusDuration: TimeInterval // seconds
    var shortBreakDuration: TimeInterval // seconds
    var longBreakDuration: TimeInterval // seconds
    var blockingMode: AppBlockingMode
    var numberOfShortBreaks: Int

    static let `default` = UserSettings(
        focusDuration: 25 * 60, // 25 minutes
        shortBreakDuration: 5 * 60, // 5 minutes
        longBreakDuration: 15 * 60, // 15 minutes
        blockingMode: .strict,
        numberOfShortBreaks: 4
    )
} 