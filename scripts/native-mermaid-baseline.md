# Native Mermaid Epic — Phase 0 Baselines

Recorded at the start of the native WebView-free Mermaid renderer epic (task 18,
PRD `20260531-1706_native-mermaid_v0.7_PRD_task18.txt`). These are the
green-baseline anchors the epic must preserve or improve.

| Metric | Baseline | Source |
| --- | --- | --- |
| Full `swift test` | 272 tests, 0 failures, none ignored | `swift test` |
| `MermaidTests.swift` count | 22 tests | `grep -c 'func test' Tests/MarkdownExtendedViewTests/MermaidTests.swift` |
| WebKit imports | exactly 1, in `Sources/MarkdownExtendedView/Views/MermaidView.swift` | `scripts/webkit-guard.sh` |
| Deployment floor | iOS 16 / macOS 13 (do not raise) | `Package.swift` |

Date: 2026-05-31. Branch: `dev`.

Guards:
- `scripts/webkit-guard.sh` — fails if `import WebKit`/`WKWebView` appears outside the allowed file; wired into CI. After Phase 9 (WebView removal), empty its `ALLOWED` list to forbid WebKit anywhere in `Sources/`.

PR8 performance anchor: the full suite runs in well under 1 s on the macOS host
(reported ~0.15 s execution); the native path must not materially regress total
`swift test` wall-clock. Re-measure on the CI runner when establishing the
quantified PR8 gate.
