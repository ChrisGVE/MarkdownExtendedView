// MVPSnapshotTests.swift
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

import SwiftUI
import XCTest

import MarkdownExtendedView
@testable import MarkdownExtendedViewMermaidNative

/// Perceptual snapshots for the 7 MVP types × light/dark (PRD §10 T6 / D5),
/// including the first `erDiagram` reference. Renders via the deterministic PNG
/// path (tiny-skia + embedded font), so references are stable per host.
///
/// Run with `MEV_RECORD_SNAPSHOTS=1` to (re)generate the committed references;
/// the default run compares the current render against them with the perceptual
/// tolerance (SSIM ≥ 0.98, ≤ 0.5% differing pixels).
final class MVPSnapshotTests: XCTestCase {

    private var recording: Bool {
        ProcessInfo.processInfo.environment["MEV_RECORD_SNAPSHOTS"] != nil
    }

    private var fixturesDir: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
    }

    func testMVPTypesSnapshotLightAndDark() throws {
        try FileManager.default.createDirectory(at: fixturesDir, withIntermediateDirectories: true)
        var failures: [String] = []

        for c in MVPFixtures.all {
            for scheme: ColorScheme in [.light, .dark] {
                let label = "\(c.name)_\(scheme == .dark ? "dark" : "light")"
                let options = ThemeMapper.options(for: MarkdownTheme(), colorScheme: scheme)
                let result = MermaidNativeRenderer.render(code: c.source, format: .rasterPNG, options: options)
                guard case let .success(.png(png), _) = result else {
                    failures.append("[\(label)] render failed: \(result)")
                    continue
                }
                let referenceURL = fixturesDir.appendingPathComponent("\(label).png")

                if recording {
                    try png.write(to: referenceURL)
                    continue
                }

                guard let reference = try? Data(contentsOf: referenceURL) else {
                    failures.append("[\(label)] missing reference — run with MEV_RECORD_SNAPSHOTS=1")
                    continue
                }
                let comparison = PerceptualComparison.compare(candidate: png, reference: reference)
                if !comparison.passed {
                    failures.append("[\(label)] \(comparison.describe)")
                }
            }
        }

        if recording {
            // Recording always "passes" — it writes the references.
            return
        }
        XCTAssertTrue(failures.isEmpty, "snapshot mismatches:\n" + failures.joined(separator: "\n"))
    }

    /// Identical PNGs compare as a perfect pass (SSIM 1.0, 0 differing pixels) —
    /// validates the comparison harness itself.
    func testIdenticalImagesArePerfectMatch() {
        let result = MermaidNativeRenderer.render(code: "flowchart LR\nA-->B", format: .rasterPNG)
        guard case let .success(.png(png), _) = result else {
            return XCTFail("expected a PNG")
        }
        let comparison = PerceptualComparison.compare(candidate: png, reference: png)
        guard case let .pass(ssim, ratio) = comparison else {
            return XCTFail("identical PNGs must pass: \(comparison.describe)")
        }
        XCTAssertEqual(ssim, 1.0, accuracy: 0.0001)
        XCTAssertEqual(ratio, 0.0)
    }

    /// A clearly different diagram must FAIL the tolerance (harness sanity).
    func testDifferentDiagramsFailTolerance() {
        guard case let .success(.png(a), _) = MermaidNativeRenderer.render(code: "flowchart LR\nA-->B", format: .rasterPNG),
              case let .success(.png(b), _) = MermaidNativeRenderer.render(code: "pie title X\n\"A\": 1\n\"B\": 2", format: .rasterPNG)
        else {
            return XCTFail("expected two PNGs")
        }
        // Different dimensions/content → fail (dimension mismatch or below tolerance).
        XCTAssertFalse(PerceptualComparison.compare(candidate: a, reference: b).passed)
    }
}
