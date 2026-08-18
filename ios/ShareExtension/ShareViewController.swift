import UIKit
import UniformTypeIdentifiers

/// Safari and Chrome iOS share a page as URL / text / JS preprocessor results.
/// The extension extracts that http(s) URL and opens the host app.
final class ShareViewController: UIViewController {
  private var destURL: URL?
  private let status = UILabel()
  private let openButton = UIButton(type: .system)

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    preferredContentSize = CGSize(width: 320, height: 180)

    status.translatesAutoresizingMaskIntoConstraints = false
    status.text = "Opening UPSC Wars…"
    status.textAlignment = .center
    status.numberOfLines = 0
    status.font = .preferredFont(forTextStyle: .body)

    openButton.translatesAutoresizingMaskIntoConstraints = false
    openButton.setTitle("Open in UPSC Wars", for: .normal)
    openButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
    openButton.addTarget(self, action: #selector(openTapped), for: .touchUpInside)

    view.addSubview(status)
    view.addSubview(openButton)
    NSLayoutConstraint.activate([
      status.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      status.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      status.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -24),
      openButton.topAnchor.constraint(equalTo: status.bottomAnchor, constant: 16),
      openButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
    ])
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    loadSharedURL { [weak self] urlString in
      DispatchQueue.main.async {
        self?.handleExtracted(urlString)
      }
    }
  }

  @objc private func openTapped() {
    guard let destURL else { return }
    openHostApp(destURL)
  }

  private func handleExtracted(_ articleURL: String?) {
    guard let articleURL, !articleURL.isEmpty else {
      status.text = "Could not read this page’s URL."
      openButton.setTitle("Done", for: .normal)
      openButton.removeTarget(self, action: #selector(openTapped), for: .touchUpInside)
      openButton.addTarget(self, action: #selector(finish), for: .touchUpInside)
      return
    }
    var comps = URLComponents()
    comps.scheme = "upscwars"
    comps.host = "pulse-article"
    comps.queryItems = [URLQueryItem(name: "url", value: articleURL)]
    guard let dest = comps.url else {
      finish()
      return
    }
    destURL = dest
    openHostApp(dest)
  }

  private func openHostApp(_ url: URL) {
    openURLViaResponder(url)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
      self?.finish()
    }
  }

  /// Share extensions cannot use `extensionContext.open`. Walk the responder
  /// chain and invoke `openURL:` so Safari/Chrome can hand off to the host app.
  private func openURLViaResponder(_ url: URL) {
    let selector = NSSelectorFromString("openURL:")
    var responder: UIResponder? = self
    while let current = responder {
      if current !== self, current.responds(to: selector) {
        _ = current.perform(selector, with: url)
      }
      responder = current.next
    }
  }

  @objc private func finish() {
    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }

  private func loadSharedURL(completion: @escaping (String?) -> Void) {
    let items = extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? []
    var providers: [NSItemProvider] = []
    var fallbackText: String?
    for item in items {
      providers.append(contentsOf: item.attachments ?? [])
      if fallbackText == nil {
        fallbackText = item.attributedContentText?.string
      }
    }
    guard !providers.isEmpty else {
      completion(Self.httpURL(from: fallbackText))
      return
    }
    loadFromProviders(providers, index: 0) { url in
      if let url {
        completion(url)
        return
      }
      completion(Self.httpURL(from: fallbackText))
    }
  }

  private func loadFromProviders(
    _ providers: [NSItemProvider],
    index: Int,
    completion: @escaping (String?) -> Void
  ) {
    if index >= providers.count {
      completion(nil)
      return
    }
    extractURL(from: providers[index]) { [weak self] url in
      if let url, !url.isEmpty {
        completion(url)
        return
      }
      self?.loadFromProviders(providers, index: index + 1, completion: completion)
    }
  }

  private func extractURL(
    from provider: NSItemProvider,
    completion: @escaping (String?) -> Void
  ) {
    if provider.canLoadObject(ofClass: URL.self) {
      provider.loadObject(ofClass: URL.self) { [weak self] object, _ in
        if let url = Self.httpURL(from: object) {
          completion(url)
          return
        }
        self?.loadTypedItem(from: provider, completion: completion)
      }
      return
    }
    loadTypedItem(from: provider, completion: completion)
  }

  private func loadTypedItem(
    from provider: NSItemProvider,
    completion: @escaping (String?) -> Void
  ) {
    let preferred = [
      UTType.url.identifier,
      "public.url",
      UTType.propertyList.identifier,
      "com.apple.property-list",
      UTType.plainText.identifier,
      UTType.html.identifier,
      "public.text",
      "public.plain-text",
    ]
    var types = preferred.filter { provider.hasItemConformingToTypeIdentifier($0) }
    for type in provider.registeredTypeIdentifiers where !types.contains(type) {
      types.append(type)
    }
    loadFirstType(provider, types: types, index: 0, completion: completion)
  }

  private func loadFirstType(
    _ provider: NSItemProvider,
    types: [String],
    index: Int,
    completion: @escaping (String?) -> Void
  ) {
    if index >= types.count {
      completion(nil)
      return
    }
    provider.loadItem(forTypeIdentifier: types[index], options: nil) { [weak self] item, _ in
      if let url = Self.httpURL(from: item) {
        completion(url)
        return
      }
      self?.loadFirstType(provider, types: types, index: index + 1, completion: completion)
    }
  }

  private static func httpURL(from item: Any?) -> String? {
    if let url = item as? URL {
      if url.scheme?.lowercased().hasPrefix("http") == true {
        return url.absoluteString
      }
      return firstHttpURL(in: url.absoluteString)
    }
    if let url = item as? NSURL {
      return firstHttpURL(in: url.absoluteString ?? "")
    }
    if let text = item as? String {
      return firstHttpURL(in: text)
    }
    if let text = item as? NSAttributedString {
      return firstHttpURL(in: text.string)
    }
    if let data = item as? Data {
      if let plist = try? PropertyListSerialization.propertyList(
        from: data,
        options: [],
        format: nil
      ) {
        return httpURL(from: plist)
      }
      if let text = String(data: data, encoding: .utf8) {
        return firstHttpURL(in: text)
      }
    }
    if let dict = item as? [String: Any] {
      if let results = dict[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any] {
        if let url = results["URL"] as? String { return firstHttpURL(in: url) }
        if let url = results["url"] as? String { return firstHttpURL(in: url) }
      }
      for key in ["URL", "url", "public.url"] {
        if let url = dict[key] as? String { return firstHttpURL(in: url) }
      }
    }
    return nil
  }

  private static func firstHttpURL(in text: String) -> String? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
      return trimmed.trimmingCharacters(in: CharacterSet(charactersIn: ".,<>"))
    }
    if trimmed.lowercased().hasPrefix("www.") {
      return "https://\(trimmed)"
    }
    let pattern = #"https?://[^\s<>"'\)\]]+"#
    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
      return nil
    }
    let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
    guard let match = regex.firstMatch(in: trimmed, options: [], range: range),
          let swiftRange = Range(match.range, in: trimmed)
    else {
      return nil
    }
    return String(trimmed[swiftRange]).trimmingCharacters(in: CharacterSet(charactersIn: ".,"))
  }
}
