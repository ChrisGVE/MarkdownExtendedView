// Checkbox+Helpers.swift
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

import Markdown

/// Extension to add convenience properties to the Checkbox type from swift-markdown.
public extension Checkbox {

    /// Returns `true` for both checked and unchecked checkboxes.
    ///
    /// This is useful when you need to determine if a list item is a task list item
    /// vs a regular list item (which would have `checkbox == nil`).
    var isTask: Bool {
        switch self {
        case .checked, .unchecked:
            return true
        }
    }

    /// Returns `true` if the checkbox is in the checked state.
    var isChecked: Bool {
        switch self {
        case .checked:
            return true
        case .unchecked:
            return false
        }
    }
}
