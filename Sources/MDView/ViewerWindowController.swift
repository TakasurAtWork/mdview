import AppKit
import WebKit

final class ViewerWindowController: NSWindowController, NSWindowDelegate {
    private let webView: WKWebView
    private let searchItem = NSSearchToolbarItem(itemIdentifier: .init("search"))
    private var pageLoaded = false

    private var markdownDocument: MarkdownDocument? { document as? MarkdownDocument }

    private static let markdownExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn", "mdx"]
    private static let zoomKey = "pageZoom"

    init() {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(LocalFileSchemeHandler(), forURLScheme: LocalFileSchemeHandler.scheme)
        // Scripts inside the markdown never run; only the app's own injected JS does.
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        let zoom = UserDefaults.standard.double(forKey: Self.zoomKey)
        webView.pageZoom = zoom > 0 ? zoom : 1

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 1000),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.contentView = webView
        window.minSize = NSSize(width: 360, height: 240)
        window.tabbingMode = .preferred
        window.toolbarStyle = .unifiedCompact
        window.center()
        super.init(window: window)

        window.delegate = self
        webView.navigationDelegate = self
        webView.uiDelegate = self
        shouldCascadeWindows = true
        windowFrameAutosaveName = "MDViewWindow"

        searchItem.searchField.target = self
        searchItem.searchField.action = #selector(searchFieldAction(_:))
        searchItem.searchField.sendsWholeSearchString = true
        searchItem.searchField.placeholderString = "Find"
        let toolbar = NSToolbar(identifier: "viewer")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
    }

    required init?(coder: NSCoder) { fatalError() }

    override var document: AnyObject? {
        didSet { render() }
    }

    // MARK: - Rendering

    func render() {
        guard let doc = markdownDocument, let url = doc.fileURL else { return }
        let body = Renderer.body(from: doc.markdown)
        if pageLoaded, let json = try? String(data: JSONEncoder().encode(body), encoding: .utf8) {
            // Swap content in place: no flash, and scroll position is kept.
            webView.evaluateJavaScript("document.getElementById('content').innerHTML = \(json);",
                                       in: nil, in: .defaultClient)
        } else {
            webView.loadHTMLString(Renderer.page(body: body),
                                   baseURL: LocalFileSchemeHandler.url(forDirectory: url.deletingLastPathComponent()))
        }
    }

    func printOperation(_ info: NSPrintInfo) -> NSPrintOperation {
        let op = webView.printOperation(with: info)
        op.view?.frame = webView.bounds
        return op
    }

    private func scroll(toFragment fragment: String) {
        guard let json = try? String(data: JSONEncoder().encode(fragment), encoding: .utf8) else { return }
        webView.evaluateJavaScript(
            "document.getElementById(decodeURIComponent(\(json)))?.scrollIntoView({behavior: 'smooth'});",
            in: nil, in: .defaultClient)
    }

    // MARK: - Actions

    @objc func reload(_ sender: Any?) {
        markdownDocument?.reloadFromDisk()
    }

    @objc func revealInFinder(_ sender: Any?) {
        if let url = markdownDocument?.fileURL { NSWorkspace.shared.activateFileViewerSelecting([url]) }
    }

    @objc func actualSize(_ sender: Any?) { setZoom(1) }
    @objc func zoomIn(_ sender: Any?) { setZoom(min(webView.pageZoom + 0.1, 3)) }
    @objc func zoomOut(_ sender: Any?) { setZoom(max(webView.pageZoom - 0.1, 0.5)) }

    private func setZoom(_ zoom: CGFloat) {
        webView.pageZoom = zoom
        UserDefaults.standard.set(Double(zoom), forKey: Self.zoomKey)
    }

    @objc func showFind(_ sender: Any?) {
        if window?.toolbar?.isVisible == false { window?.toolbar?.isVisible = true }
        searchItem.beginSearchInteraction()
    }

    @objc func findNext(_ sender: Any?) { find(backwards: false) }
    @objc func findPrevious(_ sender: Any?) { find(backwards: true) }

    @objc private func searchFieldAction(_ sender: NSSearchField) {
        find(backwards: NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false)
    }

    private func find(backwards: Bool) {
        let query = searchItem.searchField.stringValue
        guard !query.isEmpty else { return showFind(nil) }
        let config = WKFindConfiguration()
        config.backwards = backwards
        config.caseSensitive = false
        config.wraps = true
        webView.find(query, configuration: config) { result in
            if !result.matchFound { NSSound.beep() }
        }
    }
}

// MARK: - Navigation

extension ViewerWindowController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        pageLoaded = true
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
        let current = markdownDocument?.fileURL?.standardizedFileURL

        // In-page anchor (relative to the <base> directory or to this file).
        if let fragment = url.fragment,
           target == current || target == current?.deletingLastPathComponent() {
            return scroll(toFragment: fragment)
        }

        guard Self.markdownExtensions.contains(target.pathExtension.lowercased()) else {
            NSWorkspace.shared.open(target)
            return
        }
        NSDocumentController.shared.openDocument(withContentsOf: target, display: true) { doc, _, error in
            if let error { NSApp.presentError(error); return }
            if let fragment = url.fragment,
               let viewer = doc?.windowControllers.first as? ViewerWindowController {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { viewer.scroll(toFragment: fragment) }
            }
        }
    }
}

// MARK: - Toolbar

extension ViewerWindowController: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace, searchItem.itemIdentifier]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier id: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        id == searchItem.itemIdentifier ? searchItem : nil
    }
}
