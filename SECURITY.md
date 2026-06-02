# Security Policy

## Reporting a Vulnerability

Please report security vulnerabilities privately through GitHub's Security
Advisory feature:

https://github.com/ChrisGVE/MarkdownExtendedView/security/advisories/new

Do not open a public issue for a suspected vulnerability. We will acknowledge a
report within 5 business days and keep you informed as we investigate and fix.

## Scope

`MarkdownExtendedView` renders untrusted Markdown, including Mermaid diagrams.
Two areas are most security-relevant:

- **The optional native Mermaid renderer** (`MarkdownExtendedViewMermaidNative`),
  which links a prebuilt Rust static library (the `MermaidFFI` xcframework) built
  from the pinned `mermaid-rs-renderer` fork.
- **The Markdown rendering path**, which must never execute untrusted content.

### Untrusted-input guarantees

- **No code execution.** Diagram rendering is WebView-free: there is no embedded
  JavaScript engine and no remote script load. Untrusted Mermaid source can at
  worst produce a parse/render error, never code execution.
- **No network or filesystem egress.** Both display paths are egress-free, each
  with its own test:
  - *Vector (SVG via SVGView):* the adapter sanitizes the SVG before display —
    it neutralizes non-`data:` `<image>` `href`/`xlink:href`, external `<use>`
    references, CSS `url()` with non-`data:` schemes, `<script>`, and
    event-handler attributes (CWE-20/79/918).
  - *Raster (PNG via resvg/usvg, in Rust):* the rasterizer is configured with a
    `data:`-only image resolver, `resources_dir = None`, and an embedded-only
    font database (`load_system_fonts()` is never called), so it issues zero
    network or filesystem fetches.
- **Panic safety.** Every FFI entry point wraps the whole render pipeline in
  `catch_unwind`; a renderer panic returns a status code with a redacted,
  fixed payload (no internal paths or source fragments cross the boundary).
- **Denial-of-service bounds.** A 256 KB source-size cap and a 5000-node cap
  bound compute, and a perceived-latency timeout abandons a slow render.

## Advisory Response SLO

For vulnerabilities affecting the native Mermaid renderer's prebuilt binary:

- **Critical / High severity:** a patched xcframework is built from an updated
  source pin and released within **5 business days**.
- **Medium / Low severity:** addressed in the next regular release.

## Supply Chain

The native renderer's audited dependency tree includes `mermaid-rs-renderer`
(fork), `resvg`, `usvg`, `tiny-skia`, `rustybuzz`, `fontdb`, `regex`, and their
transitive dependencies. Dependency auditing runs in CI via `cargo audit`
(OSV/RustSec) on every push and pull request, and on a weekly schedule to catch
newly-disclosed advisories against unchanged dependencies. `regex` is pinned to
a `>= 1.5.5` floor (RUSTSEC-2022-0013).
