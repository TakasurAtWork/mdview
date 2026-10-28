import Foundation

/// kqueue-backed watcher that survives atomic saves (write-temp-then-rename),
/// which is how VS Code, vim, Xcode and most editors write files.
final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var pending: DispatchWorkItem?

    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
        start()
    }

    deinit { source?.cancel() }

    private func start(attempt: Int = 0) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            // File is mid-replace; try again shortly.
            if attempt < 20 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.start(attempt: attempt + 1)
                }
            }
            return
        }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: [.write, .extend, .delete, .rename], queue: .main)
        src.setEventHandler { [weak self, unowned src] in
            guard let self else { return }
            if !src.data.isDisjoint(with: [.delete, .rename]) {
                src.cancel()
                self.source = nil
                self.start()
            }
            self.scheduleChange()
        }
        src.setCancelHandler { close(fd) }
        src.resume()
        source = src
    }

    private func scheduleChange() {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.onChange() }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
    }
}
