# MarkdownExtendedView

A native SwiftUI Markdown renderer with LaTeX equation support.

## Features

- **GitHub Flavored Markdown** parsing via Apple's swift-markdown
- **LaTeX equations** rendered natively via SwiftMath
  - Inline math: `$...$`
  - Display math: `$$...$$`
- **Theming system** with built-in themes (default, gitHub, compact)
- **Cross-platform** support for iOS 16+ and macOS 13+
- **Pure SwiftUI** - no WebViews or JavaScript

## Supported Markdown Elements

- Headings (H1-H6)
- Paragraphs with inline formatting (bold, italic, strikethrough, code)
- Ordered and unordered lists
- Code blocks with syntax highlighting support
- Block quotes
- Tables (GFM)
- Links and images
- Thematic breaks

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ChrisGVE/MarkdownExtendedView.git", from: "1.0.0")
]
```

## Usage

```swift
import SwiftUI
import MarkdownExtendedView

struct ContentView: View {
    var body: some View {
        MarkdownView("""
            # Hello World

            This is **bold** and this is *italic*.

            Inline equation: $E = mc^2$

            Display equation:
            $$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}$$
        """)
    }
}
```

### Theming

```swift
MarkdownView(content)
    .markdownTheme(.gitHub)
```

Available themes:
- `.default` - Clean, readable defaults
- `.gitHub` - GitHub-style rendering
- `.compact` - Reduced spacing for dense content

### Custom Theme

```swift
var customTheme = MarkdownTheme.default
customTheme.headingColor = .blue
customTheme.linkColor = .purple

MarkdownView(content)
    .markdownTheme(customTheme)
```

## Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 5.9+
- Xcode 15.0+

## Dependencies

- [swift-markdown](https://github.com/apple/swift-markdown) - Apple's Markdown parser
- [SwiftMath](https://github.com/mgriebling/SwiftMath) - Native LaTeX rendering

## License

Proprietary - Copyright (c) 2025 Christian C. Berclaz. All rights reserved.
