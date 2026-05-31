// SyntaxHighlighterEnvironment.swift
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

// MARK: - Syntax Highlighter Environment

private struct SyntaxHighlighterKey: EnvironmentKey {
    static let defaultValue: any SyntaxHighlighting = SyntaxHighlighter()
}

public extension EnvironmentValues {
    /// The syntax highlighter used for code blocks.
    ///
    /// Defaults to the built-in ``SyntaxHighlighter``. Override it with
    /// ``SwiftUI/View/markdownSyntaxHighlighter(_:)`` to plug in a more capable
    /// engine (such as tree-sitter) while keeping the built-in as a fallback for
    /// languages your engine does not handle.
    var markdownSyntaxHighlighter: any SyntaxHighlighting {
        get { self[SyntaxHighlighterKey.self] }
        set { self[SyntaxHighlighterKey.self] = newValue }
    }
}

public extension View {
    /// Sets the ``SyntaxHighlighting`` engine used for code blocks in nested
    /// ``MarkdownView`` instances.
    ///
    /// ```swift
    /// MarkdownView(content)
    ///     .markdownSyntaxHighlighter(MyTreeSitterHighlighter())
    /// ```
    ///
    /// - Parameter highlighter: The highlighter to use.
    func markdownSyntaxHighlighter(_ highlighter: any SyntaxHighlighting) -> some View {
        environment(\.markdownSyntaxHighlighter, highlighter)
    }
}
