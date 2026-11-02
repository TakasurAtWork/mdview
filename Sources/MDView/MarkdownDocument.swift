import AppKit

/// Read-only single-file document. The view controller does the reading and watching.
@objc(MarkdownDocument)
final class MarkdownDocument: NSDocument {
    override class var autosavesInPlace: Bool { false }
    override var isDocumentEdited: Bool { false }

    override func read(from url: URL, ofType typeName: String) throws {
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw CocoaError(.fileReadNoPermission, userInfo: [NSURLErrorKey: url])
        }
    }

    override func data(ofType typeName: String) throws -> Data {
        throw CocoaError(.featureUnsupported)
    }

    override func makeWindowControllers() {
        let markdown = MarkdownViewController()
        addWindowController(ViewerWindowController(content: markdown, markdown: markdown))
        if let url = fileURL { markdown.show(url) }
    }

    override func printOperation(withSettings printSettings: [NSPrintInfo.AttributeKey: Any]) throws -> NSPrintOperation {
        guard let viewer = windowControllers.first as? ViewerWindowController else {
            throw CocoaError(.featureUnsupported)
        }
        return viewer.markdown.printOperation(printInfo)
    }
}

/// Read-only folder document: a sidebar of the folder's Markdown files plus a viewer.
@objc(FolderDocument)
final class FolderDocument: NSDocument {
    override class var autosavesInPlace: Bool { false }
    override var isDocumentEdited: Bool { false }

    override func read(from url: URL, ofType typeName: String) throws {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else {
            throw CocoaError(.fileReadNoSuchFile, userInfo: [NSURLErrorKey: url])
        }
    }

    override func data(ofType typeName: String) throws -> Data {
        throw CocoaError(.featureUnsupported)
    }

    override func makeWindowControllers() {
        guard let url = fileURL else { return }
        let folder = FolderViewController(root: url)
        addWindowController(ViewerWindowController(content: folder, markdown: folder.markdown, hasSidebar: true))
    }

    override func printOperation(withSettings printSettings: [NSPrintInfo.AttributeKey: Any]) throws -> NSPrintOperation {
        guard let viewer = windowControllers.first as? ViewerWindowController else {
            throw CocoaError(.featureUnsupported)
        }
        return viewer.markdown.printOperation(printInfo)
    }
}

/// Lets the Open panel pick folders as well as files.
final class DocumentController: NSDocumentController {
    override func beginOpenPanel(_ openPanel: NSOpenPanel, forTypes inTypes: [String]?,
                                 completionHandler: @escaping (Int) -> Void) {
        openPanel.canChooseDirectories = true
        openPanel.treatsFilePackagesAsDirectories = false
        super.beginOpenPanel(openPanel, forTypes: inTypes, completionHandler: completionHandler)
    }
}
