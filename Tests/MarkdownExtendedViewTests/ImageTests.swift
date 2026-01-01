// ImageTests.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import XCTest
import Markdown
@testable import MarkdownExtendedView

final class ImageTests: XCTestCase {

    // MARK: - Parser Detection Tests

    func testParserDetectsImage() {
        let markdown = "![Alt text](https://example.com/image.png)"
        let document = Document(parsing: markdown)

        guard let paragraph = document.child(at: 0) as? Paragraph else {
            XCTFail("Failed to parse paragraph")
            return
        }

        guard let image = paragraph.child(at: 0) as? Markdown.Image else {
            XCTFail("Failed to find image")
            return
        }

        XCTAssertEqual(image.source, "https://example.com/image.png")
        XCTAssertEqual(image.plainText, "Alt text")
    }

    func testParserDetectsImageWithTitle() {
        let markdown = "![Alt text](https://example.com/image.png \"Image Title\")"
        let document = Document(parsing: markdown)

        guard let paragraph = document.child(at: 0) as? Paragraph,
              let image = paragraph.child(at: 0) as? Markdown.Image else {
            XCTFail("Failed to parse")
            return
        }

        XCTAssertEqual(image.source, "https://example.com/image.png")
        XCTAssertEqual(image.title, "Image Title")
    }

    func testParserDetectsImageWithEmptyAlt() {
        let markdown = "![](https://example.com/image.png)"
        let document = Document(parsing: markdown)

        guard let paragraph = document.child(at: 0) as? Paragraph,
              let image = paragraph.child(at: 0) as? Markdown.Image else {
            XCTFail("Failed to parse")
            return
        }

        XCTAssertEqual(image.source, "https://example.com/image.png")
        XCTAssertEqual(image.plainText, "")
    }

    // MARK: - Feature Flag Tests

    func testImagesFlagDisabledByDefault() {
        let features = MarkdownFeatures.none
        XCTAssertFalse(features.contains(.images))
    }

    func testImagesCanBeEnabled() {
        let features: MarkdownFeatures = .images
        XCTAssertTrue(features.contains(.images))
    }

    func testImagesInAllFeatures() {
        let features = MarkdownFeatures.all
        XCTAssertTrue(features.contains(.images))
    }

    // MARK: - URL Validation Tests

    func testValidImageURL() {
        let urlString = "https://example.com/image.png"
        let url = URL(string: urlString)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "https")
        XCTAssertTrue(url?.pathExtension == "png")
    }

    func testLocalFileURL() {
        let urlString = "file:///path/to/image.png"
        let url = URL(string: urlString)
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.scheme, "file")
    }

    func testRelativeImagePath() {
        let urlString = "images/photo.jpg"
        let url = URL(string: urlString)
        XCTAssertNotNil(url)
        XCTAssertNil(url?.scheme)
    }

    // MARK: - Multiple Images Tests

    func testMultipleImagesInDocument() {
        let markdown = """
        ![First](https://example.com/1.png)

        ![Second](https://example.com/2.png)
        """
        let document = Document(parsing: markdown)

        var imageCount = 0
        for child in document.children {
            if let paragraph = child as? Paragraph {
                for pChild in paragraph.children {
                    if pChild is Markdown.Image {
                        imageCount += 1
                    }
                }
            }
        }

        XCTAssertEqual(imageCount, 2)
    }

    // MARK: - Image in Context Tests

    func testImageInParagraph() {
        let markdown = "Here is an image: ![photo](https://example.com/photo.jpg) in text."
        let document = Document(parsing: markdown)

        guard let paragraph = document.child(at: 0) as? Paragraph else {
            XCTFail("Failed to parse paragraph")
            return
        }

        var foundImage = false
        var foundText = false
        for child in paragraph.children {
            if child is Markdown.Image { foundImage = true }
            if child is Markdown.Text { foundText = true }
        }

        XCTAssertTrue(foundImage, "Should find image")
        XCTAssertTrue(foundText, "Should find text around image")
    }

    func testImageInLink() {
        let markdown = "[![Alt](https://example.com/img.png)](https://example.com)"
        let document = Document(parsing: markdown)

        guard let paragraph = document.child(at: 0) as? Paragraph,
              let link = paragraph.child(at: 0) as? Markdown.Link else {
            XCTFail("Failed to parse")
            return
        }

        var foundImage = false
        for child in link.children {
            if child is Markdown.Image { foundImage = true }
        }

        XCTAssertTrue(foundImage, "Link should contain image")
        XCTAssertEqual(link.destination, "https://example.com")
    }
}
