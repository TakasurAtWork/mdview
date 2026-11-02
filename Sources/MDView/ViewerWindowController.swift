import AppKit

/// Window shell shared by file and folder windows: toolbar, find, zoom.
final class ViewerWindowController: NSWindowController, NSWindowDelegate {
    let markdown: MarkdownViewController
    private let searchItem = NSSearchToolbarItem(itemIdentifier: .init("search"))
    private let hasSidebar: Bool

    init(content: NSViewController, markdown: MarkdownViewController, hasSidebar: Bool = false) {
        self.markdown = markdown
        self.hasSidebar = hasSidebar

        let size = NSSize(width: hasSidebar ? 1160 : 900, height: 1000)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.contentViewController = content
        window.setContentSize(size)
        window.minSize = NSSize(width: 360, height: 240)
        window.tabbingMode = .preferred
        window.toolbarStyle = .unifiedCompact
        window.center()
        super.init(window: window)

        window.delegate = self
        shouldCascadeWindows = true
        windowFrameAutosaveName = hasSidebar ? "MDViewFolderWindow" : "MDViewWindow"

        searchItem.searchField.target = self
        searchItem.searchField.action = #selector(searchFieldAction(_:))
        searchItem.searchField.sendsWholeSearchString = true
        searchItem.searchField.placeholderString = "Find"
        let toolbar = NSToolbar(identifier: hasSidebar ? "folder" : "viewer")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        window.toolbar = toolbar
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Actions

    @objc func reloadDocument(_ sender: Any?) {
        markdown.reloadFromDisk()
    }

    @objc func revealInFinder(_ sender: Any?) {
        if let url = markdown.fileURL ?? (document as? NSDocument)?.fileURL {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    @objc func actualSize(_ sender: Any?) { markdown.adjustZoom(nil) }
    @objc func zoomInText(_ sender: Any?) { markdown.adjustZoom(markdown.pageZoom + 0.1) }
    @objc func zoomOutText(_ sender: Any?) { markdown.adjustZoom(markdown.pageZoom - 0.1) }

    @objc func showFind(_ sender: Any?) {
        if window?.toolbar?.isVisible == false { window?.toolbar?.isVisible = true }
        searchItem.beginSearchInteraction()
    }

    @objc func findNextMatch(_ sender: Any?) { find(backwards: false) }
    @objc func findPreviousMatch(_ sender: Any?) { find(backwards: true) }

    @objc private func searchFieldAction(_ sender: NSSearchField) {
        find(backwards: NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false)
    }

    private func find(backwards: Bool) {
        let query = searchItem.searchField.stringValue
        guard !query.isEmpty else { return showFind(nil) }
        markdown.find(query, backwards: backwards)
    }
}

// MARK: - Toolbar

extension ViewerWindowController: NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        (hasSidebar ? [.toggleSidebar] : []) + [.flexibleSpace, searchItem.itemIdentifier]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier id: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        id == searchItem.itemIdentifier ? searchItem : nil
    }
}
