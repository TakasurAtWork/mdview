import AppKit

/// Read-only document. Watches its file and re-renders whenever another app writes it.
@objc(MarkdownDocument)
final class MarkdownDocument: NSDocument {
    private(set) var markdown = ""
    private var watcher: FileWatcher?

    override class var autosavesInPlace: Bool { false }
    override var isDocumentEdited: Bool { false }

    override func read(from data: Data, ofType typeName: String) throws {
        markdown = Self.decode(data)
        if watcher == nil, let url = fileURL {
            watcher = FileWatcher(url: url) { [weak self] in self?.reloadFromDisk() }
        }
    }

    override func data(ofType typeName: String) throws -> Data {
        throw CocoaError(.featureUnsupported)
    }

    override func makeWindowControllers() {
        addWindowController(ViewerWindowController())
    }

    func reloadFromDisk() {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return }
        let text = Self.decode(data)
        guard text != markdown else { return }
        markdown = text
        windowControllers.forEach { ($0 as? ViewerWindowController)?.render() }
    }

    override func close() {
        watcher = nil
        super.close()
    }

    override func printOperation(withSettings printSettings: [NSPrintInfo.AttributeKey: Any]) throws -> NSPrintOperation {
        guard let viewer = windowControllers.first as? ViewerWindowController else {
            throw CocoaError(.featureUnsupported)
        }
        return viewer.printOperation(printInfo)
    }

    private static func decode(_ data: Data) -> String {
        var text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? String(decoding: data, as: UTF8.self)
        if text.hasPrefix("\u{FEFF}") { text.removeFirst() }
        return text
    }
}
