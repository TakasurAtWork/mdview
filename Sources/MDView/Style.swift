enum Style {
    static let css = """
    :root {
      --fg: #1f2328; --muted: #59636e; --bg: #ffffff; --border: #d1d9e0;
      --code-bg: #f6f8fa; --link: #0969da; --mark: #fff8c5;
      --hl-keyword: #cf222e; --hl-title: #8250df; --hl-string: #0a3069; --hl-number: #0550ae;
      --hl-comment: #6e7781; --hl-type: #953800; --hl-tag: #116329;
      --hl-add-fg: #116329; --hl-add-bg: #dafbe1; --hl-del-fg: #82071e; --hl-del-bg: #ffebe9;
      --alert-note: #0969da; --alert-tip: #1a7f37; --alert-important: #8250df;
      --alert-warning: #9a6700; --alert-caution: #cf222e;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --fg: #e6edf3; --muted: #9198a1; --bg: #0d1117; --border: #3d444d;
        --code-bg: #151b23; --link: #4493f8; --mark: #bb800926;
        --hl-keyword: #ff7b72; --hl-title: #d2a8ff; --hl-string: #a5d6ff; --hl-number: #79c0ff;
        --hl-comment: #9198a1; --hl-type: #ffa657; --hl-tag: #7ee787;
        --hl-add-fg: #aff5b4; --hl-add-bg: #033a16; --hl-del-fg: #ffdcd7; --hl-del-bg: #67060c;
        --alert-note: #4493f8; --alert-tip: #3fb950; --alert-important: #ab7df8;
        --alert-warning: #d29922; --alert-caution: #f85149;
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
    .empty { margin-top: 30vh; text-align: center; color: var(--muted); }
    .alert { color: inherit; padding: .5em 1em; }
    .alert > :last-child { margin-bottom: 0; }
    .alert-title { font-weight: 600; margin-bottom: .25em !important; }
    .alert-note { border-left-color: var(--alert-note); } .alert-note .alert-title { color: var(--alert-note); }
    .alert-tip { border-left-color: var(--alert-tip); } .alert-tip .alert-title { color: var(--alert-tip); }
    .alert-important { border-left-color: var(--alert-important); } .alert-important .alert-title { color: var(--alert-important); }
    .alert-warning { border-left-color: var(--alert-warning); } .alert-warning .alert-title { color: var(--alert-warning); }
    .alert-caution { border-left-color: var(--alert-caution); } .alert-caution .alert-title { color: var(--alert-caution); }
    .alert-title::before { display: inline-block; width: 1.25em; }
    .alert-note .alert-title::before { content: "ⓘ"; }
    .alert-tip .alert-title::before { content: "✦"; }
    .alert-important .alert-title::before { content: "❖"; }
    .alert-warning .alert-title::before { content: "⚠︎"; }
    .alert-caution .alert-title::before { content: "⊘"; }
    .hljs-keyword, .hljs-meta .hljs-keyword, .hljs-doctag, .hljs-template-tag, .hljs-template-variable,
    .hljs-type.hljs-keyword, .hljs-variable.language_ { color: var(--hl-keyword); }
    .hljs-title, .hljs-title.class_, .hljs-title.function_ { color: var(--hl-title); }
    .hljs-attr, .hljs-attribute, .hljs-literal, .hljs-meta, .hljs-number, .hljs-operator,
    .hljs-variable, .hljs-selector-attr, .hljs-selector-class, .hljs-selector-id { color: var(--hl-number); }
    .hljs-regexp, .hljs-string, .hljs-meta .hljs-string { color: var(--hl-string); }
    .hljs-built_in, .hljs-symbol, .hljs-type, .hljs-params { color: var(--hl-type); }
    .hljs-comment, .hljs-code, .hljs-formula { color: var(--hl-comment); font-style: italic; }
    .hljs-name, .hljs-quote, .hljs-selector-tag, .hljs-selector-pseudo { color: var(--hl-tag); }
    .hljs-section { color: var(--hl-number); font-weight: 600; }
    .hljs-bullet { color: var(--hl-type); }
    .hljs-emphasis { font-style: italic; } .hljs-strong { font-weight: 600; }
    .hljs-addition { color: var(--hl-add-fg); background: var(--hl-add-bg); }
    .hljs-deletion { color: var(--hl-del-fg); background: var(--hl-del-bg); }
    mark { background: var(--mark); color: inherit; }
    @media print {
      body { padding: 0; }
      pre, table, img { break-inside: avoid; }
    }
    """
}
