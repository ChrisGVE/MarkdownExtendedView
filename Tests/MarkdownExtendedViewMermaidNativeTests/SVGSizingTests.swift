// SVGSizingTests.swift
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

import CoreGraphics
import XCTest

@testable import MarkdownExtendedViewMermaidNative

/// Intrinsic-sizing helpers for the native display path (PRD F6). Task 16
/// extends this with the T13 narrow-container assertion.
final class SVGSizingTests: XCTestCase {

    func testViewBoxExtractionReturnsWidthHeightAspect() {
        let svg = #"<svg viewBox="0 0 320 160" width="100%"><rect/></svg>"#
        let size = SVGSizing.intrinsicSize(fromSVG: svg)
        XCTAssertEqual(size?.width, 320)
        XCTAssertEqual(size?.height, 160)
        XCTAssertEqual(size?.aspectRatio ?? 0, 2.0, accuracy: 0.0001)
    }

    func testFallsBackToWidthHeightAttributesWithoutViewBox() {
        let svg = #"<svg width="240px" height="120px"><rect/></svg>"#
        let size = SVGSizing.intrinsicSize(fromSVG: svg)
        XCTAssertEqual(size?.width, 240)
        XCTAssertEqual(size?.height, 120)
    }

    func testNoDimensionsReturnsNil() {
        XCTAssertNil(SVGSizing.intrinsicSize(fromSVG: "<svg><rect/></svg>"))
        XCTAssertNil(SVGSizing.intrinsicSize(fromSVG: ""))
    }

    func testDisplayHeightFollowsAspectAboveFloor() {
        let size = SVGIntrinsicSize(width: 200, height: 100) // aspect 2:1
        // 600 wide / 2.0 = 300, well above the floor.
        XCTAssertEqual(SVGSizing.displayHeight(for: size, availableWidth: 600), 300, accuracy: 0.0001)
    }

    func testDisplayHeightRespects80ptFloor() {
        let size = SVGIntrinsicSize(width: 200, height: 20) // very wide/short, aspect 10:1
        // 300 wide / 10 = 30 → floored to 80 (F6-AC5).
        XCTAssertEqual(SVGSizing.displayHeight(for: size, availableWidth: 300), SVGSizing.minimumHeight)
    }

    func testDisplayHeightFloorWhenSizeUnknown() {
        XCTAssertEqual(SVGSizing.displayHeight(for: nil, availableWidth: 400), SVGSizing.minimumHeight)
    }
}

/// End-to-end egress: a REAL mmdr render of an MVP diagram, run through the
/// sanitizer, carries no external reference (defense-in-depth over the already
/// clean fork-side baseline — PRD F1-AC5) and yields a usable intrinsic size.
final class NativeRenderEgressTests: XCTestCase {

    func testRenderedMVPSVGIsEgressFreeAndSized() {
        let result = MermaidNativeRenderer.render(code: "flowchart LR\nA-->B", format: .vectorSVG)
        guard case let .success(.svg(svg), _) = result else {
            return XCTFail("expected an SVG success, got \(result)")
        }
        let sanitized = SVGSanitizer.sanitize(svg)
        // No fetchable external reference. `xmlns="http://www.w3.org/2000/svg"`
        // is a namespace identifier (never fetched), so we assert on href/url()
        // egress surfaces rather than on a bare "http://" substring.
        XCTAssertFalse(sanitized.contains("href=\"http"))
        XCTAssertFalse(sanitized.contains("href='http"))
        XCTAssertFalse(sanitized.lowercased().contains("url(http"))
        XCTAssertFalse(sanitized.lowercased().contains("<script"))
        XCTAssertNotNil(SVGSizing.intrinsicSize(fromSVG: sanitized), "rendered SVG should carry a viewBox/size")
    }
}
