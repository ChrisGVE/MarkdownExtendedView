// LinkTests.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import XCTest
import Markdown
@testable import MarkdownExtendedView

final class LinkTests: XCTestCase {

    // MARK: - Parser Detection Tests

    func testParserDetectsLink() {
        let markdown = "This is a [link](https://example.com)."
        let document = Document(parsing: markdown)

        guard let paragraph = document.child(at: 0) as? Paragraph else {
            XCTFail("Failed to parse paragraph")
            return
        }

        // Find the link in children
        var foundLink = false
        for child in paragraph.children {
            if let link = child as? Markdown.Link {
                foundLink = true
                XCTAssertEqual(link.destination, "https://example.com")
                XCTAssertEqual(link.plainText, "link")
            }
        }
        XCTAssertTrue(foundLink, "Should find link in paragraph")
    }

    func testParserDetectsLinkWithTitle() {
        let markdown = "[link](https://example.com \"Example Title\")"
        let document = Document(parsing: markdown)

        guard let paragraph = document.child(at: 0) as? Paragraph else {
            XCTFail("Failed to parse paragraph")
            return
        }

        guard let link = paragraph.child(at: 0) as? Markdown.Link else {
            XCTFail("Failed to find link")
            return
        }

        XCTAssertEqual(link.destination, "https://example.com")
        XCTAssertEqual(link.title, "Example Title")
    }

    func testParserDetectsAutolink() {
        let markdown = "<https://example.com>"
        let document = Document(parsing: markdown)

        guard let paragraph = document.child(at: 0) as? Paragraph else {
            XCTFail("Failed to parse paragraph")
            return
        }

        // Autolinks become Link nodes in swift-markdown
        var foundLink = false
        for child in paragraph.children {
            if let link = child as? Markdown.Link {
                foundLink = true
                XCTAssertEqual(link.destination, "https://example.com")
            }
        }
        XCTAssertTrue(foundLink, "Should find autolink")
    }

    func testParserDetectsEmailAutolink() {
        let markdown = "<test@example.com>"
        let document = Document(parsing: markdown)

        guard let paragraph = document.child(at: 0) as? Paragraph else {
            XCTFail("Failed to parse paragraph")
            return
        }

        // Email autolinks also become Link nodes
        var foundLink = false
        for child in paragraph.children {
            if let link = child as? Markdown.Link {
                foundLink = true
                XCTAssertTrue(link.destination?.contains("mailto:") == true || link.destination?.contains("test@example.com") == true)
            }
        }
        XCTAssertTrue(foundLink, "Should find email autolink")
    }

    // MARK: - Feature Flag Tests

    func testLinksFlagDisabledByDefault() {
        let features = MarkdownFeatures.none
        XCTAssertFalse(features.contains(.links))
    }

    func testLinksCanBeEnabled() {
        let features: MarkdownFeatures = .links
        XCTAssertTrue(features.contains(.links))
    }

    func testLinksInAllFeatures() {
        let features = MarkdownFeatures.all
        XCTAssertTrue(features.contains(.links))
    }

    // MARK: - URL Validation Tests

    func testValidHTTPSURL() {
        let urlString = "https://example.com"
        let url = URL(string: urlString)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
    }

    func testValidHTTPURL() {
        let urlString = "http://example.com"
        let url = URL(string: urlString)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "http")
    }

    func testValidMailtoURL() {
        let urlString = "mailto:test@example.com"
        let url = URL(string: urlString)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "mailto")
    }

    func testRelativeURL() {
        let urlString = "/path/to/page"
        let url = URL(string: urlString)
        XCTAssertNotNil(url)
        XCTAssertNil(url?.scheme)
    }

    // MARK: - Link with Formatting Tests

    func testLinkWithBoldText() {
        let markdown = "[**bold link**](https://example.com)"
        let document = Document(parsing: markdown)

        guard let paragraph = document.child(at: 0) as? Paragraph,
              let link = paragraph.child(at: 0) as? Markdown.Link else {
            XCTFail("Failed to parse")
            return
        }

        XCTAssertEqual(link.destination, "https://example.com")
        // Check that link contains Strong element
        var foundStrong = false
        for child in link.children {
            if child is Strong { foundStrong = true }
        }
        XCTAssertTrue(foundStrong, "Link should contain Strong element")
    }

    func testLinkWithInlineCode() {
        let markdown = "[`code link`](https://example.com)"
        let document = Document(parsing: markdown)

        guard let paragraph = document.child(at: 0) as? Paragraph,
              let link = paragraph.child(at: 0) as? Markdown.Link else {
            XCTFail("Failed to parse")
            return
        }

        XCTAssertEqual(link.destination, "https://example.com")
        // Check that link contains InlineCode element
        var foundCode = false
        for child in link.children {
            if child is InlineCode { foundCode = true }
        }
        XCTAssertTrue(foundCode, "Link should contain InlineCode element")
    }

    // MARK: - Multiple Links Tests

    func testMultipleLinksInParagraph() {
        let markdown = "Visit [Google](https://google.com) or [Apple](https://apple.com)."
        let document = Document(parsing: markdown)

        guard let paragraph = document.child(at: 0) as? Paragraph else {
            XCTFail("Failed to parse paragraph")
            return
        }

        var linkCount = 0
        var destinations: [String] = []
        for child in paragraph.children {
            if let link = child as? Markdown.Link, let dest = link.destination {
                linkCount += 1
                destinations.append(dest)
            }
        }

        XCTAssertEqual(linkCount, 2)
        XCTAssertTrue(destinations.contains("https://google.com"))
        XCTAssertTrue(destinations.contains("https://apple.com"))
    }
}
