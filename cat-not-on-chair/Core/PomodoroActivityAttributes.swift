import ActivityKit
import Foundation

public struct PomodoroActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var remainingTime: TimeInterval
        public var sessionType: String // "Focus", "Short Break", etc.
        
        public init(remainingTime: TimeInterval, sessionType: String) {
            self.remainingTime = remainingTime
            self.sessionType = sessionType
        }
    }

    public var totalTime: TimeInterval
    public var sessionType: String
    
    public init(totalTime: TimeInterval, sessionType: String) {
        self.totalTime = totalTime
        self.sessionType = sessionType
    }
}