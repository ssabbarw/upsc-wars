import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    loadSharedURL { [weak self] urlString in
      DispatchQueue.main.async {
        self?.openHostApp(articleURL: urlString)
      }
    }
  }

  private func loadSharedURL(completion: @escaping (String?) -> Void) {
    guard
      let item = extensionContext?.inputItems.first as? NSExtensionItem,
      let attachments = item.attachments
    else {
      completion(nil)
      return
    }

    if let provider = attachments.first(where: {
      $0.hasItemConformingToTypeIdentifier(UTType.url.identifier)
    }) {
      provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
        if let url = item as? URL {
          completion(url.absoluteString)
        } else if let url = item as? NSURL {
          completion(url.absoluteString)
        } else {
          completion(nil)
        }
      }
      return
    }

    if let provider = attachments.first(where: {
      $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
    }) {
      provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
        let text = (item as? String) ?? ""
        completion(Self.firstHttpURL(in: text))
      }
      return
    }

    completion(nil)
  }

  private func openHostApp(articleURL: String?) {
    guard
      let articleURL,
      let encoded = articleURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
      let dest = URL(string: "upscwars://pulse-article?url=\(encoded)")
    else {
      finish()
      return
    }
    openURL(dest)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
      self?.finish()
    }
  }

  @objc
  private func openURL(_ url: URL) {
    var responder: UIResponder? = self
    while let current = responder {
      if let application = current as? UIApplication {
        application.open(url, options: [:], completionHandler: nil)
        return
      }
      let selector = NSSelectorFromString("openURL:")
      if current.responds(to: selector) {
        _ = current.perform(selector, with: url)
        return
      }
      responder = current.next
    }
  }

  private func finish() {
    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }

  private static func firstHttpURL(in text: String) -> String? {
    let pattern = #"https?://[^\s<>"'\)\]]+"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
      return nil
    }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = regex.firstMatch(in: text, options: [], range: range),
          let swiftRange = Range(match.range, in: text)
    else {
      return nil
    }
    return String(text[swiftRange]).trimmingCharacters(in: CharacterSet(charactersIn: ".,"))
  }
}
