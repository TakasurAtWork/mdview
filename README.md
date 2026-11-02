# MDView

A tiny native macOS Markdown viewer. AppKit + the system WebKit, with Apple's
[swift-markdown](https://github.com/swiftlang/swift-markdown) (cmark-gfm) as the parser.
The app is about 1.5 MB, and one open file uses about 85 MB of memory ([numbers](#memory)).

- GitHub-flavored Markdown: tables, task lists, strikethrough, autolinks, raw HTML
- Syntax highlighting for fenced code blocks ([highlight.js](https://highlightjs.org), bundled, ~35 common languages)
- GitHub callouts: `> [!NOTE]`, `[!TIP]`, `[!IMPORTANT]`, `[!WARNING]`, `[!CAUTION]`
- Open a folder to browse every Markdown file in it, recursively (dependency and build folders are skipped);
  ⇧⌘O filters files, ⌘[ / ⌘] go back and forward, ⌃⌘S toggles the sidebar
- Live reload when the file changes on disk, including atomic saves; scroll position is kept
- Light and dark mode follow the system
- Relative images and links: `.md` links open in a new tab, `#anchors` scroll, others open in their default app
- Find (⌘F, ⌘G, ⇧⌘G), zoom (⌘+ ⌘- ⌘0), print, tabs, Open Recent, Reveal in Finder (⇧⌘R)
- Scripts inside documents never run (the highlighter runs in its own isolated script world)

## Memory

Measured with macOS's `footprint` tool on an Apple Silicon Mac (macOS 27). WebKit runs each page in
helper processes, so the total counts the app and all three helpers.

| Window | App | Page | GPU | Network | **Total** |
|---|--:|--:|--:|--:|--:|
| One Markdown file | 33 MB | 28 MB | 17 MB | 6 MB | **84 MB** |
| A folder with ~3,300 Markdown files across ~15 repos | 73 MB | 19 MB | 13 MB | 6 MB | **111 MB** |

For comparison, VS Code running on the same Mac at the same time measured 981 MB (with its own
windows and extensions, so this isn't a like-for-like test).

Most of the folder window's extra memory is the file list. Closing the last window quits the app,
so it holds no memory in the background.

## Build

    ./build.sh            # → build/MDView.app
    ./build.sh install    # also copies it to ~/Applications and links `mdv` into ~/.local/bin

## Use

    mdv README.md
    mdv ~/Developer/some-repo

To make it the default for `.md`: Finder → Get Info on any `.md` → Open with: MDView → Change All.
