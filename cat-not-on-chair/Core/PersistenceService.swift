import Foundation

// MARK: - PersistenceService Protocol

protocol PersistenceService {
    func saveUserSettings(_ settings: UserSettings)
    func loadUserSettings() -> UserSettings
    func saveSession(_ session: FocusSession)
    func loadSessionHistory() -> [FocusSession]
    func clearSessionHistory()
}

// MARK: - UserDefaultsPersistence

final class UserDefaultsPersistence: PersistenceService {
    private let userSettingsKey = "userSettings"
    private let sessionHistoryKey = "sessionHistory"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func saveUserSettings(_ settings: UserSettings) {
        if let data = try? encoder.encode(settings) {
            UserDefaults.standard.set(data, forKey: userSettingsKey)
        }
    }

    func loadUserSettings() -> UserSettings {
        guard let data = UserDefaults.standard.data(forKey: userSettingsKey),
              let settings = try? decoder.decode(UserSettings.self, from: data) else {
            return UserSettings.default
        }
        return settings
    }

    func saveSession(_ session: FocusSession) {
        var history = loadSessionHistory()
        history.append(session)
        if let data = try? encoder.encode(history) {
            UserDefaults.standard.set(data, forKey: sessionHistoryKey)
        }
    }

    func loadSessionHistory() -> [FocusSession] {
        guard let data = UserDefaults.standard.data(forKey: sessionHistoryKey),
              let history = try? decoder.decode([FocusSession].self, from: data) else {
            return []
        }
        return history
    }

    func clearSessionHistory() {
        UserDefaults.standard.removeObject(forKey: sessionHistoryKey)
    }
} 