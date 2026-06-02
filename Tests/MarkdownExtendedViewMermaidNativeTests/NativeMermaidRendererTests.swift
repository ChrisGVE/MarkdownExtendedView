// NativeMermaidRendererTests.swift
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

/// Phase 8 / Task 11 wire-in: the optional product registers a renderer into
/// core's seam, and that renderer vends a displayed diagram view.
final class NativeMermaidRendererTests: XCTestCase {

    override func tearDown() {
        MermaidRendererRegistry.shared.reset()
        super.tearDown()
    }

    func testEnableRegistersANativeRenderer() {
        XCTAssertNil(MermaidRendererRegistry.shared.current)
        enableNativeMermaidRendering()
        XCTAssertTrue(MermaidRendererRegistry.shared.current is NativeMermaidRenderer)
    }

    func testEnableIsIdempotent() {
        enableNativeMermaidRendering()
        enableNativeMermaidRendering(format: .rasterPNG)
        let current = MermaidRendererRegistry.shared.current as? NativeMermaidRenderer
        XCTAssertEqual(current?.format, .rasterPNG, "the latest opt-in wins")
    }

    func testDefaultFormatIsVectorSVG() {
        XCTAssertEqual(NativeMermaidRenderer().format, .vectorSVG)
    }

    @MainActor
    func testRendererVendsADiagramView() {
        let renderer = NativeMermaidRenderer()
        let view = renderer.makeDiagramView(
            code: "flowchart LR\nA-->B",
            theme: MarkdownTheme(),
            colorScheme: .light,
            availableWidth: 320
        )
        // A non-optional AnyView is always produced (never nil / never a crash).
        _ = view
    }
}
