import SwiftUI
// import Features
// import Timer
// import Features.Timer.TimerView
// TimerView is now in UI/TimerView.swift and should be accessible if included in the target
#if os(iOS)
import BackgroundTasks
import UserNotifications
import UIKit
#endif

// Import Core services and UI components
struct CatNotOnChairApp: App {
    @Environment(\.scenePhase) private var scenePhase
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif
    
    // Shared services
    @StateObject private var blockModeService = BlockModeService()

    init() {
        #if os(iOS)
        registerBackgroundTasks()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                TabView {
                    TimerView()
                        .environmentObject(blockModeService)
                        .tabItem {
                            Label("Timer", systemImage: "timer")
                        }
                        .tag(1)

                    FocusStatsView()
                        .tabItem {
                            Label("Stats", systemImage: "chart.bar")
                        }
                        .tag(2)
                        
                    SettingsView()
                        .environmentObject(blockModeService)
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag(3)
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            #if os(iOS)
            if newPhase == .background {
                scheduleAppRefresh()
                scheduleBackgroundProcessing()
            }
            #endif
        }
    }

    #if os(iOS)
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ryanyao.catnotonchair.processing", using: nil) { task in
            self.handleBackgroundProcessing(task: task as! BGProcessingTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ryanyao.catnotonchair.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.ryanyao.catnotonchair.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now

        do {
            try BGTaskScheduler.shared.submit(request)
            print("App refresh task scheduled successfully")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    private func scheduleBackgroundProcessing() {
        let request = BGProcessingTaskRequest(identifier: "com.ryanyao.catnotonchair.processing")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background processing task scheduled successfully")
        } catch {
            print("Could not schedule background processing: \(error)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        print("Handling app refresh task")
        task.setTaskCompleted(success: true)
    }

    private func handleBackgroundProcessing(task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        print("Handling background processing task")
        task.setTaskCompleted(success: true)
    }
    #endif
}

#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        registerBackgroundTasks()
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        // LiveActivityManager.shared.updatePushToken(tokenString)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ryanyao.catnotonchair.processing", using: nil) { task in
            self.handleBackgroundProcessing(task: task as! BGProcessingTask)
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ryanyao.catnotonchair.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        print("Handling app refresh task")
        task.setTaskCompleted(success: true)
    }

    private func handleBackgroundProcessing(task: BGProcessingTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }

        print("Handling background processing task")
        task.setTaskCompleted(success: true)
    }
}
#endif

struct FocusTimerView: View {
    var body: some View {
        Text("Timer View")
    }
}

struct FocusStatsView: View {
    var body: some View {
        Text("Stats View")
    }
} 