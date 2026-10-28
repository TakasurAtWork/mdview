import UniformTypeIdentifiers
import WebKit

/// Serves files next to the document (images, etc.) under `mdv-local://file/<absolute path>`.
/// WKWebView won't load file:// subresources into an HTML string, so this stands in.
final class LocalFileSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "mdv-local"

    static func url(forDirectory dir: URL) -> URL {
        var c = URLComponents()
        c.scheme = scheme
        c.host = "file"
        c.path = dir.standardizedFileURL.path + "/"
        return c.url!
    }

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        let fileURL = URL(fileURLWithPath: url.path)
        do {
            let data = try Data(contentsOf: fileURL)
            let mime = UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType
                ?? "application/octet-stream"
            task.didReceive(URLResponse(url: url, mimeType: mime,
                                        expectedContentLength: data.count, textEncodingName: nil))
            task.didReceive(data)
            task.didFinish()
        } catch {
            task.didFailWithError(error)
        }
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}
