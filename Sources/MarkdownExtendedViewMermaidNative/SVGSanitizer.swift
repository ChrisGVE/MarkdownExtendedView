// SVGSanitizer.swift
// MarkdownExtendedView
//
// Copyright 2025 Christian C. Berclaz
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Foundation

/// Egress sanitizer for the vector (SVGView) display path
/// (PRD §4.7a / §5.2 / F1-AC5; CWE-20/79/918).
///
/// `SVGView` is a renderer, not a sanitizer (F-07), so before any SVG reaches
/// it the adapter neutralizes every reference that could trigger a network or
/// filesystem fetch. mmdr's emitter is already clean (fork-side T2 asserts MVP
/// SVGs never emit these); this pass is defense-in-depth against adversarial or
/// future-emitter SVG. `SVGView`'s default `SVGLinker.none` (which returns nil
/// from `load(src:)`) is a second, runtime backstop covering resource LOAD — a
/// distinct interception point from this string sanitizer, so both are kept.
///
/// `XMLDocument` is macOS-only, so this is a portable `NSRegularExpression`
/// string-scan pass that runs identically on iOS and macOS. It neutralizes:
///   1. `<image>` whose `href` OR `xlink:href` is not a `data:` URI (CWE-20 —
///      both attribute forms checked: SVG 1.1 `xlink:href`, SVG 2 `href`).
///   2. `<script>` elements (paired and self-closing).
///   3. Event-handler attributes (`onload`, `onclick`, …).
///   4. External `<use>` references — any `href`/`xlink:href` not a local
///      `#fragment` reference (CWE-918).
///   5. CSS `url()` with non-`data:` schemes in inline `style=` attributes and
///      in `<style>` block content (CWE-918/CWE-79).
public enum SVGSanitizer {

    /// Return a sanitized copy of `svg` with every non-`data:` external
    /// reference, `<script>`, and event handler neutralized. Order matters:
    /// scripts and `<style>` blocks are removed/cleaned before attribute passes
    /// so their internal `on*=`/`href=` text cannot survive as a false match.
    public static func sanitize(_ svg: String) -> String {
        var result = svg
        result = stripScripts(result)
        result = cleanStyleBlocks(result)
        result = neutralizeImageHrefs(result)
        result = neutralizeUseHrefs(result)
        result = stripEventHandlers(result)
        result = neutralizeStyleAttributeURLs(result)
        return result
    }

    // MARK: - Passes

    /// (2) Remove `<script>…</script>` and self-closing `<script .../>`.
    private static func stripScripts(_ svg: String) -> String {
        var s = replaceAll(in: svg, pattern: "<script\\b[\\s\\S]*?</script\\s*>", with: "")
        s = replaceAll(in: s, pattern: "<script\\b[^>]*/\\s*>", with: "")
        return s
    }

    /// (5a) Within each `<style>…</style>` block, strip `url(<non-data>)` tokens.
    private static func cleanStyleBlocks(_ svg: String) -> String {
        rewriteMatches(in: svg, pattern: "<style\\b[^>]*>[\\s\\S]*?</style\\s*>") { block in
            neutralizeCSSURLs(in: block)
        }
    }

    /// (1) For every `<image …>` start tag, drop any `href`/`xlink:href` whose
    /// value is not a `data:` URI.
    private static func neutralizeImageHrefs(_ svg: String) -> String {
        rewriteMatches(in: svg, pattern: "<image\\b[^>]*>") { tag in
            neutralizeHrefs(in: tag) { value in
                value.hasPrefix("data:")  // keep only data: images
            }
        }
    }

    /// (4) For every `<use …>` start tag, drop any `href`/`xlink:href` that is
    /// not a local `#fragment` reference (blocks external-document `<use>`).
    private static func neutralizeUseHrefs(_ svg: String) -> String {
        rewriteMatches(in: svg, pattern: "<use\\b[^>]*>") { tag in
            neutralizeHrefs(in: tag) { value in
                value.hasPrefix("#")  // keep only same-document fragment refs
            }
        }
    }

    /// (3) Remove every `on<event>="…"` / `on<event>='…'` attribute.
    private static func stripEventHandlers(_ svg: String) -> String {
        replaceAll(
            in: svg,
            pattern: "\\s+on[a-zA-Z]+\\s*=\\s*(\"[^\"]*\"|'[^']*')",
            with: ""
        )
    }

    /// (5b) Strip `url(<non-data>)` tokens inside inline `style="…"` / `style='…'`.
    private static func neutralizeStyleAttributeURLs(_ svg: String) -> String {
        rewriteMatches(in: svg, pattern: "\\bstyle\\s*=\\s*(\"[^\"]*\"|'[^']*')") { attr in
            neutralizeCSSURLs(in: attr)
        }
    }

    // MARK: - Helpers

    /// Drop `href` and `xlink:href` attributes within a single start-tag string
    /// whose value fails `keep`. The whole attribute (name + value) is removed
    /// so no dangling reference remains.
    private static func neutralizeHrefs(
        in tag: String,
        keep: (String) -> Bool
    ) -> String {
        rewriteMatches(
            in: tag,
            pattern: "\\s+(?:xlink:href|href)\\s*=\\s*(\"[^\"]*\"|'[^']*')"
        ) { attr in
            let value = attributeValue(from: attr)
            return keep(value) ? attr : ""
        }
    }

    /// Replace `url(<scheme>…)` with `url()` when the referenced target is not a
    /// `data:` URI (covers `http(s)://`, `file://`, protocol-relative `//`, and
    /// any other non-`data:` reference); `data:` and bare `#fragment` survive.
    private static func neutralizeCSSURLs(in css: String) -> String {
        rewriteMatches(in: css, pattern: "url\\(\\s*(['\"]?)([^'\")]*)\\1\\s*\\)") { token in
            let inner = cssURLTarget(from: token)
            if inner.hasPrefix("data:") || inner.hasPrefix("#") {
                return token
            }
            return "url()"
        }
    }

    /// Extract the quoted/unquoted value from an `name="value"` attribute slice.
    private static func attributeValue(from attribute: String) -> String {
        guard let eq = attribute.firstIndex(of: "=") else { return "" }
        var v = attribute[attribute.index(after: eq)...]
            .trimmingCharacters(in: .whitespaces)
        if let first = v.first, first == "\"" || first == "'" {
            v = String(v.dropFirst())
            if let close = v.firstIndex(of: first) {
                v = String(v[..<close])
            }
        }
        return v.trimmingCharacters(in: .whitespaces)
    }

    /// Extract the target inside a `url(...)` token.
    private static func cssURLTarget(from token: String) -> String {
        guard let open = token.firstIndex(of: "("),
              let close = token.lastIndex(of: ")")
        else { return "" }
        var inner = token[token.index(after: open)..<close]
            .trimmingCharacters(in: .whitespaces)
        if let first = inner.first, first == "\"" || first == "'" {
            inner = inner.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        }
        return inner.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Regex primitives

    /// Replace every match of `pattern` (case-insensitive, dot-matches-line)
    /// with a fixed `replacement`.
    private static func replaceAll(in input: String, pattern: String, with replacement: String) -> String {
        rewriteMatches(in: input, pattern: pattern) { _ in replacement }
    }

    /// Rewrite every match of `pattern` via `transform`, applied right-to-left
    /// so earlier match ranges stay valid. Returns the input unchanged if the
    /// pattern fails to compile (a sanitizer must never throw into the caller).
    private static func rewriteMatches(
        in input: String,
        pattern: String,
        transform: (String) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return input
        }
        var output = input
        let full = NSRange(input.startIndex..., in: input)
        let matches = regex.matches(in: input, range: full)
        for match in matches.reversed() {
            guard let range = Range(match.range, in: output) else { continue }
            let slice = String(output[range])
            output.replaceSubrange(range, with: transform(slice))
        }
        return output
    }
}
