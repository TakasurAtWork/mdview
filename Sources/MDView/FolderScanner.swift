import CoreServices
import Foundation

final class FileNode {
    let url: URL
    let name: String
    /// nil for files.
    let children: [FileNode]?

    init(url: URL, children: [FileNode]?) {
        self.url = url
        self.name = url.lastPathComponent
        self.children = children
    }

    var isDirectory: Bool { children != nil }
}

/// Builds a tree of just the Markdown files under a folder, pruning folders that have none.
enum FolderScanner {
    /// Dependency and build output folders: big, and never worth browsing.
    private static let skipped: Set<String> = [
        "node_modules", "Pods", "Carthage", "DerivedData", ".build", "build", "vendor", "target",
    ]

    static func scan(_ root: URL) -> [FileNode] {
        children(of: root, depth: 0)
    }

    private static func children(of dir: URL, depth: Int) -> [FileNode] {
        guard depth < 16, let entries = try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey], options: [.skipsHiddenFiles])
        else { return [] }

        var folders: [FileNode] = []
        var files: [FileNode] = []
        for url in entries {
            // Symlinked folders report isDirectory == false, so cycles are impossible.
            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
            if values?.isDirectory == true {
                guard values?.isPackage != true, !skipped.contains(url.lastPathComponent) else { continue }
                let kids = children(of: url, depth: depth + 1)
                if !kids.isEmpty { folders.append(FileNode(url: url, children: kids)) }
            } else if MarkdownViewController.markdownExtensions.contains(url.pathExtension.lowercased()) {
                files.append(FileNode(url: url, children: nil))
            }
        }
        let byName: (FileNode, FileNode) -> Bool = { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return folders.sorted(by: byName) + files.sorted(by: byName)
    }

    /// The file to show first: a top-level README or index, else the first top-level file.
    static func defaultFile(in roots: [FileNode]) -> URL? {
        for preferred in ["readme.md", "readme.markdown", "index.md"] {
            if let hit = roots.first(where: { !$0.isDirectory && $0.name.lowercased() == preferred }) { return hit.url }
        }
        return roots.first(where: { !$0.isDirectory })?.url
    }

    static func allFiles(_ nodes: [FileNode]) -> [FileNode] {
        nodes.flatMap { $0.children.map(allFiles) ?? [$0] }
    }
}

/// FSEvents watcher that fires when Markdown files or folders are added, removed or renamed.
final class DirectoryWatcher {
    private let onChange: () -> Void
    private var stream: FSEventStreamRef?

    init(url: URL, onChange: @escaping () -> Void) {
        self.onChange = onChange
        var context = FSEventStreamContext(
            version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagNoDefer)
        stream = FSEventStreamCreate(nil, { _, info, count, paths, eventFlags, _ in
            guard let info else { return }
            let watcher = Unmanaged<DirectoryWatcher>.fromOpaque(info).takeUnretainedValue()
            let paths = unsafeBitCast(paths, to: NSArray.self) as? [String] ?? []
            let structural = FSEventStreamEventFlags(
                kFSEventStreamEventFlagItemCreated | kFSEventStreamEventFlagItemRemoved | kFSEventStreamEventFlagItemRenamed)
            for i in 0..<count where eventFlags[i] & structural != 0 {
                let path = paths[i]
                guard !path.contains("/.git/") else { continue }
                let isDir = eventFlags[i] & FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsDir) != 0
                let ext = (path as NSString).pathExtension.lowercased()
                if isDir || MarkdownViewController.markdownExtensions.contains(ext) {
                    watcher.onChange()
                    return
                }
            }
        }, &context, [url.path] as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.5, flags)
        if let stream {
            FSEventStreamSetDispatchQueue(stream, .main)
            FSEventStreamStart(stream)
        }
    }

    deinit {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
    }
}
