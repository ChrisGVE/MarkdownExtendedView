// LinkOpener.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Utility for opening URLs on the current platform.
enum LinkOpener {

    /// Opens a URL using the system's default handler.
    ///
    /// - On iOS: Opens in Safari (external browser)
    /// - On macOS: Opens in the default browser
    ///
    /// - Parameter url: The URL to open.
    @MainActor
    static func openInBrowser(_ url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
}
