import AppKit
import WebKit

/// Renders one Markdown file and re-renders it whenever it changes on disk.
/// Used on its own for a file, and as the detail pane of a folder window.
final class MarkdownViewController: NSViewController {
    static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn", "mdx"]
    private static let zoomKey = "pageZoom"
    private let webView: WKWebView
    private(set) var fileURL: URL?
    private var markdown = ""
    private var watcher: FileWatcher?
    private var pageLoaded = false
    private var pendingFragment: String?

    /// Lets a folder window keep `.md` links in the same window. Return true if handled.
    var openMarkdownLink: ((URL, String?) -> Bool)?

    init() {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(LocalFileSchemeHandler(), forURLScheme: LocalFileSchemeHandler.scheme)
        // Scripts inside the markdown never run; only the app's own injected JS does.
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 900, height: 1000), configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        let zoom = UserDefaults.standard.double(forKey: Self.zoomKey)
        webView.pageZoom = zoom > 0 ? zoom : 1
        super.init(nibName: nil, bundle: nil)
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }

    required init?(coder: NSCoder) { fatalError() }

    override func loadView() { view = webView }

    // MARK: - Content

    func show(_ url: URL, fragment: String? = nil) {
        let url = url.standardizedFileURL
        if url == fileURL {
            if let fragment { scroll(toFragment: fragment) }
            return
        }
        fileURL = url
        pendingFragment = fragment
        pageLoaded = false
        markdown = Self.read(url) ?? ""
        watcher = FileWatcher(url: url) { [weak self] in self?.reloadFromDisk() }
        render()
    }

    func showMessage(_ text: String) {
        fileURL = nil
        watcher = nil
        pageLoaded = false
        webView.loadHTMLString(Renderer.page(body: "<p class=\"empty\">\(Renderer.escape(text))</p>"), baseURL: nil)
    }

    func reloadFromDisk() {
        guard let url = fileURL, let text = Self.read(url), text != markdown else { return }
        markdown = text
        render()
    }

    private func render() {
        guard let url = fileURL else { return }
        let body = Renderer.body(from: markdown)
        if pageLoaded, let json = Self.jsonLiteral(body) {
            // Swap content in place: no flash, and scroll position is kept.
            webView.evaluateJavaScript("document.getElementById('content').innerHTML = \(json);",
                                       in: nil, in: .defaultClient)
        } else {
            webView.loadHTMLString(Renderer.page(body: body),
                                   baseURL: LocalFileSchemeHandler.url(forDirectory: url.deletingLastPathComponent()))
        }
    }

    private func scroll(toFragment fragment: String) {
        guard let json = Self.jsonLiteral(fragment) else { return }
        webView.evaluateJavaScript(
            "document.getElementById(decodeURIComponent(\(json)))?.scrollIntoView({behavior: 'smooth'});",
            in: nil, in: .defaultClient)
    }

    // MARK: - Commands

    func printOperation(_ info: NSPrintInfo) -> NSPrintOperation {
        let op = webView.printOperation(with: info)
        op.view?.frame = webView.bounds
        return op
    }

    func adjustZoom(_ zoom: CGFloat?) {
        let value = zoom.map { min(max($0, 0.5), 3) } ?? 1
        webView.pageZoom = value
        UserDefaults.standard.set(Double(value), forKey: Self.zoomKey)
    }

    var pageZoom: CGFloat { webView.pageZoom }

    func find(_ query: String, backwards: Bool) {
        let config = WKFindConfiguration()
        config.backwards = backwards
        config.caseSensitive = false
        config.wraps = true
        webView.find(query, configuration: config) { result in
            if !result.matchFound { NSSound.beep() }
        }
    }

    // MARK: - Helpers

    private static func read(_ url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        var text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? String(decoding: data, as: UTF8.self)
        if text.hasPrefix("\u{FEFF}") { text.removeFirst() }
        return text
    }

    private static func jsonLiteral(_ s: String) -> String? {
        (try? JSONEncoder().encode(s)).flatMap { String(data: $0, encoding: .utf8) }
    }
}

// MARK: - Navigation

extension MarkdownViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        pageLoaded = true
        if let fragment = pendingFragment {
            pendingFragment = nil
            scroll(toFragment: fragment)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard action.navigationType == .linkActivated, let url = action.request.url else {
            return decisionHandler(.allow)
        }
        decisionHandler(.cancel)
        open(url)
    }

    // target="_blank" links
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = action.request.url { open(url) }
        return nil
    }

    private func open(_ url: URL) {
        guard url.scheme == LocalFileSchemeHandler.scheme else {
            NSWorkspace.shared.open(url)
            return
        }
        let target = URL(fileURLWithPath: url.path).standardizedFileURL

        // In-page anchor (relative to the <base> directory or to this file).
        if let fragment = url.fragment,
           target == fileURL || target == fileURL?.deletingLastPathComponent() {
            return scroll(toFragment: fragment)
        }

        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: target.path, isDirectory: &isDir)
        guard exists, !isDir.boolValue,
              Self.markdownExtensions.contains(target.pathExtension.lowercased()) else {
            NSWorkspace.shared.open(target)
            return
        }
        if openMarkdownLink?(target, url.fragment) == true { return }

        NSDocumentController.shared.openDocument(withContentsOf: target, display: true) { doc, _, error in
            if let error { NSApp.presentError(error); return }
            if let fragment = url.fragment,
               let viewer = doc?.windowControllers.first as? ViewerWindowController {
                viewer.markdown.show(target, fragment: fragment)
            }
        }
    }
}
