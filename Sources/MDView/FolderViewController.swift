import AppKit

/// Sidebar of Markdown files on the left, the selected file on the right.
final class FolderViewController: NSSplitViewController {
    let root: URL
    let markdown = MarkdownViewController()
    private let sidebar = SidebarViewController()
    private var watcher: DirectoryWatcher?
    private var history: [URL] = []
    private var historyIndex = -1
    private var scanGeneration = 0

    init(root: URL) {
        self.root = root.standardizedFileURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.frame = NSRect(x: 0, y: 0, width: 1160, height: 1000)
        splitView.autosaveName = "MDViewSidebar"

        let side = NSSplitViewItem(sidebarWithViewController: sidebar)
        side.minimumThickness = 180
        side.maximumThickness = 420
        side.canCollapse = true
        addSplitViewItem(side)
        addSplitViewItem(NSSplitViewItem(viewController: markdown))

        sidebar.root = root
        sidebar.onSelect = { [weak self] url in self?.open(url) }
        markdown.openMarkdownLink = { [weak self] url, fragment in
            guard let self, url.path.hasPrefix(self.root.path + "/") else { return false }
            self.open(url, fragment: fragment)
            return true
        }
        markdown.showMessage("Scanning \(root.lastPathComponent)…")
        rescan()
        watcher = DirectoryWatcher(url: root) { [weak self] in self?.rescan() }
    }

    // MARK: - Files

    private func rescan() {
        scanGeneration += 1
        let generation = scanGeneration
        let root = self.root
        DispatchQueue.global(qos: .userInitiated).async {
            let tree = FolderScanner.scan(root)
            DispatchQueue.main.async { [weak self] in
                guard let self, generation == self.scanGeneration else { return }
                self.sidebar.setTree(tree)
                if let current = self.markdown.fileURL,
                   FileManager.default.fileExists(atPath: current.path) {
                    self.sidebar.select(current)
                } else if let first = FolderScanner.defaultFile(in: tree) {
                    self.open(first)
                } else {
                    self.markdown.showMessage(tree.isEmpty ? "No Markdown files in \(root.lastPathComponent)."
                                                           : "Choose a file from the sidebar.")
                    self.view.window?.subtitle = ""
                }
            }
        }
    }

    func open(_ url: URL, fragment: String? = nil, recordHistory: Bool = true) {
        let url = url.standardizedFileURL
        markdown.show(url, fragment: fragment)
        sidebar.select(url)
        view.window?.subtitle = String(url.path.dropFirst(root.path.count + 1))
        guard recordHistory, history.indices.contains(historyIndex) ? history[historyIndex] != url : true else { return }
        history = Array(history.prefix(historyIndex + 1)) + [url]
        historyIndex = history.count - 1
    }

    // MARK: - Actions (found through the responder chain)

    @objc func reloadDocument(_ sender: Any?) {
        markdown.reloadFromDisk()
        rescan()
    }

    @objc func goBack(_ sender: Any?) { step(-1) }
    @objc func goForward(_ sender: Any?) { step(1) }

    @objc func filterFiles(_ sender: Any?) {
        if splitViewItems.first?.isCollapsed == true { toggleSidebar(nil) }
        sidebar.focusFilter()
    }

    private func step(_ delta: Int) {
        let target = historyIndex + delta
        guard history.indices.contains(target) else { return NSSound.beep() }
        historyIndex = target
        open(history[target], recordHistory: false)
    }

}

extension FolderViewController: NSMenuItemValidation {
    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        switch item.action {
        case #selector(goBack(_:)): return historyIndex > 0
        case #selector(goForward(_:)): return historyIndex < history.count - 1
        case #selector(toggleSidebar(_:)):
            item.title = splitViewItems.first?.isCollapsed == true ? "Show Sidebar" : "Hide Sidebar"
            return true
        default: return true
        }
    }
}

// MARK: - Sidebar

final class SidebarViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, NSSearchFieldDelegate {
    var root: URL!
    var onSelect: ((URL) -> Void)?

    private let outline = NSOutlineView()
    private let filterField = NSSearchField()
    private var tree: [FileNode] = []
    private var matches: [FileNode]?
    private var nodesByURL: [URL: FileNode] = [:]
    private var parents: [URL: FileNode] = [:]
    private var selectingProgrammatically = false

    override func loadView() {
        filterField.placeholderString = "Filter files"
        filterField.delegate = self
        filterField.controlSize = .regular

        let column = NSTableColumn(identifier: .init("name"))
        outline.addTableColumn(column)
        outline.outlineTableColumn = column
        outline.headerView = nil
        outline.style = .sourceList
        outline.dataSource = self
        outline.delegate = self
        outline.autosaveExpandedItems = false

        let scroll = NSScrollView()
        scroll.documentView = outline
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false

        let stack = NSStackView(views: [filterField, scroll])
        stack.orientation = .vertical
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 8, left: 8, bottom: 0, right: 8)
        stack.setHuggingPriority(.defaultLow, for: .horizontal)
        scroll.setContentHuggingPriority(.defaultLow, for: .vertical)
        view = stack
        view.frame = NSRect(x: 0, y: 0, width: 260, height: 1000)
    }

    func setTree(_ newTree: [FileNode]) {
        let expanded = Set(nodesByURL.values.filter { outline.isItemExpanded($0) }.map(\.url))
        tree = newTree
        nodesByURL = [:]
        parents = [:]
        index(newTree, parent: nil)
        applyFilter()
        for url in expanded.sorted(by: { $0.path.count < $1.path.count }) {
            if let node = nodesByURL[url] { outline.expandItem(node) }
        }
    }

    private func index(_ nodes: [FileNode], parent: FileNode?) {
        for node in nodes {
            nodesByURL[node.url] = node
            if let parent { parents[node.url] = parent }
            if let kids = node.children { index(kids, parent: node) }
        }
    }

    func select(_ url: URL) {
        guard let node = nodesByURL[url] else { return outline.deselectAll(nil) }
        var chain: [FileNode] = []
        var p = parents[url]
        while let parent = p { chain.insert(parent, at: 0); p = parents[parent.url] }
        chain.forEach { outline.expandItem($0) }
        let row = outline.row(forItem: node)
        guard row >= 0, outline.selectedRow != row else { return }
        selectingProgrammatically = true
        outline.selectRowIndexes([row], byExtendingSelection: false)
        outline.scrollRowToVisible(row)
        selectingProgrammatically = false
    }

    func focusFilter() {
        view.window?.makeFirstResponder(filterField)
    }

    // MARK: Filtering

    func controlTextDidChange(_ obj: Notification) { applyFilter() }

    private func applyFilter() {
        let query = filterField.stringValue.trimmingCharacters(in: .whitespaces)
        let selected = outline.item(atRow: outline.selectedRow) as? FileNode
        matches = query.isEmpty ? nil : FolderScanner.allFiles(tree).filter {
            relativePath($0).localizedCaseInsensitiveContains(query)
        }
        outline.reloadData()
        if let selected { select(selected.url) }
    }

    private func relativePath(_ node: FileNode) -> String {
        String(node.url.path.dropFirst(root.path.count + 1))
    }

    // MARK: Data source

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let node = item as? FileNode { return node.children?.count ?? 0 }
        return (matches ?? tree).count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let node = item as? FileNode { return node.children![index] }
        return (matches ?? tree)[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        matches == nil && (item as? FileNode)?.isDirectory == true
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? FileNode else { return nil }
        let id = NSUserInterfaceItemIdentifier("cell")
        let cell = outlineView.makeView(withIdentifier: id, owner: nil) as? NSTableCellView ?? makeCell(id)
        cell.textField?.stringValue = matches == nil ? node.name : relativePath(node)
        cell.imageView?.image = NSImage(systemSymbolName: node.isDirectory ? "folder" : "doc.text",
                                        accessibilityDescription: nil)
        cell.toolTip = relativePath(node)
        return cell
    }

    private func makeCell(_ id: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = id
        let image = NSImageView()
        let text = NSTextField(labelWithString: "")
        text.lineBreakMode = .byTruncatingMiddle
        for v in [image, text] { v.translatesAutoresizingMaskIntoConstraints = false; cell.addSubview(v) }
        NSLayoutConstraint.activate([
            image.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 2),
            image.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            image.widthAnchor.constraint(equalToConstant: 16),
            text.leadingAnchor.constraint(equalTo: image.trailingAnchor, constant: 6),
            text.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -2),
            text.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
        ])
        cell.imageView = image
        cell.textField = text
        return cell
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard !selectingProgrammatically,
              let node = outline.item(atRow: outline.selectedRow) as? FileNode, !node.isDirectory else { return }
        onSelect?(node.url)
    }
}
