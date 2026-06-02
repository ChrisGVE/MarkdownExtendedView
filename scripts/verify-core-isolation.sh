#!/bin/bash
#
# verify-core-isolation.sh — the T9 core-isolation gate (PRD §4.6 / F3-AC4).
#
# Branch A keeps the core `MarkdownExtendedView` product binary- and
# dependency-free: the prebuilt Rust binary (`CMermaidFFI`), the native module
# (`MarkdownExtendedViewMermaidNative`), and `SVGView` live ONLY in the optional
# opt-in product, which the manifest includes ONLY when `MEV_MERMAID_NATIVE` is
# set (the xcframework is an uncommitted build product, so an unconditional
# binary target would break a fresh-clone core build — see Package.swift).
#
# This gate proves the isolation four ways:
#   1. No core Swift source imports `Cmmdr` or the native module.
#   2. With the env var UNSET, the package manifest is core-only — it declares
#      neither the native product/target nor the binary target.
#   3. With the env var UNSET *and the xcframework physically absent*, the core
#      product still builds — proving it needs no binary artifact and no Rust
#      toolchain (the fresh-clone / external-consumer guarantee).
#   4. With the env var SET (native product present), the core target's
#      dependency graph still names neither the binary nor the native target.
#
# If any check fails, Branch A's clean opt-in split has regressed.
#
# Usage: ./scripts/verify-core-isolation.sh
# Exit:  0 = isolated (Branch A holds), 1 = leak (core couples to the binary).

set -euo pipefail

if [ ! -f "Package.swift" ]; then
	echo "Error: must be run from the package root" >&2
	exit 1
fi

CORE_TARGET="MarkdownExtendedView"
NATIVE_TARGET="MarkdownExtendedViewMermaidNative"
BINARY_TARGET="CMermaidFFI"
XCFRAMEWORK="Artifacts/MermaidFFI.xcframework"
fail=0

# Ensure the native env var does not leak in from the caller for the core-only
# checks (1–3); check 4 sets it explicitly.
unset MEV_MERMAID_NATIVE || true

# --- 1. no native imports in core source -------------------------------------
if grep -rnE '^[[:space:]]*import (Cmmdr|'"$NATIVE_TARGET"')([[:space:]]|$)' \
	"Sources/$CORE_TARGET/" --include='*.swift'; then
	echo "::error::core source imports the native module / Cmmdr — isolation leak" >&2
	fail=1
else
	echo "isolation 1/4: core imports no native module / Cmmdr — OK"
fi

# --- 2. core-only manifest when the env var is unset -------------------------
manifest_leak=$(swift package describe --type json | python3 -c '
import json, sys
d = json.load(sys.stdin)
bad = []
for p in d["products"]:
    if p["name"] == "'"$NATIVE_TARGET"'":
        bad.append("product:" + p["name"])
for t in d["targets"]:
    if t["name"] in ("'"$BINARY_TARGET"'", "'"$NATIVE_TARGET"'"):
        bad.append("target:" + t["name"])
print(",".join(bad))
')
if [ -n "$manifest_leak" ]; then
	echo "::error::core-only manifest still declares [$manifest_leak] — env-gate broken" >&2
	fail=1
else
	echo "isolation 2/4: core-only manifest declares no native product/target/binary — OK"
fi

# --- 3. core product builds with the xcframework physically absent -----------
moved=0
if [ -e "$XCFRAMEWORK" ]; then
	mv "$XCFRAMEWORK" "${XCFRAMEWORK}.isolation-bak"
	moved=1
fi
if swift build --product "$CORE_TARGET" >/tmp/core-iso-build.log 2>&1; then
	echo "isolation 3/4: core product builds with the binary artifact absent — OK"
else
	echo "::error::core product failed to build without the binary artifact — isolation leak" >&2
	tail -10 /tmp/core-iso-build.log >&2
	fail=1
fi
[ "$moved" -eq 1 ] && mv "${XCFRAMEWORK}.isolation-bak" "$XCFRAMEWORK"

# --- 4. with the native product present, core's dep graph excludes it --------
if [ -e "$XCFRAMEWORK" ]; then
	graph_leak=$(MEV_MERMAID_NATIVE=1 swift package describe --type json | python3 -c '
import json, sys
d = json.load(sys.stdin)
bad = []
for t in d["targets"]:
    if t["name"] == "'"$CORE_TARGET"'":
        for dep in t.get("target_dependencies", []) or []:
            if dep in ("'"$BINARY_TARGET"'", "'"$NATIVE_TARGET"'"):
                bad.append(dep)
print(",".join(bad))
')
	if [ -n "$graph_leak" ]; then
		echo "::error::with native enabled, core target depends on [$graph_leak] — isolation leak" >&2
		fail=1
	else
		echo "isolation 4/4: with native enabled, core dependency graph excludes it — OK"
	fi
else
	echo "isolation 4/4: SKIPPED (no xcframework on disk; build it via scripts/build-xcframework.sh to run)"
fi

if [ "$fail" -ne 0 ]; then
	echo "verify-core-isolation: FAILED (Branch A isolation regressed)" >&2
	exit 1
fi

echo "verify-core-isolation: passed (T9 — core product is binary- and dependency-free)"
