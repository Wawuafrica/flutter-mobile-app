import UIKit
import Flutter
import flutter_local_notifications
import webview_flutter

@main // Updated from @UIApplicationMain (Swift 5.3+)
class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
    // WebView initialization (must come first)
    if #available(iOS 11.0, *) {
      WKWebView.apply()
    }
    
    // Notifications setup
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}