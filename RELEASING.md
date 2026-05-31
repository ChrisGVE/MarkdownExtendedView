# Releasing the native Mermaid renderer

This documents the **atomic release protocol** (PRD §4.5.1) binding the Rust
fork submodule pin to the locally-built `MermaidFFI.xcframework`. A submodule
pin and the built artifact are two pointers to one logical "Rust version" and
**MUST move together** in a single commit — a pin advanced without a matching
rebuild (or vice versa) is a split-brain (risk R14) and is made un-mergeable by
the CI gates below.

> **MVP packaging = LOCAL-PATH + Git LFS only.** `Package.swift` consumes the
> xcframework via `binaryTarget(path:)`. There is **no `checksum:` field** for
> the local-path form — that parameter exists only on the remote
> `binaryTarget(url:checksum:)` form, which is a **Phase 11 / SPI-publish**
> concern (PRD D2, §13-D3), NOT MVP. Local-path integrity is guaranteed by Git
> LFS SHA-256 content addressing.

## Components that move together

| Pointer | Location |
| --- | --- |
| Submodule pin (fork `dev` commit) | `rust/mermaid-rs-renderer` + recorded in `rust/SUBMODULE_PIN.md` |
| FFI wrapper crate | `rust/mermaid-ffi` (Phase 3) |
| Generated C header | `mmdr.h` (cbindgen — committed; Phase 4) |
| Built artifact | `Artifacts/MermaidFFI.xcframework.zip` (Git LFS; Phase 5) |
| Artifact provenance | `Artifacts/MermaidFFI.xcframework.zip.sha256` |

## Release procedure (`make release-mermaid` — target added in Phase 5)

1. **Advance (or revert) the submodule pin.** Move `rust/mermaid-rs-renderer`
   to the target fork-`dev` commit (which aggregates the accepted per-PR
   feature/fix branches — PRD D3). Record the new SHA in `rust/SUBMODULE_PIN.md`.

   ```sh
   git -C rust/mermaid-rs-renderer fetch origin dev
   git -C rust/mermaid-rs-renderer checkout <target-dev-sha>
   # update rust/SUBMODULE_PIN.md with <target-dev-sha>
   ```

2. **Rebuild.** Run `scripts/build-xcframework.sh`, which regenerates `mmdr.h`
   via cbindgen **and** rebuilds all five slices (iOS-device arm64, iOS-sim
   arm64+x86_64 fat, macOS arm64+x86_64 fat) with the dual-format `--features
   png` build (D1), then assembles `MermaidFFI.xcframework`.

3. **Header-drift gate.** Fail if the regenerated `mmdr.h` differs from the
   committed one **without** an accompanying ABI-version bump
   (`MmdrResult.abi_version`). This is the structural binding between the
   submodule and the header. For the dual-format ABI the header declares BOTH
   `mmdr_render_svg` and `mmdr_render_png`.

4. **Commit pin + artifact together (local-path, the ONLY MVP variant).**
   `git lfs` commit the new `Artifacts/MermaidFFI.xcframework.zip`, its
   `.sha256` provenance note, the submodule pin, and `rust/SUBMODULE_PIN.md`
   **in the same commit**.

   > Remote-asset path (upload zip as a GitHub release asset → `swift package
   > compute-checksum` → pin `url:`+`checksum:`) is **NOT MVP** — introduced in
   > Phase 11 / §13-D3.

5. **CI integrity gates** (subject to the §4.4 change-detection guard — the full
   five-triple rebuild runs only when a Rust-adjacent path changed; a
   Swift/docs-only PR instead asserts the committed artifact's SHA-256 still
   matches the last build-tagged SHA-256). The MVP guarantee is **artifact
   integrity, not byte-for-byte reproducibility** (bit-identical rebuilds need
   path-remap + `SOURCE_DATE_EPOCH` + deterministic `ar`/zip — deferred to
   §13-D9). CI:
   - (i) **build-succeeds gate** — builds the xcframework from the pinned
     submodule with `--features png`; proves the pin compiles.
   - (ii) **cbindgen header-drift gate** — regenerated `mmdr.h` must match the
     committed one, else an ABI-version bump is required.
   - (iii) **committed-artifact integrity gate** — assert the build-output
     SHA-256 equals the committed Git-LFS blob's SHA-256
     (`Artifacts/MermaidFFI.xcframework.zip.sha256`). No `Package.swift`
     `checksum:` is involved in MVP.

   A mismatch in (i)/(ii)/(iii) fails the build.

6. **Tag the release.** The tag, the submodule pin, and the LFS-pinned artifact
   are now provably in sync (integrity), with the header drift-gated to the
   binary.

## Rollback

Run the same procedure against the previous known-good submodule SHA (recorded
in `rust/SUBMODULE_PIN.md` history / prior release tags).

## Upstreaming contributions (Phase 10 — OUTWARD, gated)

Each Rust feature/fix is upstreamed as its **own independent branch → PR**
against `1jehuang/mermaid-rs-renderer` (PRD D3, §14.3). Accepted PRs merge into
the fork `dev`. Two hard constraints apply to every fork commit and every PR:

- **A PR is opened only after Chris's explicit per-PR go-ahead.**
