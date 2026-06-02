// MermaidRenderGuard.swift
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

import Cmmdr
import Foundation

/// DoS bounds for the native render path (PRD §4.3 / §5.6 / T7).
///
/// Three layers:
///   1. **Source-size cap (Swift, pre-FFI):** sources over 256 KB are rejected
///      immediately, before any FFI call or byte copy.
///   2. **Node cap (FFI):** the wrapper enforces a 5000-node bound pre-layout
///      (`MmdrOptions.max_nodes` default) — the TRUE compute bound; an oversized
///      diagram returns `ErrTooLarge` → `.renderError`.
///   3. **Perceived-latency timeout (Swift):** a slow render is ABANDONED after
///      the deadline and mapped to `.renderError("render timed out")` WITHOUT
///      relying on any Rust status (Rust has no MVP deadline — §13-D10). The
///      pinned worker keeps running until Rust returns (honest scope), but the
///      UI is freed at the deadline.
public enum MermaidRenderGuard {

    /// Source-size cap in bytes (256 KB), matching the FFI default
    /// (`DEFAULT_MAX_SOURCE_BYTES`). The Swift check avoids even copying an
    /// oversized source across the FFI.
    public static let maxSourceBytes = 262_144

    /// Default perceived-latency deadline. Simulators are slower, so they get a
    /// more generous budget than a device.
    public static var defaultTimeoutSeconds: Double {
        #if targetEnvironment(simulator)
        return 5.0
        #else
        return 2.0
        #endif
    }

    /// Render `code` with all three DoS layers applied. Runs the FFI off the
    /// calling actor and races it against the deadline.
    public static func render(
        code: String,
        format: MermaidDisplayFormat,
        options: MmdrOptions? = nil,
        timeoutSeconds: Double = defaultTimeoutSeconds
    ) async -> MermaidRenderResult {
        // Layer 1: source-size cap (no FFI call when exceeded).
        guard code.utf8.count <= maxSourceBytes else {
            return .renderError(message: "Diagram source too large (max 256 KB).")
        }

        // Cache hit avoids re-running Rust entirely (PR7 / MF-5).
        let key = MermaidCacheKey(source: code, options: options, format: format)
        if let cached = MermaidRenderCache.shared.get(key) {
            return cached
        }

        // Layers 2 + 3: off-actor FFI render (node cap inside) raced against
        // the perceived-latency deadline. A nil outcome means the deadline
        // elapsed first (detected structurally — no string match).
        let outcome = await withDeadline(seconds: timeoutSeconds) {
            await Task.detached(priority: .userInitiated) {
                MermaidNativeRenderer.render(code: code, format: format, options: options)
            }.value
        }

        guard let result = outcome else {
            // Transient timeout: surface it but NEVER cache it, so a one-off
            // slow render cannot make a diagram permanently fail for the session.
            return .renderError(message: "Render timed out.")
        }
        MermaidRenderCache.shared.set(key, result)
        return result
    }

    /// Synchronous cache lookup (no FFI). The view uses this to seed its state
    /// so a repeat of the same source+inputs displays with NO placeholder
    /// transition (T12 sync cache-hit).
    public static func cachedResult(
        code: String,
        format: MermaidDisplayFormat,
        options: MmdrOptions?
    ) -> MermaidRenderResult? {
        MermaidRenderCache.shared.get(MermaidCacheKey(source: code, options: options, format: format))
    }

    /// Run `operation`, returning its value if it finishes within `seconds`,
    /// else `nil` (the deadline elapsed first). The losing child is cancelled
    /// (the synchronous FFI render cannot be interrupted and runs to completion
    /// in the background — honest scope, §4.3). A non-finite or non-positive
    /// `seconds` is treated as "no deadline" (operation always wins).
    static func withDeadline<T: Sendable>(
        seconds: Double,
        operation: @escaping @Sendable () async -> T
    ) async -> T? {
        // Clamp: a public caller could pass .infinity/.nan/negative; UInt64(.nan)
        // / UInt64(.infinity) would trap. Non-finite/≤0 ⇒ effectively unbounded.
        let nanos: UInt64 = seconds.isFinite && seconds > 0
            ? UInt64(min(seconds, 86_400) * 1_000_000_000)
            : UInt64.max
        return await withTaskGroup(of: T?.self) { group in
            group.addTask { await operation() }
            group.addTask {
                try? await Task.sleep(nanoseconds: nanos)
                return nil
            }
            defer { group.cancelAll() }
            // The first child to finish decides the outcome (value, or nil = timeout).
            if let next = await group.next() {
                return next
            }
            return nil
        }
    }

    /// Convenience: `operation`'s value, or `onTimeout()` if the deadline elapses.
    static func withTimeout<T: Sendable>(
        seconds: Double,
        operation: @escaping @Sendable () async -> T,
        onTimeout: @Sendable () -> T
    ) async -> T {
        await withDeadline(seconds: seconds, operation: operation) ?? onTimeout()
    }
}
