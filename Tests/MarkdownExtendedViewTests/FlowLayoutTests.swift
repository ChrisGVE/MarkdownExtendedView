// FlowLayoutTests.swift
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

/// Tests for ``FlowLayout``'s pure line-breaking core (task 4 wrapping).
final class FlowLayoutTests: XCTestCase {

    private func size(_ w: CGFloat, _ h: CGFloat) -> CGSize { CGSize(width: w, height: h) }

    func testItemsFitOnOneLine() {
        let sizes = [size(50, 10), size(50, 10), size(50, 10)]
        let result = FlowLayout.frames(forItemSizes: sizes, maxWidth: 200, spacing: 0)
        XCTAssertEqual(result.positions.map { $0.y }, [0, 0, 0], "All items should be on the first line")
        XCTAssertEqual(result.positions.map { $0.x }, [0, 50, 100])
        XCTAssertEqual(result.totalSize, size(150, 10))
    }

    func testWrapsWhenExceedingWidth() {
        // Three 100-wide items, container 250 -> two per line.
        let sizes = [size(100, 10), size(100, 10), size(100, 10)]
        let result = FlowLayout.frames(forItemSizes: sizes, maxWidth: 250, spacing: 0)
        XCTAssertEqual(result.positions[0], CGPoint(x: 0, y: 0))
        XCTAssertEqual(result.positions[1], CGPoint(x: 100, y: 0))
        // Third does not fit (200 + 100 > 250) -> wraps to second line.
        XCTAssertEqual(result.positions[2], CGPoint(x: 0, y: 10))
        XCTAssertEqual(result.totalSize.height, 20)
        XCTAssertLessThanOrEqual(result.totalSize.width, 250)
    }

    func testReportedWidthNeverExceedsContainer() {
        // A single item wider than the container must not report an overflowing
        // width (it is expected to wrap its own content instead).
        let sizes = [size(400, 10)]
        let result = FlowLayout.frames(forItemSizes: sizes, maxWidth: 250, spacing: 0)
        XCTAssertEqual(result.positions[0], CGPoint(x: 0, y: 0))
        XCTAssertLessThanOrEqual(result.totalSize.width, 250)
    }

    func testSpacingApplied() {
        let sizes = [size(50, 10), size(50, 20)]
        let result = FlowLayout.frames(forItemSizes: sizes, maxWidth: 200, spacing: 8)
        XCTAssertEqual(result.positions[1].x, 58, "Second item should be offset by width + spacing")
        XCTAssertEqual(result.totalSize.height, 20, "Line height is the tallest item")
    }

    func testInfiniteWidthKeepsSingleLine() {
        let sizes = [size(100, 10), size(100, 10), size(100, 10)]
        let result = FlowLayout.frames(forItemSizes: sizes, maxWidth: .infinity, spacing: 0)
        XCTAssertEqual(result.positions.map { $0.y }, [0, 0, 0])
        XCTAssertEqual(result.totalSize.width, 300)
    }

    func testEmptyInput() {
        let result = FlowLayout.frames(forItemSizes: [], maxWidth: 200, spacing: 0)
        XCTAssertTrue(result.positions.isEmpty)
        XCTAssertEqual(result.totalSize, .zero)
    }

    func testMultipleLinesHeightAccumulates() {
        // Four 100-wide items in a 200 container -> 2 lines of height 10 each.
        let sizes = [size(100, 10), size(100, 10), size(100, 10), size(100, 10)]
        let result = FlowLayout.frames(forItemSizes: sizes, maxWidth: 200, spacing: 0)
        XCTAssertEqual(result.positions[2], CGPoint(x: 0, y: 10))
        XCTAssertEqual(result.positions[3], CGPoint(x: 100, y: 10))
        XCTAssertEqual(result.totalSize.height, 20)
    }
}
