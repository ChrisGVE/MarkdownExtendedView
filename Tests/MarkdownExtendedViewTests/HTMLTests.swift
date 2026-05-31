// HTMLTests.swift
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

import XCTest
import Markdown
@testable import MarkdownExtendedView

/// Tests for the supported inline-HTML subset and `<details>` block grouping
/// (task 10).
final class HTMLTests: XCTestCase {

    private func fragments(_ markdown: String) -> [InlineFragment] {
        let document = Document(parsing: markdown)
        guard let paragraph = document.child(at: 0) as? Paragraph else {
            XCTFail("Expected a paragraph in: \(markdown)")
            return []
        }
        return InlineFlattener.fragments(for: paragraph)
    }

    private func texts(_ fragments: [InlineFragment]) -> [(String, InlineStyle)] {
        fragments.compactMap {
            if case .text(let value, let style) = $0 { return (value, style) }
            return nil
        }
    }

    // MARK: - Inline HTML formatting

    func testBoldTag() {
        let result = fragments("a <b>bold</b> b")
        XCTAssertTrue(texts(result).contains { $0.0 == "bold" && $0.1.isBold })
    }

    func testItalicAndUnderlineTags() {
        XCTAssertTrue(texts(fragments("<i>it</i>")).contains { $0.0 == "it" && $0.1.isItalic })
        XCTAssertTrue(texts(fragments("<u>under</u>")).contains { $0.0 == "under" && $0.1.isUnderline })
    }

    func testStrikethroughAndCodeTags() {
        XCTAssertTrue(texts(fragments("<del>gone</del>")).contains { $0.0 == "gone" && $0.1.isStrikethrough })
        XCTAssertTrue(texts(fragments("<kbd>Cmd</kbd>")).contains { $0.0 == "Cmd" && $0.1.isCode })
    }

    func testMarkTag() {
        XCTAssertTrue(texts(fragments("<mark>hi</mark>")).contains { $0.0 == "hi" && $0.1.isHighlight })
    }

    func testSubAndSupTags() {
        XCTAssertTrue(texts(fragments("H<sub>2</sub>O")).contains { $0.0 == "2" && $0.1.baseline == .sub })
        XCTAssertTrue(texts(fragments("x<sup>2</sup>")).contains { $0.0 == "2" && $0.1.baseline == .sup })
    }

    func testBrEmitsLineBreak() {
        let result = fragments("line<br>next")
        XCTAssertTrue(result.contains(.lineBreak))
    }

    func testNestedTagsCombineTraits() {
        let result = fragments("<b>bold <i>and italic</i></b>")
        XCTAssertTrue(texts(result).contains { $0.0 == "and italic" && $0.1.isBold && $0.1.isItalic })
    }

    func testUnknownTagDropped() {
        // The span tag is unsupported; its text content still renders, unstyled.
        let result = fragments("<span>plain</span>")
        let plain = texts(result)
        XCTAssertTrue(plain.contains { $0.0 == "plain" && $0.1 == InlineStyle() })
        XCTAssertFalse(plain.contains { $0.0.contains("<span") })
    }

    func testTagInsideMarkdownEmphasis() {
        // Inline HTML can appear inside markdown emphasis; both traits apply.
        let result = fragments("*em <u>under</u>*")
        XCTAssertTrue(texts(result).contains { $0.0 == "under" && $0.1.isItalic && $0.1.isUnderline })
    }

    // MARK: - <details> grouping

    func testDetailsGroupsIntoDisclosure() {
        let markdown = "<details>\n<summary>More</summary>\n\nHidden body.\n\n</details>"
        let document = Document(parsing: markdown)
        let nodes = MarkdownRenderer.groupBlocks(Array(document.children))
        XCTAssertEqual(nodes.count, 1)
        guard case .details(let summary, let body) = nodes.first else {
            return XCTFail("Expected a details node, got \(nodes)")
        }
        XCTAssertEqual(summary, "More")
        XCTAssertTrue(body.contains { node in
            if case .markup(let markup) = node { return markup is Paragraph }
            return false
        }, "Body markdown should be preserved inside the disclosure")
    }

    func testDetailsWithoutSummaryFallsBackToLabel() {
        let markdown = "<details>\n\nBody.\n\n</details>"
        let document = Document(parsing: markdown)
        let nodes = MarkdownRenderer.groupBlocks(Array(document.children))
        guard case .details(let summary, _) = nodes.first else {
            return XCTFail("Expected a details node")
        }
        XCTAssertEqual(summary, "Details")
    }

    func testNestedDetails() {
        let markdown = """
        <details>
        <summary>Outer</summary>

        <details>
        <summary>Inner</summary>

        Deep.

        </details>

        </details>
        """
        let document = Document(parsing: markdown)
        let nodes = MarkdownRenderer.groupBlocks(Array(document.children))
        XCTAssertEqual(nodes.count, 1)
        guard case .details(let outer, let body) = nodes.first else {
            return XCTFail("Expected outer details")
        }
        XCTAssertEqual(outer, "Outer")
        XCTAssertTrue(body.contains { node in
            if case .details(let inner, _) = node { return inner == "Inner" }
            return false
        }, "Nested details should be grouped recursively")
    }

    func testUnmatchedDetailsRendersAsBlocks() {
        let markdown = "<details>\n<summary>Open</summary>\n\nBody."
        let document = Document(parsing: markdown)
        let nodes = MarkdownRenderer.groupBlocks(Array(document.children))
        // No closing tag -> no details node; blocks pass through unchanged.
        XCTAssertFalse(nodes.contains { node in
            if case .details = node { return true }
            return false
        })
    }

    func testSelfContainedDetailsInOneBlock() {
        // Compact single-block form (no blank lines) lands in one HTMLBlock.
        let markdown = "<details><summary>Toggle</summary>\n\nInner **body**.\n</details>"
        let document = Document(parsing: markdown)
        let nodes = MarkdownRenderer.groupBlocks(Array(document.children))
        guard case .details(let summary, let body)? = nodes.first else {
            return XCTFail("Expected a details node, got \(nodes)")
        }
        XCTAssertEqual(summary, "Toggle")
        XCTAssertFalse(body.isEmpty, "Inner body should be parsed and present")
    }

    func testDetailsInnerBodyExtraction() {
        let html = "<details>\n<summary>Title</summary>\nhello world\n</details>"
        XCTAssertEqual(MarkdownRenderer.detailsInnerBody(html), "hello world")
    }

    func testNonDetailsBlocksUnaffected() {
        let markdown = "# Heading\n\nA paragraph.\n\n- item"
        let document = Document(parsing: markdown)
        let nodes = MarkdownRenderer.groupBlocks(Array(document.children))
        XCTAssertEqual(nodes.count, 3)
        XCTAssertTrue(nodes.allSatisfy { node in
            if case .markup = node { return true }
            return false
        })
    }

    // MARK: - Tag-boundary / attribute robustness

    func testSummaryWithAttributesExtracted() {
        // `<summary>` carrying attributes must still yield its label, not the
        // hardcoded "Details" fallback.
        let html = "<details>\n<summary class=\"toggle\" id=\"s1\">Open me</summary>\nbody\n</details>"
        XCTAssertEqual(MarkdownRenderer.extractSummary(html), "Open me")
    }

    func testSummaryWithAttributesGroups() {
        let markdown = "<details open>\n<summary class=\"t\">Titled</summary>\n\nHidden.\n\n</details>"
        let document = Document(parsing: markdown)
        let nodes = MarkdownRenderer.groupBlocks(Array(document.children))
        guard case .details(let summary, _)? = nodes.first else {
            return XCTFail("Expected a details node, got \(nodes)")
        }
        XCTAssertEqual(summary, "Titled")
    }

    func testSummaryLikeTagNotMatched() {
        // `<summaryx>` is a different element and must not be parsed as summary.
        let html = "<details>\n<summaryx>Nope</summaryx>\nbody\n</details>"
        XCTAssertEqual(MarkdownRenderer.extractSummary(html), "Details")
    }

    func testSummaryAttributeValueWithAngleBracket() {
        // A `>` inside a quoted attribute value must not truncate the open tag.
        let html = "<details>\n<summary title=\"a > b\">Real Label</summary>\nbody\n</details>"
        XCTAssertEqual(MarkdownRenderer.extractSummary(html), "Real Label")
    }

    func testDetailsTagFollowedByNewlineGroups() {
        // A newline immediately after the tag name is a valid boundary.
        let markdown = "<details\nopen>\n<summary>S</summary>\n\nBody.\n\n</details>"
        let document = Document(parsing: markdown)
        let nodes = MarkdownRenderer.groupBlocks(Array(document.children))
        XCTAssertTrue(nodes.contains { node in
            if case .details = node { return true }
            return false
        }, "<details\\n…> should still be recognised as a disclosure")
    }

    func testDetailsLikeTagNotGrouped() {
        // A custom `<detailspanel>` element must not be treated as `<details>`,
        // which would otherwise swallow blocks up to a later real `</details>`.
        let markdown = "<detailspanel>\nkeep\n</detailspanel>"
        let document = Document(parsing: markdown)
        let nodes = MarkdownRenderer.groupBlocks(Array(document.children))
        XCTAssertFalse(nodes.contains { node in
            if case .details = node { return true }
            return false
        }, "<detailspanel> must not be grouped as a disclosure")
    }
}
