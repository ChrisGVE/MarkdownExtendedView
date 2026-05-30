// InlineContentTests.swift
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

/// Tests for the inline flattener, which preserves styling across LaTeX, links,
/// and images in a single paragraph (the core of task 3).
final class InlineContentTests: XCTestCase {

    // MARK: - Helpers

    /// Flattens the first paragraph of `markdown` to fragments.
    private func fragments(_ markdown: String) -> [InlineFragment] {
        let document = Document(parsing: markdown)
        guard let paragraph = document.child(at: 0) as? Paragraph else {
            XCTFail("Expected a paragraph in: \(markdown)")
            return []
        }
        return InlineFlattener.fragments(for: paragraph)
    }

    private func latexFragments(_ fragments: [InlineFragment]) -> [(String, Bool)] {
        fragments.compactMap {
            if case .latex(let value, let isBlock) = $0 { return (value, isBlock) }
            return nil
        }
    }

    private func textFragments(_ fragments: [InlineFragment]) -> [(String, InlineStyle)] {
        fragments.compactMap {
            if case .text(let value, let style) = $0 { return (value, style) }
            return nil
        }
    }

    // MARK: - Styling preserved alongside LaTeX

    func testBoldPreservedWithLaTeX() {
        let result = fragments("**bold** $x$")
        // Bold run must survive.
        XCTAssertTrue(textFragments(result).contains { $0.0 == "bold" && $0.1.isBold },
                      "Bold text must be preserved when the paragraph also contains LaTeX")
        // LaTeX must still be recognised.
        XCTAssertEqual(latexFragments(result).map { $0.0 }, ["x"])
    }

    func testItalicPreservedWithLaTeX() {
        let result = fragments("*emph* and $y^2$")
        XCTAssertTrue(textFragments(result).contains { $0.0 == "emph" && $0.1.isItalic })
        XCTAssertEqual(latexFragments(result).map { $0.0 }, ["y^2"])
    }

    func testInlineCodePreservedWithLaTeX() {
        let result = fragments("`code` $x$")
        XCTAssertTrue(textFragments(result).contains { $0.0 == "code" && $0.1.isCode },
                      "Inline code must be preserved alongside LaTeX")
        XCTAssertEqual(latexFragments(result).map { $0.0 }, ["x"])
    }

    func testStrikethroughPreserved() {
        let result = fragments("~~gone~~")
        XCTAssertTrue(textFragments(result).contains { $0.0 == "gone" && $0.1.isStrikethrough })
    }

    // MARK: - Links

    func testLinkPreservedWithLaTeX() {
        let result = fragments("[site](https://example.com) $x$")
        let links = result.compactMap { fragment -> (String?, [InlineFragment])? in
            if case .link(let dest, let content) = fragment { return (dest, content) }
            return nil
        }
        XCTAssertEqual(links.count, 1)
        XCTAssertEqual(links.first?.0, "https://example.com")
        XCTAssertEqual(latexFragments(result).map { $0.0 }, ["x"])
    }

    func testStyledLinkKeepsLinkAndStyle() {
        let result = fragments("[**bold link**](https://example.com)")
        guard case .link(let destination, let content)? = result.first else {
            return XCTFail("Expected a link fragment, got \(result)")
        }
        XCTAssertEqual(destination, "https://example.com")
        XCTAssertTrue(content.contains { fragment in
            if case .text(let value, let style) = fragment { return value == "bold link" && style.isBold }
            return false
        }, "Link content must keep bold styling")
    }

    // MARK: - Images

    func testImagePreservedWithStyledText() {
        let result = fragments("*caption* ![alt text](image.png)")
        XCTAssertTrue(textFragments(result).contains { $0.0 == "caption" && $0.1.isItalic })
        XCTAssertTrue(result.contains { fragment in
            if case .image(let source, let alt) = fragment {
                return source == "image.png" && alt == "alt text"
            }
            return false
        })
    }

    // MARK: - Breaks

    func testSoftBreakBetweenLines() {
        let result = fragments("line one\nline two")
        XCTAssertTrue(result.contains(.softBreak))
        XCTAssertTrue(textFragments(result).contains { $0.0 == "line one" })
        XCTAssertTrue(textFragments(result).contains { $0.0 == "line two" })
    }

    func testHardLineBreak() {
        let result = fragments("line one  \nline two")
        XCTAssertTrue(result.contains(.lineBreak))
    }

    // MARK: - Cross-node LaTeX

    func testLaTeXJoinedAcrossMarkdownEmphasisSplit() {
        // "a*b*c" makes markdown parse "*b*" as emphasis, splitting the text node.
        // The math scanner must still recover a single equation across those runs.
        let result = fragments("$a*b*c$")
        XCTAssertEqual(latexFragments(result).count, 1, "Math split by markdown emphasis must join into one equation")
        XCTAssertFalse(textFragments(result).contains { $0.0.contains("$") },
                       "No stray dollar delimiters should remain as text")
    }

    func testSubscriptUnderscoresStayInOneEquation() {
        // Intraword underscores are not emphasis in CommonMark, so this stays one
        // text node — but verify the equation is intact.
        let result = fragments("$a_1 + a_2$")
        XCTAssertEqual(latexFragments(result).map { $0.0 }, ["a_1 + a_2"])
    }

    // MARK: - Plain styling (no special inline)

    func testPlainBoldRun() {
        let result = fragments("Hello **world**")
        XCTAssertEqual(textFragments(result).map { $0.0 }, ["Hello ", "world"])
        XCTAssertTrue(textFragments(result).last?.1.isBold == true)
    }

    func testDisplayMathInline() {
        let result = fragments("before $$x^2$$ after")
        XCTAssertEqual(latexFragments(result).map { $0.1 }, [true], "Display math should be marked as block")
        XCTAssertEqual(latexFragments(result).map { $0.0 }, ["x^2"])
    }

    // MARK: - Combined styling

    func testNestedBoldItalic() {
        let result = fragments("***both***")
        XCTAssertTrue(textFragments(result).contains { $0.1.isBold && $0.1.isItalic },
                      "Nested strong+emphasis should carry both traits")
    }
}
