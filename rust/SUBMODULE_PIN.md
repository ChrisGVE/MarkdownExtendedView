# Rust submodule pin — `rust/mermaid-rs-renderer`

Authoritative record of the fork commit the native Mermaid renderer is built
against. The submodule pin and the locally-built xcframework are two pointers to
one logical "Rust version" and **must move together** (PRD §4.5.1). Update this
file in the same commit that advances the submodule pin.

| Field | Value |
| --- | --- |
| Fork | `ChrisGVE/mermaid-rs-renderer` (parent `1jehuang/mermaid-rs-renderer`, MIT) |
| Tracked branch | `dev` (our compile/aggregation branch — aggregates the per-PR feature/fix branches; PRD D2/D3) |
| Pinned commit | `80dd5b1` (dev; adds MVP render-proof tests over v0.2.2 baseline cf57b027) |
| Upstream version at pin | `v0.2.2` |
| Date pinned | 2026-05-31 |
| Phase | 2 (MVP render-proof tests on `dev`; feature branches not yet merged) |

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

## How to advance the pin

See `RELEASING.md` (§4.5.1 atomic protocol). In short: advance the submodule to
the target `dev` commit, record the new SHA here, rebuild the xcframework, pass
the header-drift + integrity gates, and commit the pin + artifact together.
