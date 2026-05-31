// DefinitionListTests.swift
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

/// Tests for definition-list detection, grouping, and marker stripping (task 12).
final class DefinitionListTests: XCTestCase {

    private func firstParagraph(_ markdown: String) -> Paragraph {
        Document(parsing: markdown).child(at: 0) as! Paragraph
    }

    // MARK: - Detection

    func testTermWithDefinitionDetected() {
        let paragraph = firstParagraph("Apple\n: A fruit")
        XCTAssertTrue(MarkdownRenderer.isDefinitionParagraph(paragraph))
    }

    func testTermWithMultipleDefinitionsDetected() {
        let paragraph = firstParagraph("Apple\n: A fruit\n: A company")
        XCTAssertTrue(MarkdownRenderer.isDefinitionParagraph(paragraph))
    }

    func testPlainParagraphNotDetected() {
        let paragraph = firstParagraph("Just a normal paragraph of prose.")
        XCTAssertFalse(MarkdownRenderer.isDefinitionParagraph(paragraph))
    }

    func testColonNotAtLineStartNotDetected() {
        let paragraph = firstParagraph("Ratio\nis 16:9 today")
        XCTAssertFalse(MarkdownRenderer.isDefinitionParagraph(paragraph),
                       "A colon mid-line is not a definition marker")
    }

    func testLeadingColonOnlyNotDetected() {
        // First line is the colon line — no term, so not a definition list.
        let paragraph = firstParagraph(": orphan definition\n: another")
        XCTAssertFalse(MarkdownRenderer.isDefinitionParagraph(paragraph))
    }

    // MARK: - Grouping

    func testConsecutiveDefinitionsGroupedIntoOneList() {
        let markdown = "Apple\n: A fruit\n\nBanana\n: A yellow fruit"
        let document = Document(parsing: markdown)
        let nodes = MarkdownRenderer.groupBlocks(Array(document.children))
        XCTAssertEqual(nodes.count, 1, "Consecutive definition paragraphs should form one list")
        guard case .definitionList(let items) = nodes.first else {
            return XCTFail("Expected a definition list, got \(nodes)")
        }
        XCTAssertEqual(items.count, 2)
    }

    func testDefinitionListSeparatedFromProse() {
        let markdown = "Intro paragraph.\n\nTerm\n: Definition\n\nOutro paragraph."
        let document = Document(parsing: markdown)
        let nodes = MarkdownRenderer.groupBlocks(Array(document.children))
        XCTAssertEqual(nodes.count, 3)
        guard case .definitionList = nodes[1] else {
            return XCTFail("Middle node should be the definition list")
        }
    }

    // MARK: - Marker stripping

    func testStripLeadingColon() {
        let fragments: [InlineFragment] = [.text(": A fruit", InlineStyle())]
        let stripped = MarkdownRenderer.stripLeadingColon(fragments)
        XCTAssertEqual(stripped, [.text("A fruit", InlineStyle())])
    }

    func testStripLeadingColonPreservesLaterFragments() {
        let fragments: [InlineFragment] = [
            .text(":  ", InlineStyle()),
            .text("bold", InlineStyle(isBold: true)),
        ]
        let stripped = MarkdownRenderer.stripLeadingColon(fragments)
        XCTAssertEqual(stripped.first, .text("", InlineStyle()))
        XCTAssertEqual(stripped.last, .text("bold", InlineStyle(isBold: true)))
    }
}
