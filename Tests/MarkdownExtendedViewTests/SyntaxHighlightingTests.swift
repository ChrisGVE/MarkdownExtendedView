// SyntaxHighlightingTests.swift
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
import SwiftUI
import Markdown
@testable import MarkdownExtendedView

final class SyntaxHighlightingTests: XCTestCase {

    // MARK: - Parser Detection Tests

    func testParserDetectsCodeBlockWithLanguage() {
        let markdown = """
        ```swift
        let x = 5
        ```
        """
        let document = Document(parsing: markdown)

        guard let codeBlock = document.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse code block")
            return
        }

        XCTAssertEqual(codeBlock.language, "swift")
        XCTAssertEqual(codeBlock.code.trimmingCharacters(in: .whitespacesAndNewlines), "let x = 5")
    }

    func testParserDetectsCodeBlockWithoutLanguage() {
        let markdown = """
        ```
        plain code
        ```
        """
        let document = Document(parsing: markdown)

        guard let codeBlock = document.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse code block")
            return
        }

        XCTAssertNil(codeBlock.language)
    }

    func testParserDetectsCodeBlockWithPython() {
        let markdown = """
        ```python
        def hello():
            print("Hello")
        ```
        """
        let document = Document(parsing: markdown)

        guard let codeBlock = document.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse code block")
            return
        }

        XCTAssertEqual(codeBlock.language, "python")
    }

    func testParserDetectsCodeBlockWithJavaScript() {
        let markdown = """
        ```javascript
        function hello() {
            console.log("Hello");
        }
        ```
        """
        let document = Document(parsing: markdown)

        guard let codeBlock = document.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse code block")
            return
        }

        XCTAssertEqual(codeBlock.language, "javascript")
    }

    // MARK: - Feature Flag Tests

    func testSyntaxHighlightingFlagDisabledByDefault() {
        let features = MarkdownFeatures.none
        XCTAssertFalse(features.contains(.syntaxHighlighting))
    }

    func testSyntaxHighlightingCanBeEnabled() {
        let features: MarkdownFeatures = .syntaxHighlighting
        XCTAssertTrue(features.contains(.syntaxHighlighting))
    }

    func testSyntaxHighlightingInAllFeatures() {
        let features = MarkdownFeatures.all
        XCTAssertTrue(features.contains(.syntaxHighlighting))
    }

    // MARK: - Highlighter Tests

    func testSyntaxHighlighterExists() {
        let highlighter = SyntaxHighlighter()
        XCTAssertNotNil(highlighter)
    }

    func testHighlightSwiftKeywords() {
        let highlighter = SyntaxHighlighter()
        let code = "let x = 5"
        let tokens = highlighter.tokenize(code, language: "swift")

        // Should contain at least a keyword token for "let"
        let hasKeyword = tokens.contains { $0.type == .keyword }
        XCTAssertTrue(hasKeyword, "Should detect 'let' as keyword")
    }

    func testHighlightSwiftStrings() {
        let highlighter = SyntaxHighlighter()
        let code = "let message = \"Hello\""
        let tokens = highlighter.tokenize(code, language: "swift")

        let hasString = tokens.contains { $0.type == .string }
        XCTAssertTrue(hasString, "Should detect string literal")
    }

    func testHighlightSwiftComments() {
        let highlighter = SyntaxHighlighter()
        let code = "// This is a comment"
        let tokens = highlighter.tokenize(code, language: "swift")

        let hasComment = tokens.contains { $0.type == .comment }
        XCTAssertTrue(hasComment, "Should detect comment")
    }

    func testHighlightPythonKeywords() {
        let highlighter = SyntaxHighlighter()
        let code = "def hello():"
        let tokens = highlighter.tokenize(code, language: "python")

        let hasKeyword = tokens.contains { $0.type == .keyword }
        XCTAssertTrue(hasKeyword, "Should detect 'def' as keyword")
    }

    func testHighlightJavaScriptKeywords() {
        let highlighter = SyntaxHighlighter()
        let code = "function test() { return true; }"
        let tokens = highlighter.tokenize(code, language: "javascript")

        let hasKeyword = tokens.contains { $0.type == .keyword }
        XCTAssertTrue(hasKeyword, "Should detect 'function' as keyword")
    }

    func testUnknownLanguageFallback() {
        let highlighter = SyntaxHighlighter()
        let code = "some random code"
        let tokens = highlighter.tokenize(code, language: "unknown_lang")

        // Should return at least plain text token
        XCTAssertFalse(tokens.isEmpty, "Should return at least one token")
    }

    // MARK: - Color Theme Tests

    func testDefaultSyntaxColorsExist() {
        let theme = MarkdownTheme.default
        XCTAssertNotNil(theme.syntaxColors)
    }

    func testSyntaxColorsHaveKeywordColor() {
        let theme = MarkdownTheme.default
        XCTAssertNotNil(theme.syntaxColors.keyword)
    }

    func testSyntaxColorsHaveStringColor() {
        let theme = MarkdownTheme.default
        XCTAssertNotNil(theme.syntaxColors.string)
    }

    func testSyntaxColorsHaveCommentColor() {
        let theme = MarkdownTheme.default
        XCTAssertNotNil(theme.syntaxColors.comment)
    }

    func testGitHubThemeHasSyntaxColors() {
        let theme = MarkdownTheme.gitHub
        XCTAssertNotNil(theme.syntaxColors)
        XCTAssertNotNil(theme.syntaxColors.keyword)
    }

    // MARK: - Multiline Code Tests

    func testMultilineCodeBlock() {
        let markdown = """
        ```swift
        struct Person {
            let name: String
            let age: Int
        }
        ```
        """
        let document = Document(parsing: markdown)

        guard let codeBlock = document.child(at: 0) as? CodeBlock else {
            XCTFail("Failed to parse code block")
            return
        }

        XCTAssertEqual(codeBlock.language, "swift")
        XCTAssertTrue(codeBlock.code.contains("struct"))
        XCTAssertTrue(codeBlock.code.contains("let name"))
    }

    // MARK: - Pluggable Highlighter Seam

    /// A custom highlighter that marks the entire code as a single keyword token.
    private struct StubHighlighter: SyntaxHighlighting {
        func tokenize(_ code: String, language: String?) -> [Token] {
            [Token(text: code, type: .keyword)]
        }
    }

    func testBuiltInConformsToProtocol() {
        let highlighter: any SyntaxHighlighting = SyntaxHighlighter()
        let tokens = highlighter.tokenize("let x = 1", language: "swift")
        XCTAssertFalse(tokens.isEmpty)
        XCTAssertTrue(tokens.contains { $0.type == .keyword })
    }

    func testCustomHighlighterProducesItsOwnTokens() {
        let highlighter: any SyntaxHighlighting = StubHighlighter()
        let tokens = highlighter.tokenize("anything here", language: "swift")
        XCTAssertEqual(tokens.count, 1)
        XCTAssertEqual(tokens.first?.type, .keyword)
        XCTAssertEqual(tokens.first?.text, "anything here")
    }

    func testDefaultEnvironmentHighlighterIsBuiltIn() {
        let environment = EnvironmentValues()
        XCTAssertTrue(environment.markdownSyntaxHighlighter is SyntaxHighlighter)
    }
}
