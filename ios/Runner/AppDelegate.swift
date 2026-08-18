import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // #region agent log
    CursorDebugLog.write(
      hypothesisId: "B",
      location: "AppDelegate.swift:didFinishLaunchingWithOptions",
      message: "App launch",
      data: [
        "bundleId": Bundle.main.bundleIdentifier ?? "",
      ]
    )
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      CursorDebugLog.write(
        hypothesisId: "A",
        location: "AppDelegate.swift:getNotificationSettings",
        message: "UNNotificationSettings snapshot",
        data: [
          "authorizationStatus": "\(settings.authorizationStatus.rawValue)",
          "alertSetting": "\(settings.alertSetting.rawValue)",
          "badgeSetting": "\(settings.badgeSetting.rawValue)",
          "soundSetting": "\(settings.soundSetting.rawValue)"
        ]
      )
    }
    // #endregion
    if let url = launchOptions?[.url] as? URL {
      ShareBridge.handle(url: url)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    ShareBridge.handle(url: url)
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL
    {
      ShareBridge.handle(url: url)
    }
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }

  // #region agent log
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    CursorDebugLog.write(
      hypothesisId: "B",
      location: "AppDelegate.swift:didRegisterForRemoteNotificationsWithDeviceToken",
      message: "APNs registration succeeded",
      data: [
        "deviceTokenBytes": deviceToken.count
      ]
    )
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    CursorDebugLog.write(
      hypothesisId: "B",
      location: "AppDelegate.swift:didFailToRegisterForRemoteNotificationsWithError",
      message: "APNs registration failed",
      data: [
        "error": "\(error)"
      ]
    )
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
  // #endregion

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    ShareBridge.register(
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
  }
}

// #region agent log
private enum CursorDebugLog {
  static let sessionId = "3fd9a5"
  static let path = "/Users/sachinsabbarwal/Desktop/upsc_wars_april/upsc_wars/.cursor/debug-3fd9a5.log"

  static func write(
    hypothesisId: String,
    location: String,
    message: String,
    data: [String: Any] = [:],
    runId: String = "pre-fix"
  ) {
    let payload: [String: Any] = [
      "sessionId": sessionId,
      "runId": runId,
      "hypothesisId": hypothesisId,
      "location": location,
      "message": message,
      "data": data,
      "timestamp": Int(Date().timeIntervalSince1970 * 1000)
    ]
    guard let json = try? JSONSerialization.data(withJSONObject: payload),
          var line = String(data: json, encoding: .utf8) else { return }
    line.append("\n")
    guard let bytes = line.data(using: .utf8) else { return }
    do {
      if !FileManager.default.fileExists(atPath: path) {
        FileManager.default.createFile(atPath: path, contents: nil)
      }
      let handle = try FileHandle(forWritingTo: URL(fileURLWithPath: path))
      defer { try? handle.close() }
      try handle.seekToEndOfFile()
      try handle.write(bytes)
    } catch {
      // Never crash due to debug logging.
    }
  }
}
// #endregion
