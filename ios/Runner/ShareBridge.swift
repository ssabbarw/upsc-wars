import Flutter
import UIKit

enum ShareBridge {
  static let methodChannelName = "upsc_wars/share"
  static let eventChannelName = "upsc_wars/share/events"

  private static var pendingArticleUrl: String?
  private static var events: FlutterEventSink?

  static func register(binaryMessenger: FlutterBinaryMessenger) {
    let methods = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: binaryMessenger
    )
    methods.setMethodCallHandler { call, result in
      if call.method == "consumeSharedArticleUrl" {
        let url = pendingArticleUrl
        pendingArticleUrl = nil
        result(url)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    let eventChannel = FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: binaryMessenger
    )
    eventChannel.setStreamHandler(ShareStreamHandler())
  }

  static func handle(url: URL) {
    guard let article = articleURL(from: url) else { return }
    pendingArticleUrl = article
    events?(article)
  }

  private static func articleURL(from url: URL) -> String? {
    if url.scheme?.lowercased() == "upscwars",
       url.host?.lowercased() == "pulse-article"
    {
      let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
      if let value = comps?.queryItems?.first(where: { $0.name == "url" })?.value,
         !value.isEmpty
      {
        return value
      }
    }
    if url.scheme?.lowercased() == "http" || url.scheme?.lowercased() == "https" {
      let host = url.host?.lowercased() ?? ""
      if host == "upscwars.in" || host == "www.upscwars.in" {
        return nil
      }
      return url.absoluteString
    }
    return nil
  }

  fileprivate static func attach(events: FlutterEventSink?) {
    self.events = events
    if let events, let pendingArticleUrl {
      events(pendingArticleUrl)
    }
  }
}

private final class ShareStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    ShareBridge.attach(events: events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    ShareBridge.attach(events: nil)
    return nil
  }
}
