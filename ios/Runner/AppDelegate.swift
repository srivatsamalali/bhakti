import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(name: "com.bhakti.devotional/notifications", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] (call, callResult) in
        if call.method == "showNativeNotification" {
          guard let args = call.arguments as? [String: Any],
                let title = args["title"] as? String,
                let body = args["body"] as? String else {
            callResult(FlutterError(code: "INVALID_ARGS", message: "Missing title or body", details: nil))
            return
          }
          self?.scheduleNativeNotification(title: title, body: body)
          callResult(true)
        } else if call.method == "requestNativePermissions" {
          if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
              callResult(granted)
            }
          } else {
            callResult(true)
          }
        } else {
          callResult(FlutterMethodNotImplemented)
        }
      }
    } else if let registrar = self.registrar(forPlugin: "DevotionalNativeNotifications") {
      let channel = FlutterMethodChannel(name: "com.bhakti.devotional/notifications", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { [weak self] (call, callResult) in
        if call.method == "showNativeNotification" {
          guard let args = call.arguments as? [String: Any],
                let title = args["title"] as? String,
                let body = args["body"] as? String else {
            callResult(FlutterError(code: "INVALID_ARGS", message: "Missing title or body", details: nil))
            return
          }
          self?.scheduleNativeNotification(title: title, body: body)
          callResult(true)
        } else if call.method == "requestNativePermissions" {
          if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
              callResult(granted)
            }
          } else {
            callResult(true)
          }
        } else {
          callResult(FlutterMethodNotImplemented)
        }
      }
    }

    return result
  }

  private func scheduleNativeNotification(title: String, body: String) {
    if #available(iOS 10.0, *) {
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = UNNotificationSound.default
      content.badge = 1
      if #available(iOS 15.0, *) {
        content.interruptionLevel = .timeSensitive
      }

      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
      let identifier = "bhakti_instant_\(Date().timeIntervalSince1970)"
      let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

      UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
          print("Error adding native notification: \(error)")
        }
      }
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}
