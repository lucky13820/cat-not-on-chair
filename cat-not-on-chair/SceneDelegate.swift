import UIKit
import BackgroundTasks

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        let timerVC = TimerViewController()
        timerVC.tabBarItem = UITabBarItem(title: "Timer", image: UIImage(systemName: "timer"), tag: 0)
        
        let statsVC = StatsViewController()
        statsVC.tabBarItem = UITabBarItem(title: "Stats", image: UIImage(systemName: "chart.bar"), tag: 1)
        
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [timerVC, statsVC]
        
        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()
        
        // Register for background processing tasks
        registerBackgroundTasks()
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.ryanyao.catnotonchair.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        // Schedule a new refresh task
        scheduleAppRefresh()
        
        // Create a task request that expires after 30 seconds
        let taskExpirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Add the expiration handler
        task.expirationHandler = taskExpirationHandler
        
        // Mark the task complete
        task.setTaskCompleted(success: true)
    }
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.ryanyao.catnotonchair.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        scheduleAppRefresh()
    }
} 