import Foundation

enum SessionType: String, Codable {
    case focus
    case shortBreak
    case longBreak
}

enum SessionStatus: String, Codable {
    case inProgress
    case completed
    case failed
}

struct Session: Identifiable, Codable {
    let id: UUID
    let type: SessionType
    let duration: TimeInterval
    let startTime: Date
    var endTime: Date?
    var status: SessionStatus
    
    init(type: SessionType, duration: TimeInterval) {
        self.id = UUID()
        self.type = type
        self.duration = duration
        self.startTime = Date()
        self.status = .inProgress
    }
    
    init(id: UUID, type: SessionType, duration: TimeInterval, startTime: Date, endTime: Date?, status: SessionStatus) {
        self.id = id
        self.type = type
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
    }
    
    var remainingTime: TimeInterval {
        guard let endTime = endTime else {
            return duration
        }
        return endTime.timeIntervalSince(startTime)
    }
} 