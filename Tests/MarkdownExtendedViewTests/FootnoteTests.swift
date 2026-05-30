// FootnoteTests.swift
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
@testable import MarkdownExtendedView

final class FootnoteTests: XCTestCase {

    // MARK: - Footnote Detection Tests

    func testDetectsInlineFootnoteReference() {
        let markdown = "This has a footnote[^1] in the text."
        let preprocessor = FootnotePreprocessor()
        let result = preprocessor.process(markdown)

        XCTAssertTrue(result.hasFootnotes)
        XCTAssertEqual(result.footnoteCount, 1)
    }

    func testDetectsFootnoteDefinition() {
        let markdown = """
        Text with footnote[^1].

        [^1]: This is the footnote content.
        """
        let preprocessor = FootnotePreprocessor()
        let result = preprocessor.process(markdown)

        XCTAssertTrue(result.hasFootnotes)
        XCTAssertEqual(result.footnoteCount, 1)
        XCTAssertNotNil(result.footnotes["1"])
        XCTAssertEqual(result.footnotes["1"], "This is the footnote content.")
    }

    func testDetectsMultipleFootnotes() {
        let markdown = """
        First footnote[^1] and second[^2].

        [^1]: First definition.
        [^2]: Second definition.
        """
        let preprocessor = FootnotePreprocessor()
        let result = preprocessor.process(markdown)

        XCTAssertEqual(result.footnoteCount, 2)
        XCTAssertEqual(result.footnotes["1"], "First definition.")
        XCTAssertEqual(result.footnotes["2"], "Second definition.")
    }

    func testDetectsNamedFootnotes() {
        let markdown = """
        Reference to note[^note-name].

        [^note-name]: Named footnote content.
        """
        let preprocessor = FootnotePreprocessor()
        let result = preprocessor.process(markdown)

        XCTAssertEqual(result.footnoteCount, 1)
        XCTAssertNotNil(result.footnotes["note-name"])
    }

    // MARK: - Footnote Transformation Tests

    func testReplacesFootnoteWithSuperscript() {
        let markdown = "Text[^1] here."
        let preprocessor = FootnotePreprocessor()
        let result = preprocessor.process(markdown)

        // The processed markdown should contain a superscript marker
        XCTAssertTrue(result.processedMarkdown.contains("¹"))
    }

    func testAppendsFootnotesSection() {
        let markdown = """
        Text with footnote[^1].

        [^1]: The footnote content.
        """
        let preprocessor = FootnotePreprocessor()
        let result = preprocessor.process(markdown)

        // Should contain a footnotes section
        XCTAssertTrue(result.processedMarkdown.contains("---"))
        XCTAssertTrue(result.processedMarkdown.contains("The footnote content"))
    }

    func testPreservesOriginalContentWithoutFootnotes() {
        let markdown = "Just regular markdown with **bold** and *italic*."
        let preprocessor = FootnotePreprocessor()
        let result = preprocessor.process(markdown)

        XCTAssertFalse(result.hasFootnotes)
        XCTAssertEqual(result.processedMarkdown, markdown)
    }

    // MARK: - Multi-line Footnote Tests

    func testHandlesMultilineFootnote() {
        let markdown = """
        Text[^1].

        [^1]: First line of footnote.
            Second line continues.
            Third line too.
        """
        let preprocessor = FootnotePreprocessor()
        let result = preprocessor.process(markdown)

        let footnoteContent = result.footnotes["1"] ?? ""
        XCTAssertTrue(footnoteContent.contains("First line"))
        XCTAssertTrue(footnoteContent.contains("Second line"))
    }

    // MARK: - Edge Cases

    func testHandlesFootnoteWithoutDefinition() {
        let markdown = "Reference[^missing] without definition."
        let preprocessor = FootnotePreprocessor()
        let result = preprocessor.process(markdown)

        // Should still process but mark as undefined
        XCTAssertTrue(result.hasFootnotes)
    }

    func testHandlesDefinitionWithoutReference() {
        let markdown = """
        No reference in text.

        [^orphan]: This footnote is never referenced.
        """
        let preprocessor = FootnotePreprocessor()
        let result = preprocessor.process(markdown)

        // Definition exists but shouldn't appear in rendered footnotes
        XCTAssertNotNil(result.footnotes["orphan"])
    }

    func testHandlesFootnoteInCodeBlock() {
        let markdown = """
        ```
        [^1]: This is not a footnote, it's code
        ```

        Real footnote[^1].

        [^1]: Real definition.
        """
        let preprocessor = FootnotePreprocessor()
        let result = preprocessor.process(markdown)

        // Should not treat code block content as footnote definition
        XCTAssertEqual(result.footnoteCount, 1)
    }

    func testFootnoteNumbering() {
        let markdown = """
        First[^a] and second[^b] and third[^c].

        [^a]: Alpha.
        [^b]: Beta.
        [^c]: Gamma.
        """
        let preprocessor = FootnotePreprocessor()
        let result = preprocessor.process(markdown)

        // Should number footnotes in order of first appearance
        XCTAssertTrue(result.processedMarkdown.contains("¹"))
        XCTAssertTrue(result.processedMarkdown.contains("²"))
        XCTAssertTrue(result.processedMarkdown.contains("³"))
    }

    func testFootnoteNumberingFollowsAppearanceOrder() {
        let markdown = """
        First[^a] and second[^b] and third[^c].

        [^a]: Alpha.
        [^b]: Beta.
        [^c]: Gamma.
        """
        let preprocessor = FootnotePreprocessor()
        let result = preprocessor.process(markdown)
        let out = result.processedMarkdown

        // The first reference in the text must be numbered 1, second 2, third 3.
        XCTAssertTrue(out.contains("First¹"), "first reference should become ¹, got: \(out)")
        XCTAssertTrue(out.contains("second²"), "second reference should become ²")
        XCTAssertTrue(out.contains("third³"), "third reference should become ³")

        // The appended footnotes section must list definitions in numbered order.
        guard let alpha = out.range(of: "Alpha"),
              let beta = out.range(of: "Beta"),
              let gamma = out.range(of: "Gamma") else {
            return XCTFail("footnote definitions missing from output")
        }
        XCTAssertTrue(alpha.lowerBound < beta.lowerBound, "Alpha (¹) must be listed before Beta (²)")
        XCTAssertTrue(beta.lowerBound < gamma.lowerBound, "Beta (²) must be listed before Gamma (³)")
    }

    // MARK: - Feature Flag Tests

    func testFootnotesDisabledByDefault() {
        let features = MarkdownFeatures.none
        XCTAssertFalse(features.contains(.footnotes))
    }

    func testFootnotesCanBeEnabled() {
        let features: MarkdownFeatures = .footnotes
        XCTAssertTrue(features.contains(.footnotes))
    }

    func testFootnotesInAllFeatures() {
        let features = MarkdownFeatures.all
        XCTAssertTrue(features.contains(.footnotes))
    }
}
