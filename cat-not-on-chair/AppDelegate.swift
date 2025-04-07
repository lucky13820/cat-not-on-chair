// @ts-ignore
import UIKit
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let timerVC = TimerViewController()
        timerVC.tabBarItem = UITabBarItem(title: "Timer", image: UIImage(systemName: "timer"), tag: 0)
        
        let statsVC = StatsViewController()
        statsVC.tabBarItem = UITabBarItem(title: "Stats", image: UIImage(systemName: "chart.bar"), tag: 1)
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [timerVC, statsVC]
        
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
        
        // Register for background tasks
        registerBackgroundTasks()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Schedule background tasks
        scheduleBackgroundProcessing()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from background to active state
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused while the app was inactive
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ryanyao.catnotonchair.processing", using: nil) { task in
            self.handleBackgroundProcessing(task: task as! BGProcessingTask)
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
    
    private func handleBackgroundProcessing(task: BGProcessingTask) {
        // Schedule a new processing task
        scheduleBackgroundProcessing()
        
        // Create an expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform the background work here
        
        // Mark the task complete
        task.setTaskCompleted(success: true)
    }
} 