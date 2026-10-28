import Foundation
import Markdown

enum Renderer {
    /// HTML for the article body. Re-injected on live reload so scroll position survives.
    static func body(from source: String) -> String {
        let (frontMatter, markdown) = splitFrontMatter(source)
        var html = HTMLFormatter.format(Document(parsing: markdown))
        html = addHeadingIDs(html)
        if let frontMatter {
            html = "<pre class=\"front-matter\"><code>\(escape(frontMatter))</code></pre>\n" + html
        }
        return html
    }

    static func page(body: String) -> String {
        """
        <!doctype html>
        <html><head><meta charset="utf-8">
        <meta name="color-scheme" content="light dark">
        <style>\(Style.css)</style>
        </head><body><article id="content">\(body)</article></body></html>
        """
    }

    // MARK: - Helpers

    private static func splitFrontMatter(_ text: String) -> (String?, String) {
        guard text.hasPrefix("---\n") || text.hasPrefix("---\r\n") else { return (nil, text) }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        for i in 1..<lines.count where lines[i].trimmingCharacters(in: .whitespaces) == "---" {
            let fm = lines[1..<i].joined(separator: "\n")
            let rest = lines[(i + 1)...].joined(separator: "\n")
            return (fm, rest)
        }
        return (nil, text)
    }

    private static let headingRegex = try! NSRegularExpression(pattern: "<h([1-6])>(.*?)</h\\1>")
    private static let tagRegex = try! NSRegularExpression(pattern: "<[^>]+>")

    /// GitHub-style slugs so `[link](#some-heading)` works.
    private static func addHeadingIDs(_ html: String) -> String {
        var seen: [String: Int] = [:]
        let ns = html as NSString
        var out = ""
        var cursor = 0
        for m in headingRegex.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
            out += ns.substring(with: NSRange(location: cursor, length: m.range.location - cursor))
            let level = ns.substring(with: m.range(at: 1))
            let inner = ns.substring(with: m.range(at: 2))
            var slug = slugify(inner)
            if let n = seen[slug] { seen[slug] = n + 1; slug += "-\(n + 1)" } else { seen[slug] = 0 }
            out += "<h\(level) id=\"\(slug)\">\(inner)</h\(level)>"
            cursor = m.range.location + m.range.length
        }
        out += ns.substring(from: cursor)
        return out
    }

    private static func slugify(_ innerHTML: String) -> String {
        let text = tagRegex.stringByReplacingMatches(
            in: innerHTML, range: NSRange(location: 0, length: (innerHTML as NSString).length), withTemplate: "")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .lowercased()
        var slug = ""
        for ch in text {
            if ch.isLetter || ch.isNumber || ch == "-" || ch == "_" { slug.append(ch) }
            else if ch == " " { slug.append("-") }
        }
        return slug
    }

    static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
