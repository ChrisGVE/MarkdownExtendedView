#!/bin/bash
#
# webkit-guard.sh
#
# Fails if `import WebKit` (or a WKWebView reference) appears in any Swift
# source outside the single allowed file. This is the Phase-0 guardrail for the
# native WebView-free Mermaid renderer epic (task 18): it prevents new WebKit
# usage from creeping into the library while the native path is developed, and
# becomes the enforcement that the WebKit path is fully gone after Phase 9.
#
# Phase 9 (Task 12) removed the WebKit path entirely, so WebKit is now forbidden
# ANYWHERE in Sources/ — the package is WebView-free (F4-AC1).
#
# Usage: ./scripts/webkit-guard.sh
# Exit:  0 = clean, 1 = unauthorized WebKit usage found.
#

set -euo pipefail

# Files permitted to import WebKit — empty after Phase 9 (WebView removed).
ALLOWED=()

if [ ! -f "Package.swift" ]; then
	echo "Error: must be run from the package root" >&2
	exit 1
fi

is_allowed() {
	local f="$1"
	# No files are permitted to import WebKit after Phase 9.
	[ "${#ALLOWED[@]}" -eq 0 ] && return 1
	for a in "${ALLOWED[@]}"; do
		[ "$f" = "$a" ] && return 0
	done
	return 1
}

violations=0
# Match the `import WebKit` statement (leading whitespace allowed). Guarding the
# import is necessary and sufficient: WKWebView cannot be referenced without it,
# and matching only the import avoids false positives on prose/doc-comment
# mentions of "WKWebView" (e.g. Features.swift describes the WebView path).
while IFS= read -r file; do
	[ -z "$file" ] && continue
	if ! is_allowed "$file"; then
		echo "ERROR: unauthorized 'import WebKit' in $file" >&2
		violations=$((violations + 1))
	fi
done < <(grep -rlE '^[[:space:]]*import WebKit([[:space:]]|$)' Sources/ --include='*.swift' || true)

if [ "$violations" -gt 0 ]; then
	echo "webkit-guard: FAILED ($violations file(s))" >&2
	exit 1
fi

echo "webkit-guard: passed (WebKit confined to: ${ALLOWED[*]:-<none>})"
