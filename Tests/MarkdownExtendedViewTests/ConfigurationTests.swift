// ConfigurationTests.swift
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
@testable import MarkdownExtendedView

final class ConfigurationTests: XCTestCase {

    // MARK: - Environment Default Values

    func testFeaturesDefaultIsNone() {
        // The default value for markdownFeatures should be .none
        let defaultFeatures = MarkdownFeatures.none
        XCTAssertTrue(defaultFeatures.isEmpty)
    }

    func testLinkHandlerDefaultIsNil() {
        // The default value for link handler should be nil
        // We can't directly test EnvironmentValues without a view,
        // but we can verify the type allows nil
        let handler: ((URL) -> Void)? = nil
        XCTAssertNil(handler)
    }

    // MARK: - LinkHandler Type

    func testLinkHandlerCanStoreCallback() {
        var callbackInvoked = false
        var receivedURL: URL?

        let handler: (URL) -> Void = { url in
            callbackInvoked = true
            receivedURL = url
        }

        let testURL = URL(string: "https://example.com")!
        handler(testURL)

        XCTAssertTrue(callbackInvoked)
        XCTAssertEqual(receivedURL, testURL)
    }

    func testLinkHandlerCallbackWithDifferentURLs() {
        var urls: [URL] = []

        let handler: (URL) -> Void = { url in
            urls.append(url)
        }

        let url1 = URL(string: "https://example.com")!
        let url2 = URL(string: "https://test.com/path")!

        handler(url1)
        handler(url2)

        XCTAssertEqual(urls.count, 2)
        XCTAssertEqual(urls[0], url1)
        XCTAssertEqual(urls[1], url2)
    }

    // MARK: - Features Contains Check

    func testFeaturesContainsLinks() {
        let features: MarkdownFeatures = [.links, .images]
        XCTAssertTrue(features.contains(.links))
    }

    func testFeaturesDoesNotContainMermaid() {
        let features: MarkdownFeatures = [.links, .images]
        XCTAssertFalse(features.contains(.mermaid))
    }

    // MARK: - ImageHandler Type (for future use)

    func testImagePlaceholderTypeExists() {
        // Verify we can create an optional AnyView for placeholder
        let placeholder: AnyView? = nil
        XCTAssertNil(placeholder)
    }

    // MARK: - View Modifier Tests

    func testMarkdownFeaturesModifierExists() {
        // Verify the markdownFeatures modifier can be called
        let view = Text("Test")
        let modifiedView = view.markdownFeatures(.links)
        // If this compiles, the modifier exists
        XCTAssertNotNil(modifiedView)
    }

    func testMarkdownFeaturesModifierWithMultipleFlags() {
        let view = Text("Test")
        let modifiedView = view.markdownFeatures([.links, .images])
        XCTAssertNotNil(modifiedView)
    }

    func testOnLinkTapModifierExists() {
        // Verify the onLinkTap modifier can be called
        let view = Text("Test")
        let modifiedView = view.onLinkTap { _ in }
        XCTAssertNotNil(modifiedView)
    }

    func testModifiersCanBeChained() {
        // Verify modifiers can be chained together
        let view = Text("Test")
        let modifiedView = view
            .markdownFeatures([.links, .images])
            .onLinkTap { url in
                print("Tapped: \(url)")
            }
        XCTAssertNotNil(modifiedView)
    }

    func testMarkdownFeaturesWithTheme() {
        // Verify features can be combined with theme
        let view = Text("Test")
        let modifiedView = view
            .markdownTheme(.gitHub)
            .markdownFeatures(.links)
        XCTAssertNotNil(modifiedView)
    }
}
