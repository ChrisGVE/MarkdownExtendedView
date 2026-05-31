//! C-ABI FFI wrapper around `mermaid-rs-renderer`.
//!
//! This crate is built as a `staticlib` and linked into `MermaidFFI.xcframework`
//! (Phases 4/5). It keeps the fork submodule pristine for independent
//! per-PR upstreaming (PRD §4.5 / D3): all FFI-specific glue lives here, not in
//! the fork.
//!
//! Modules:
//! - [`diagram_type`]: wrapper-side keyword pre-dispatch (the PRIMARY status-5
//!   `ErrUnsupported` gate for non-MVP diagram types — PRD R3-C / §4.3).
//!
//! The C-ABI render functions (`mmdr_render_svg` / `mmdr_render_png`) and the
//! transparent `MmdrResult` / `MmdrOptions` structs are added in Phase 3
//! (Task 6).

pub mod diagram_type;
