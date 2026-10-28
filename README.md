# MDView

A tiny native macOS Markdown viewer. AppKit + the system WebKit, with Apple's
[swift-markdown](https://github.com/swiftlang/swift-markdown) (cmark-gfm) as the parser.
The app is about 1.3 MB, and one open document uses about 80 MB across all of its processes.

- GitHub-flavored Markdown: tables, task lists, strikethrough, autolinks, raw HTML
- Live reload when the file changes on disk, including atomic saves; scroll position is kept
- Light and dark mode follow the system
- Relative images and links: `.md` links open in a new tab, `#anchors` scroll, others open in their default app
- Find (⌘F, ⌘G, ⇧⌘G), zoom (⌘+ ⌘- ⌘0), print, tabs, Open Recent, Reveal in Finder (⇧⌘R)
- Scripts inside documents never run

## Build

    ./build.sh            # → build/MDView.app
    ./build.sh install    # also copies it to ~/Applications and links `mdv` into ~/.local/bin

## Use

    mdv README.md

To make it the default for `.md`: Finder → Get Info on any `.md` → Open with: MDView → Change All.
