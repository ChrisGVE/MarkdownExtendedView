// MermaidRendererRegistryTests.swift
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

@testable import MarkdownExtendedView

/// The core↔native registry seam (PRD §4.6). These tests live in the CORE test
/// target and use a dummy renderer — proving the seam works with no dependency
/// on the native product (the dependency-free-core invariant).
final class MermaidRendererRegistryTests: XCTestCase {

    /// A core-only stand-in renderer (no binary, no SVGView).
    private struct DummyRenderer: MermaidRendering {
        let id: Int
        @MainActor
        func makeDiagramView(
            code: String,
            theme: MarkdownTheme,
            colorScheme: ColorScheme,
            availableWidth: CGFloat?
        ) -> AnyView {
            AnyView(Text("dummy-\(id)"))
        }
    }

    func testFreshRegistryHasNoRenderer() {
        let registry = MermaidRendererRegistry()
        XCTAssertNil(registry.current, "a fresh registry must default to nil (source-text safe default)")
    }

    func testRegisterThenCurrentReturnsRenderer() {
        let registry = MermaidRendererRegistry()
        registry.register(DummyRenderer(id: 1))
        XCTAssertNotNil(registry.current)
    }

    func testRegisterIsIdempotentReplacement() {
        let registry = MermaidRendererRegistry()
        registry.register(DummyRenderer(id: 1))
        registry.register(DummyRenderer(id: 2))
        let current = registry.current as? DummyRenderer
        XCTAssertEqual(current?.id, 2, "the latest registration wins")
    }

    func testResetRestoresSafeDefault() {
        let registry = MermaidRendererRegistry()
        registry.register(DummyRenderer(id: 1))
        registry.reset()
        XCTAssertNil(registry.current)
    }

    /// NF-01 AC: register off-main (any thread) while reading on MainActor — no
    /// data race, the value is observed.
    func testRegisterFromDetachedTaskReadOnMainActor() async {
        let registry = MermaidRendererRegistry()
        await Task.detached {
            registry.register(DummyRenderer(id: 7))
        }.value
        let current = await MainActor.run { registry.current as? DummyRenderer }
        XCTAssertEqual(current?.id, 7)
    }

    /// Concurrent registrations + reads must not crash or deadlock (lock smoke).
    func testConcurrentRegisterAndReadDoesNotRace() async {
        let registry = MermaidRendererRegistry()
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<200 {
                group.addTask { registry.register(DummyRenderer(id: i)) }
                group.addTask { _ = registry.current }
            }
        }
        XCTAssertNotNil(registry.current)
    }

    @MainActor
    func testRendererVendsAView() {
        let registry = MermaidRendererRegistry()
        registry.register(DummyRenderer(id: 3))
        let view = registry.current?.makeDiagramView(
            code: "flowchart LR\nA-->B",
            theme: MarkdownTheme(),
            colorScheme: .light,
            availableWidth: 320
        )
        XCTAssertNotNil(view)
    }
}
