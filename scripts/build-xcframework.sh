#!/usr/bin/env bash
#
# build-xcframework.sh — assemble MermaidFFI.xcframework from the Rust fork.
#
# Drives the full native-mermaid build chain (PRD §4.4 / §4.5.1):
#   - Stage 2: cbindgen header-drift gate against the committed mmdr.h.
#   - Stage 3: cross-compile the `mermaid-ffi` staticlib for five Apple triples
#              with the correct per-target deployment-version floor.
#   - Stage 4: lipo the fat simulator + macOS slices and run
#              `xcodebuild -create-xcframework` over the three slices.
#   - Stage 5: zip the framework + record its SHA-256 provenance (the Git-LFS
#              commit of the zip is the separate §4.5.1 release step).
#
# The `mermaid-ffi` wrapper depends on the fork with `features = ["png"]`
# unconditionally (the raster path is always compiled in MVP), so NO
# `--features png` flag is passed here — an SVG-only build variant is deferred
# (§13-D11). resvg/usvg are pinned `default-features = false, features =
# ["text"]`, so `system-fonts`/`fontconfig` never enter the iOS link graph.
#
# Reference: PRD §4.4 (cross-compile), §4.5/§4.5.1 (packaging + release protocol).

set -euo pipefail

# --- configuration -----------------------------------------------------------

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FFI_CRATE_DIR="${REPO_ROOT}/rust/mermaid-ffi"
SUBMODULE_DIR="${REPO_ROOT}/rust/mermaid-rs-renderer"
HEADER_DIR="${FFI_CRATE_DIR}/include" # carries mmdr.h + module.modulemap
HEADER_OUT="${HEADER_DIR}/mmdr.h"
BUILD_DIR="${REPO_ROOT}/.build/xcframework"
ARTIFACTS_DIR="${REPO_ROOT}/Artifacts"
XCFRAMEWORK="MermaidFFI.xcframework"
LIB_NAME="libmermaid_ffi.a"

# Per-slice deployment floors (PRD §4.4): mismatch = App Store rejection.
IOS_DEPLOYMENT_TARGET="16.0"
MACOS_DEPLOYMENT_TARGET="13.0"

# iOS-device arm64 stripped-slice size ceiling (PRD §7 PR5, dual-format).
IOS_DEVICE_SIZE_CEILING_MB=11

# Five build slices: iOS-device single-arch, iOS-sim fat, macOS fat.
IOS_DEVICE_TARGET="aarch64-apple-ios"
IOS_SIM_TARGETS=("aarch64-apple-ios-sim" "x86_64-apple-ios")
MACOS_TARGETS=("aarch64-apple-darwin" "x86_64-apple-darwin")

# --- helpers -----------------------------------------------------------------

log() { printf '\033[1;34m[build-xcframework]\033[0m %s\n' "$*"; }
die() {
	printf '\033[1;31m[build-xcframework] ERROR:\033[0m %s\n' "$*" >&2
	exit 1
}
require() { command -v "$1" >/dev/null 2>&1 || die "required tool '$1' not found on PATH"; }

# Deployment-target env for a triple, echoed as `NAME=value`.
deployment_env_for() {
	case "$1" in
	*-apple-ios | *-apple-ios-sim) echo "IPHONEOS_DEPLOYMENT_TARGET=${IOS_DEPLOYMENT_TARGET}" ;;
	*-apple-darwin) echo "MACOSX_DEPLOYMENT_TARGET=${MACOS_DEPLOYMENT_TARGET}" ;;
	*) die "unknown triple class: $1" ;;
	esac
}

build_target() { # build_target <triple>
	local triple="$1" env_kv
	env_kv="$(deployment_env_for "${triple}")"
	log "Building ${triple} (release, ${env_kv})..."
	(cd "${FFI_CRATE_DIR}" && env "${env_kv}" cargo build --release --target "${triple}")
	local lib="${FFI_CRATE_DIR}/target/${triple}/release/${LIB_NAME}"
	[ -f "${lib}" ] || die "expected staticlib not produced: ${lib}"
}

# --- preflight ---------------------------------------------------------------

[ -d "${SUBMODULE_DIR}/src" ] || die "submodule not checked out at ${SUBMODULE_DIR} — run 'git submodule update --init'"
[ -f "${FFI_CRATE_DIR}/Cargo.toml" ] || die "FFI crate missing at ${FFI_CRATE_DIR}"
require cargo
require rustc
require cbindgen
require lipo
require xcodebuild
require shasum

log "Repo root:      ${REPO_ROOT}"
log "Submodule pin:  $(git -C "${SUBMODULE_DIR}" rev-parse HEAD)"

# --- stage 2: cbindgen header-drift gate -------------------------------------

log "Checking cbindgen header drift against committed ${HEADER_OUT}..."
HEADER_TMP="$(mktemp)"
trap 'rm -f "${HEADER_TMP}"' EXIT
cbindgen --config "${FFI_CRATE_DIR}/cbindgen.toml" --crate mermaid-ffi --output "${HEADER_TMP}" "${FFI_CRATE_DIR}" 2>/dev/null
if ! diff -q "${HEADER_OUT}" "${HEADER_TMP}" >/dev/null; then
	die "cbindgen header drift: ${HEADER_OUT} differs from the regenerated header. Regenerate it and bump MmdrResult.abi_version if the layout changed (PRD §4.3 drift gate)."
fi
log "Header in sync."

# --- stage 3: cross-compile five slices --------------------------------------

log "Ensuring Rust targets are installed..."
rustup target add "${IOS_DEVICE_TARGET}" "${IOS_SIM_TARGETS[@]}" "${MACOS_TARGETS[@]}" >/dev/null

build_target "${IOS_DEVICE_TARGET}"
for t in "${IOS_SIM_TARGETS[@]}" "${MACOS_TARGETS[@]}"; do build_target "$t"; done

# --- stage 4: lipo fat slices + create-xcframework ---------------------------

log "Assembling slices..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/ios-device" "${BUILD_DIR}/ios-sim" "${BUILD_DIR}/macos"

cp "${FFI_CRATE_DIR}/target/${IOS_DEVICE_TARGET}/release/${LIB_NAME}" "${BUILD_DIR}/ios-device/${LIB_NAME}"
lipo -create \
	"${FFI_CRATE_DIR}/target/aarch64-apple-ios-sim/release/${LIB_NAME}" \
	"${FFI_CRATE_DIR}/target/x86_64-apple-ios/release/${LIB_NAME}" \
	-output "${BUILD_DIR}/ios-sim/${LIB_NAME}"
lipo -create \
	"${FFI_CRATE_DIR}/target/aarch64-apple-darwin/release/${LIB_NAME}" \
	"${FFI_CRATE_DIR}/target/x86_64-apple-darwin/release/${LIB_NAME}" \
	-output "${BUILD_DIR}/macos/${LIB_NAME}"

log "Running xcodebuild -create-xcframework..."
rm -rf "${BUILD_DIR}/${XCFRAMEWORK}"
xcodebuild -create-xcframework \
	-library "${BUILD_DIR}/ios-device/${LIB_NAME}" -headers "${HEADER_DIR}" \
	-library "${BUILD_DIR}/ios-sim/${LIB_NAME}" -headers "${HEADER_DIR}" \
	-library "${BUILD_DIR}/macos/${LIB_NAME}" -headers "${HEADER_DIR}" \
	-output "${BUILD_DIR}/${XCFRAMEWORK}"

# --- stage 5: zip + sha256 provenance ----------------------------------------

mkdir -p "${ARTIFACTS_DIR}"
(cd "${BUILD_DIR}" && ditto -c -k --keepParent "${XCFRAMEWORK}" "${ARTIFACTS_DIR}/${XCFRAMEWORK}.zip")
shasum -a 256 "${ARTIFACTS_DIR}/${XCFRAMEWORK}.zip" | awk '{print $1}' >"${ARTIFACTS_DIR}/${XCFRAMEWORK}.zip.sha256"
log "Artifact: ${ARTIFACTS_DIR}/${XCFRAMEWORK}.zip"
log "SHA-256:  $(cat "${ARTIFACTS_DIR}/${XCFRAMEWORK}.zip.sha256")"

log "Build complete. Slice sizes:"
du -h "${BUILD_DIR}/ios-device/${LIB_NAME}" "${BUILD_DIR}/ios-sim/${LIB_NAME}" "${BUILD_DIR}/macos/${LIB_NAME}" | sed 's/^/  /'
