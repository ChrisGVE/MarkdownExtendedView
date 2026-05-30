// MarkdownFeaturesTests.swift
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

final class MarkdownFeaturesTests: XCTestCase {

    // MARK: - Individual Flags

    func testLinksFlag() {
        let features: MarkdownFeatures = .links
        XCTAssertTrue(features.contains(.links))
        XCTAssertFalse(features.contains(.images))
        XCTAssertFalse(features.contains(.mermaid))
    }

    func testImagesFlag() {
        let features: MarkdownFeatures = .images
        XCTAssertFalse(features.contains(.links))
        XCTAssertTrue(features.contains(.images))
        XCTAssertFalse(features.contains(.mermaid))
    }

    func testMermaidFlag() {
        let features: MarkdownFeatures = .mermaid
        XCTAssertFalse(features.contains(.links))
        XCTAssertFalse(features.contains(.images))
        XCTAssertTrue(features.contains(.mermaid))
    }

    // MARK: - Combined Flags

    func testCombinedFlags() {
        let features: MarkdownFeatures = [.links, .images]
        XCTAssertTrue(features.contains(.links))
        XCTAssertTrue(features.contains(.images))
        XCTAssertFalse(features.contains(.mermaid))
    }

    func testUnionOfFlags() {
        let features1: MarkdownFeatures = .links
        let features2: MarkdownFeatures = .images
        let combined = features1.union(features2)
        XCTAssertTrue(combined.contains(.links))
        XCTAssertTrue(combined.contains(.images))
    }

    func testIntersectionOfFlags() {
        let features1: MarkdownFeatures = [.links, .images]
        let features2: MarkdownFeatures = [.images, .mermaid]
        let intersection = features1.intersection(features2)
        XCTAssertFalse(intersection.contains(.links))
        XCTAssertTrue(intersection.contains(.images))
        XCTAssertFalse(intersection.contains(.mermaid))
    }

    // MARK: - None and All Constants

    func testNoneConstant() {
        let features: MarkdownFeatures = .none
        XCTAssertTrue(features.isEmpty)
        XCTAssertFalse(features.contains(.links))
        XCTAssertFalse(features.contains(.images))
        XCTAssertFalse(features.contains(.mermaid))
    }

    func testAllConstant() {
        let features: MarkdownFeatures = .all
        XCTAssertTrue(features.contains(.links))
        XCTAssertTrue(features.contains(.images))
        XCTAssertTrue(features.contains(.mermaid))
    }

    // MARK: - Equality

    func testEquality() {
        let features1: MarkdownFeatures = [.links, .images]
        let features2: MarkdownFeatures = [.links, .images]
        XCTAssertEqual(features1, features2)
    }

    func testInequality() {
        let features1: MarkdownFeatures = [.links, .images]
        let features2: MarkdownFeatures = [.links, .mermaid]
        XCTAssertNotEqual(features1, features2)
    }

    // MARK: - Raw Value

    func testRawValueRoundTrip() {
        let original: MarkdownFeatures = [.links, .mermaid]
        let rawValue = original.rawValue
        let restored = MarkdownFeatures(rawValue: rawValue)
        XCTAssertEqual(original, restored)
    }
}
