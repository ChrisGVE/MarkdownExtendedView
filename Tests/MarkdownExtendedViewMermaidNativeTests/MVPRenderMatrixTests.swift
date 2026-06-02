// MVPRenderMatrixTests.swift
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

@testable import MarkdownExtendedViewMermaidNative

/// Both render paths produce valid output for all 7 MVP types (PRD D4 / Task 19).
final class MVPRenderMatrixTests: XCTestCase {

    private static let pngMagic: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]

    func testEveryMVPTypeRendersToSVG() {
        for c in MVPFixtures.all {
            let result = MermaidNativeRenderer.render(code: c.source, format: .vectorSVG)
            guard case let .success(.svg(svg), _) = result else {
                XCTFail("[\(c.name)] expected SVG success, got \(result)")
                continue
            }
            XCTAssertTrue(svg.contains("<svg"), "[\(c.name)] payload should be SVG markup")
            // Egress-clean even before the Swift sanitizer (fork baseline, F1-AC5).
            let sanitized = SVGSanitizer.sanitize(svg)
            XCTAssertFalse(sanitized.contains("href=\"http"), "[\(c.name)] external href leaked")
        }
    }

    func testEveryMVPTypeRendersToPNG() {
        for c in MVPFixtures.all {
            let result = MermaidNativeRenderer.render(code: c.source, format: .rasterPNG)
            guard case let .success(.png(data), _) = result else {
                XCTFail("[\(c.name)] expected PNG success, got \(result)")
                continue
            }
            XCTAssertEqual(Array(data.prefix(8)), Self.pngMagic, "[\(c.name)] payload should be a PNG")
            XCTAssertGreaterThan(data.count, 8, "[\(c.name)] PNG should carry pixel data")
        }
    }
}
