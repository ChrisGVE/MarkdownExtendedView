# Rust submodule pin — `rust/mermaid-rs-renderer`

Authoritative record of the fork commit the native Mermaid renderer is built
against. The submodule pin and the locally-built xcframework are two pointers to
one logical "Rust version" and **must move together** (PRD §4.5.1). Update this
file in the same commit that advances the submodule pin.

| Field | Value |
| --- | --- |
| Fork | `ChrisGVE/mermaid-rs-renderer` (parent `1jehuang/mermaid-rs-renderer`, MIT) |
| Tracked branch | `dev` (our compile/aggregation branch — aggregates the per-PR feature/fix branches; PRD D2/D3) |
| Pinned commit | `0ec71be` (dev; embedded zero-fs font + flowchart self-label route fix merged over the Phase 2 render-proof baseline) |
| Upstream version at pin | `v0.2.2` |
| Date pinned | 2026-06-01 |
| Phase | 2b (deterministic zero-filesystem embedded font; flowchart self-label route fix) |

## Per-PR feature/fix branches on the fork (PRD §14.3)

Each Rust contribution lives on its own branch off `master`, becomes an
independent upstream PR (Phase 10, gated), and is merged into `dev` so the
xcframework builds against the union:

| Branch | Scope | Upstream alignment |
| --- | --- | --- |
| `feat/embedded-font` | Zero-filesystem-I/O embedded DejaVu subset; OnceLock fontdb | merged #80, #89/#45/#92 |
| `feat/ffi-c-abi` | C-ABI FFI layer (`mmdr_render_svg`/`mmdr_render_png`, `MmdrResult`/`MmdrOptions`) | #62, #16 |
| `feat/release-profile` | `lto=true` + `codegen-units=1` size/perf profile | #13 |
| `feat/apple-cross-compile` | Apple-target cross-compile (5 triples) | #71, PR #98 |
| `fix/sequence-par-alt` | sequenceDiagram `par`/`alt`/`loop` fidelity (MVP type) | #102, #103 |
| `fix/panic-guards` | Panic hardening (`catch_unwind`, node-cap) | #37, #95 |
| `fix/viewbox-sizing` | viewBox / intrinsic sizing | #83 |

## Known issues at this pin

None. The full fork suite is green on macOS at this pin (340 passed, 0 failed,
0 ignored). The two failures recorded at the previous pin (`80dd5b1`) are both
resolved here:

1. **`layout::tests::dense_flowchart_keeps_mid_span_edge_reasonably_direct`** —
   was a host-font-metrics artifact (red on macOS, green on Ubuntu CI). Resolved
   by the deterministic zero-filesystem embedded-font rework ([[feat/embedded-font]],
   `e863422`): glyph metrics are now identical on every platform, so the macOS
   `path/manhattan` ratio matches CI and the assertion passes.

2. **`all_repository_fixtures_satisfy_layout_invariants`** — was a genuine
   layout bug (`flowchart_opaque.mmd` edge `Baldr->Ke2` route overlapping its own
   center label). Fixed at root by scaling the
   `nudge_flowchart_labels_clear_of_own_paths` step ladder to the label size
   (`fix/edge-label-route-overlap`, `72ba047`). Upstreamed as
   **1jehuang/mermaid-rs-renderer#106** (`Closes #105`).

## How to advance the pin

See `RELEASING.md` (§4.5.1 atomic protocol). In short: advance the submodule to
the target `dev` commit, record the new SHA here, rebuild the xcframework, pass
the header-drift + integrity gates, and commit the pin + artifact together.
