#!/usr/bin/env bash
#
# build-xcframework.sh — assemble MermaidFFI.xcframework from the Rust fork.
#
# SKELETON (Phase 1). The build chain it drives is completed across Phases 3–5:
#   - Phase 3: the `rust/mermaid-ffi` C-ABI wrapper crate (cdylib/staticlib).
#   - Phase 4: the cbindgen-generated `mmdr.h` header + header-drift gate.
#   - Phase 5: five-slice cross-compile + lipo + `xcodebuild -create-xcframework`,
#              Git-LFS artifact commit, and the §4.5.1 integrity gate.
#
# This script intentionally EXITS NON-ZERO at each not-yet-implemented stage
# rather than producing a fake/empty framework (PRD: no stubs). As each phase
# lands, replace the corresponding `phase_guard` block with the real steps.
#
# Reference: PRD §4.4 (cross-compile), §4.5/§4.5.1 (packaging + release protocol).

set -euo pipefail

# --- configuration -----------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FFI_CRATE_DIR="${REPO_ROOT}/rust/mermaid-ffi" # Phase 3
SUBMODULE_DIR="${REPO_ROOT}/rust/mermaid-rs-renderer"
HEADER_OUT="${REPO_ROOT}/rust/include/mmdr.h" # Phase 4 (cbindgen)
BUILD_DIR="${REPO_ROOT}/.build/xcframework"
ARTIFACTS_DIR="${REPO_ROOT}/Artifacts"
XCFRAMEWORK="MermaidFFI.xcframework"
LIB_NAME="libmermaid_ffi.a" # staticlib name (Phase 3)
CARGO_FEATURES="png"        # dual-format build (D1)

# Five build slices (PRD §4.4): iOS-device single-arch, iOS-sim fat, macOS fat.
IOS_DEVICE_TARGET="aarch64-apple-ios"
IOS_SIM_TARGETS=("aarch64-apple-ios-sim" "x86_64-apple-ios")
MACOS_TARGETS=("aarch64-apple-darwin" "x86_64-apple-darwin")

# --- helpers -----------------------------------------------------------------

log() { printf '\033[1;34m[build-xcframework]\033[0m %s\n' "$*"; }
die() {
	printf '\033[1;31m[build-xcframework] ERROR:\033[0m %s\n' "$*" >&2
	exit 1
}

phase_guard() { # phase_guard <phase> <reason>
	die "Stage not yet implemented ($1). $2 Complete the corresponding phase before running this script end-to-end."
}

require() { command -v "$1" >/dev/null 2>&1 || die "required tool '$1' not found on PATH"; }

# --- preflight ---------------------------------------------------------------

[ -d "${SUBMODULE_DIR}/src" ] || die "submodule not checked out at ${SUBMODULE_DIR} — run 'git submodule update --init'"
require cargo
require rustc

log "Repo root:      ${REPO_ROOT}"
log "Submodule pin:  $(git -C "${SUBMODULE_DIR}" rev-parse HEAD)"
log "Cargo features: ${CARGO_FEATURES}"

# --- stage 1: FFI wrapper crate (Phase 3) ------------------------------------

if [ ! -f "${FFI_CRATE_DIR}/Cargo.toml" ]; then
	phase_guard "Phase 3 — FFI crate" "The C-ABI wrapper crate 'rust/mermaid-ffi' does not exist yet."
fi

# --- stage 2: cbindgen header generation + drift gate (Phase 4) --------------

# require cbindgen
# log "Generating ${HEADER_OUT} via cbindgen..."
# cbindgen --config "${FFI_CRATE_DIR}/cbindgen.toml" --crate mermaid-ffi --output "${HEADER_OUT}.new" "${FFI_CRATE_DIR}"
# if [ -f "${HEADER_OUT}" ] && ! diff -q "${HEADER_OUT}" "${HEADER_OUT}.new" >/dev/null; then
#   die "cbindgen header drift: ${HEADER_OUT} changed without an ABI-version bump (PRD §4.5.1 gate)"
# fi
# mv "${HEADER_OUT}.new" "${HEADER_OUT}"
phase_guard "Phase 4 — cbindgen header" "Header generation + drift gate are not wired yet."

# --- stage 3: cross-compile five slices (Phase 5) ----------------------------

# build_target() { # build_target <triple>
#   local triple="$1"
#   log "Building ${triple} (release, --features ${CARGO_FEATURES})..."
#   ( cd "${FFI_CRATE_DIR}" && cargo build --release --features "${CARGO_FEATURES}" --target "${triple}" )
# }
# rustup target add "${IOS_DEVICE_TARGET}" "${IOS_SIM_TARGETS[@]}" "${MACOS_TARGETS[@]}"
# build_target "${IOS_DEVICE_TARGET}"
# for t in "${IOS_SIM_TARGETS[@]}" "${MACOS_TARGETS[@]}"; do build_target "$t"; done

# --- stage 4: lipo fat slices + create-xcframework (Phase 5) ------------------

# mkdir -p "${BUILD_DIR}/ios-device" "${BUILD_DIR}/ios-sim" "${BUILD_DIR}/macos"
# cp "${FFI_CRATE_DIR}/target/${IOS_DEVICE_TARGET}/release/${LIB_NAME}" "${BUILD_DIR}/ios-device/${LIB_NAME}"
# lipo -create \
#   "${FFI_CRATE_DIR}/target/aarch64-apple-ios-sim/release/${LIB_NAME}" \
#   "${FFI_CRATE_DIR}/target/x86_64-apple-ios/release/${LIB_NAME}" \
#   -output "${BUILD_DIR}/ios-sim/${LIB_NAME}"
# lipo -create \
#   "${FFI_CRATE_DIR}/target/aarch64-apple-darwin/release/${LIB_NAME}" \
#   "${FFI_CRATE_DIR}/target/x86_64-apple-darwin/release/${LIB_NAME}" \
#   -output "${BUILD_DIR}/macos/${LIB_NAME}"
# rm -rf "${BUILD_DIR}/${XCFRAMEWORK}"
# xcodebuild -create-xcframework \
#   -library "${BUILD_DIR}/ios-device/${LIB_NAME}" -headers "$(dirname "${HEADER_OUT}")" \
#   -library "${BUILD_DIR}/ios-sim/${LIB_NAME}"    -headers "$(dirname "${HEADER_OUT}")" \
#   -library "${BUILD_DIR}/macos/${LIB_NAME}"      -headers "$(dirname "${HEADER_OUT}")" \
#   -output "${BUILD_DIR}/${XCFRAMEWORK}"

# --- stage 5: zip + LFS artifact + sha256 provenance (Phase 5) ---------------

# mkdir -p "${ARTIFACTS_DIR}"
# ( cd "${BUILD_DIR}" && ditto -c -k --keepParent "${XCFRAMEWORK}" "${ARTIFACTS_DIR}/${XCFRAMEWORK}.zip" )
# shasum -a 256 "${ARTIFACTS_DIR}/${XCFRAMEWORK}.zip" | awk '{print $1}' > "${ARTIFACTS_DIR}/${XCFRAMEWORK}.zip.sha256"
# log "Artifact: ${ARTIFACTS_DIR}/${XCFRAMEWORK}.zip ($(cat "${ARTIFACTS_DIR}/${XCFRAMEWORK}.zip.sha256"))"
phase_guard "Phase 5 — cross-compile/xcframework" "Slice build, lipo, create-xcframework, and LFS packaging are not wired yet."
