// SyntaxHighlightingTests.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import XCTest
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
}
