// MermaidRendererRegistry.swift
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
import os

/// The core↔native injection seam for native Mermaid rendering (PRD §4.6, F-01).
///
/// Core declares ONLY this protocol, the registry, and the environment override.
/// It never names or imports the native renderer, the prebuilt binary, or
/// SVGView — that keeps the core `MarkdownExtendedView` product dependency- and
/// binary-free (the architectural invariant, PRD line 80; gated by T9).
///
/// **Why this vends a View rather than a data result.** §4.6 sketched a
/// `-> MermaidRenderResult` surface, but the DEFAULT display format is vector
/// SVG, which only the native product can display (via SVGView). Returning SVG
/// *data* to core would force core to render it — i.e. to import an SVG
/// renderer — breaking the dependency-free-core invariant. So the seam vends a
/// fully-built, displayed view: the native side owns the render → sanitize →
/// SVGView/PNG display → F2 fallback → a11y pipeline, and core simply embeds the
/// result. Core stays agnostic of svg/png entirely.
public protocol MermaidRendering: Sendable {
    /// Build the displayed diagram view for `code`, resolved for the given
    /// theme and color scheme. `availableWidth` is the container width when
    /// known (else nil). Runs on the main actor (SwiftUI view construction).
    @MainActor
    func makeDiagramView(
        code: String,
        theme: MarkdownTheme,
        colorScheme: ColorScheme,
        availableWidth: CGFloat?
    ) -> AnyView
}

/// Process-wide registry holding the optional native renderer (PRD §4.6).
///
/// Swift-6 strict-concurrency clean (arch NF-01): the renderer slot is guarded
/// by an `OSAllocatedUnfairLock` (iOS16/macOS13-available), so an off-main
/// `register(_:)` and the `MainActor` read in `MermaidView` never race. An
/// `actor` is rejected because it would force the SwiftUI read path to be
/// `async`. The type is `final` and `Sendable`; the stored renderer is `Sendable`.
public final class MermaidRendererRegistry: Sendable {

    /// The shared, process-wide registry consulted by `MermaidView`.
    public static let shared = MermaidRendererRegistry()

    private let slot = OSAllocatedUnfairLock<(any MermaidRendering)?>(initialState: nil)

    public init() {}

    /// Register (or replace) the native renderer. Idempotent; safe from any
    /// thread. The canonical opt-in is the native product's
    /// `enableNativeMermaidRendering()` (NF-05).
    public func register(_ renderer: any MermaidRendering) {
        slot.withLock { $0 = renderer }
    }

    /// Remove any registered renderer (restores the source-text safe default).
    public func reset() {
        slot.withLock { $0 = nil }
    }

    /// The currently registered renderer, or nil (source-text safe default).
    public var current: (any MermaidRendering)? {
        slot.withLock { $0 }
    }
}

// MARK: - Per-view environment override

private struct MermaidRendererKey: EnvironmentKey {
    static let defaultValue: (any MermaidRendering)? = nil
}

public extension EnvironmentValues {
    /// A per-subtree renderer override. Documented precedence (PRD §4.6): an
    /// injected renderer takes precedence over the process-wide registry for
    /// that subtree; absent both, the source-text safe default applies.
    var mermaidRenderer: (any MermaidRendering)? {
        get { self[MermaidRendererKey.self] }
        set { self[MermaidRendererKey.self] = newValue }
    }
}

public extension View {
    /// Inject a native Mermaid renderer for this view subtree, overriding the
    /// process-wide registry (PRD §4.6 env override).
    func mermaidRenderer(_ renderer: (any MermaidRendering)?) -> some View {
        environment(\.mermaidRenderer, renderer)
    }
}
