// LinkTests.swift
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

    // MARK: - Reference-Style Links

    func testFullReferenceLinkResolves() {
        let markdown = "See [the site][ref].\n\n[ref]: https://example.com"
        let document = Document(parsing: markdown)
        let destinations = collectLinkDestinations(document)
        XCTAssertEqual(destinations, ["https://example.com"],
                       "Full reference link [text][ref] should resolve to its definition")
    }

    func testCollapsedReferenceLinkResolves() {
        let markdown = "See [ref][].\n\n[ref]: https://example.com"
        let document = Document(parsing: markdown)
        XCTAssertEqual(collectLinkDestinations(document), ["https://example.com"],
                       "Collapsed reference link [ref][] should resolve")
    }

    func testShortcutReferenceLinkResolves() {
        let markdown = "See [shortcut].\n\n[shortcut]: https://short.example.com \"Title\""
        let document = Document(parsing: markdown)
        XCTAssertEqual(collectLinkDestinations(document), ["https://short.example.com"],
                       "Shortcut reference link [shortcut] should resolve")
    }

    func testReferenceLinkProducesLinkFragment() {
        let markdown = "Text with a [the site][ref] link.\n\n[ref]: https://example.com"
        let document = Document(parsing: markdown)
        guard let paragraph = document.child(at: 0) as? Paragraph else {
            return XCTFail("Expected a paragraph")
        }
        let fragments = InlineFlattener.fragments(for: paragraph)
        let hasResolvedLink = fragments.contains { fragment in
            if case .link(let destination, _) = fragment { return destination == "https://example.com" }
            return false
        }
        XCTAssertTrue(hasResolvedLink, "Reference links must flatten to a resolved link fragment")
    }

    /// Collects all link destinations in document order.
    private func collectLinkDestinations(_ markup: any Markup) -> [String] {
        var destinations: [String] = []
        func walk(_ node: any Markup) {
            if let link = node as? Markdown.Link, let destination = link.destination {
                destinations.append(destination)
            }
            for child in node.children { walk(child) }
        }
        walk(markup)
        return destinations
    }

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

    // MARK: - Default-handler scheme allowlist (untrusted-markdown hardening)

    func testSafeSchemesAreOpenable() {
        for raw in ["https://example.com", "http://example.com", "mailto:a@b.com", "tel:+15551234"] {
            let url = URL(string: raw)!
            XCTAssertTrue(TappableLinkView.isOpenableScheme(url), "\(raw) should be openable")
        }
    }

    func testDangerousSchemesAreNotOpenable() {
        for raw in ["javascript:alert(1)", "file:///etc/passwd", "data:text/html,x",
                    "shortcuts://run", "x-custom://payload"] {
            let url = URL(string: raw)!
            XCTAssertFalse(TappableLinkView.isOpenableScheme(url),
                           "\(raw) must not be opened by the default handler")
        }
    }
}
