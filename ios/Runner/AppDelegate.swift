import Flutter
import UIKit
import UserNotifications
import workmanager
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
    }
    
    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.register(forTaskWithIdentifier: "uv_refresh_task_ios", using: nil) { task in
        self.handleAppRefresh(task: task as! BGAppRefreshTask)
      }
      scheduleAppRefresh()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  @available(iOS 13.0, *)
  private func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "uv_refresh_task_ios")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
    do {
      try BGTaskScheduler.shared.submit(request)
      print("[AppDelegate] BGAppRefreshTask scheduled successfully")
    } catch {
      print("[AppDelegate] Could not schedule BGAppRefreshTask: \(error.localizedDescription)")
    }
  }
  
  @available(iOS 13.0, *)
  private func handleAppRefresh(task: BGAppRefreshTask) {
    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }
    
    scheduleAppRefresh()
    
    task.setTaskCompleted(success: true)
  }
}
