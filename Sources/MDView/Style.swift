enum Style {
    static let css = """
    :root {
      --fg: #1f2328; --muted: #59636e; --bg: #ffffff; --border: #d1d9e0;
      --code-bg: #f6f8fa; --link: #0969da; --mark: #fff8c5;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --fg: #e6edf3; --muted: #9198a1; --bg: #0d1117; --border: #3d444d;
        --code-bg: #151b23; --link: #4493f8; --mark: #bb800926;
      }
    }
    html { background: var(--bg); }
    body {
      margin: 0; padding: 32px 40px 80px; color: var(--fg); background: var(--bg);
      font: 16px/1.6 -apple-system, BlinkMacSystemFont, "Helvetica Neue", sans-serif;
      -webkit-font-smoothing: antialiased; word-wrap: break-word;
    }
    #content { max-width: 880px; margin: 0 auto; }
    #content > :first-child { margin-top: 0 !important; }
    a { color: var(--link); text-decoration: none; }
    a:hover { text-decoration: underline; }
    h1, h2, h3, h4, h5, h6 { margin: 1.5em 0 .6em; font-weight: 600; line-height: 1.25; }
    h1 { font-size: 2em; padding-bottom: .3em; border-bottom: 1px solid var(--border); }
    h2 { font-size: 1.5em; padding-bottom: .3em; border-bottom: 1px solid var(--border); }
    h3 { font-size: 1.25em; } h4 { font-size: 1em; }
    h5 { font-size: .875em; } h6 { font-size: .85em; color: var(--muted); }
    p, ul, ol, blockquote, pre, table, dl { margin: 0 0 1em; }
    ul, ol { padding-left: 2em; }
    li + li { margin-top: .25em; }
    li > p { margin: 0; }
    li:has(> input[type=checkbox]) { list-style: none; margin-left: -1.4em; }
    li > input[type=checkbox] { margin: 0 .4em 0 0; vertical-align: middle; }
    li > input[type=checkbox] + p { display: inline; }
    blockquote { padding: 0 1em; color: var(--muted); border-left: .25em solid var(--border); }
    code, kbd, pre { font-family: ui-monospace, "SF Mono", Menlo, monospace; font-size: 85%; }
    code { padding: .2em .4em; background: var(--code-bg); border-radius: 6px; }
    pre { padding: 16px; overflow: auto; line-height: 1.45; background: var(--code-bg); border-radius: 6px; }
    pre code { padding: 0; background: none; font-size: 100%; }
    pre.front-matter { color: var(--muted); border: 1px dashed var(--border); background: none; }
    kbd { padding: .15em .4em; border: 1px solid var(--border); border-bottom-width: 2px; border-radius: 6px; }
    table { border-collapse: collapse; display: block; width: max-content; max-width: 100%; overflow: auto; }
    th, td { padding: 6px 13px; border: 1px solid var(--border); }
    th { font-weight: 600; }
    tr:nth-child(2n) { background: var(--code-bg); }
    img { max-width: 100%; }
    hr { height: 3px; margin: 1.5em 0; border: 0; background: var(--border); }
    mark { background: var(--mark); color: inherit; }
    @media print {
      body { padding: 0; }
      pre, table, img { break-inside: avoid; }
    }
    """
}
