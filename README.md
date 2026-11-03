# MDView

A tiny native macOS Markdown viewer. AppKit + the system WebKit, with Apple's
[swift-markdown](https://github.com/swiftlang/swift-markdown) (cmark-gfm) as the parser.
The app is about 7 MB (5 MB of that is mermaid.js), and one open file uses about 85 MB of memory
([numbers](#memory)).

- GitHub-flavored Markdown: tables, task lists, strikethrough, autolinks, raw HTML
- Syntax highlighting for fenced code blocks ([highlight.js](https://highlightjs.org), bundled, ~35 common languages)
- Mermaid diagrams in ```` ```mermaid ```` blocks, following light and dark mode; a diagram with an error
  shows the error in its place. mermaid.js only loads for documents that contain a diagram
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
| One Markdown file with Mermaid diagrams | 55 MB | 100 MB | 18 MB | 7 MB | **180 MB** |

For comparison, VS Code running on the same Mac at the same time measured 981 MB (with its own
windows and extensions, so this isn't a like-for-like test).

Most of the folder window's extra memory is the file list, and most of the diagram file's is Mermaid's
runtime, which documents without diagrams never load. Closing the last window quits the app,
so it holds no memory in the background.

## Build

    ./build.sh            # → build/MDView.app
    ./build.sh install    # also copies it to ~/Applications and links `mdv` into ~/.local/bin

## Use

    mdv README.md
    mdv ~/Developer/some-repo

To make it the default for `.md`: Finder → Get Info on any `.md` → Open with: MDView → Change All.

## License

Copyright © 2026 Takasur Azeem

MDView is free software: you can redistribute it and/or modify it under the terms of the
[GNU General Public License v3.0](LICENSE) as published by the Free Software Foundation, either
version 3 of the License, or (at your option) any later version. Forks and modified versions you
distribute must stay under the same license, with their source available.

Third-party code it uses keeps its own license:
- [swift-markdown](https://github.com/swiftlang/swift-markdown): Apache License 2.0
- [swift-cmark](https://github.com/swiftlang/swift-cmark) (cmark-gfm): BSD 2-Clause
- [highlight.js](https://highlightjs.org), bundled as `Resources/highlight.min.js`: BSD 3-Clause, notice in the file header
- [Mermaid](https://mermaid.js.org), bundled as `Resources/mermaid.min.js`: MIT
