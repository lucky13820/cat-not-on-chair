import Foundation
import UIKit

@MainActor
final class FocusSessionManager: Sendable {
    static let shared = FocusSessionManager()
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "focusSessions"
    
    private init() {}
    
    private var sessions: [Session] {
        get {
            guard let data = userDefaults.data(forKey: sessionsKey),
                  let decodedSessions = try? JSONDecoder().decode([Session].self, from: data) else {
                return []
            }
            return decodedSessions
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                userDefaults.set(encoded, forKey: sessionsKey)
            }
        }
    }
    
    func addSession(_ session: Session) {
        var currentSessions = sessions
        currentSessions.append(session)
        sessions = currentSessions
    }
    
    func getSessions(for date: Date) -> [Session] {
        let calendar = Calendar.current
        return sessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: date)
        }
    }
    
    func getWeeklyStats() -> (totalSessions: Int, completedSessions: Int, failedSessions: Int) {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let weeklySessions = sessions.filter { $0.startTime >= weekAgo }
        let completed = weeklySessions.filter { $0.status == .completed }.count
        let failed = weeklySessions.filter { $0.status == .failed }.count
        
        return (weeklySessions.count, completed, failed)
    }
    
    func getMonthlyStats() -> (totalSessions: Int, completedSessions: Int, failedSessions: Int) {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        let monthlySessions = sessions.filter { $0.startTime >= monthAgo }
        let completed = monthlySessions.filter { $0.status == .completed }.count
        let failed = monthlySessions.filter { $0.status == .failed }.count
        
        return (monthlySessions.count, completed, failed)
    }
    
    func getSessionCountByDay(forPastDays days: Int) async -> [(Date, Int)] {
        let calendar = Calendar.current
        let now = Date()
        var result: [(Date, Int)] = []
        
        for dayOffset in 0..<days {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let daySessions = sessions.filter { session in
                session.startTime >= dayStart && session.startTime < dayEnd
            }
            
            result.append((dayStart, daySessions.count))
        }
        
        return result
    }
} 