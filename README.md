# MarkdownExtendedView

[![Swift Package Index](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChrisGVE%2FMarkdownExtendedView%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ChrisGVE/MarkdownExtendedView)
[![Swift Package Index](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FChrisGVE%2FMarkdownExtendedView%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ChrisGVE/MarkdownExtendedView)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS 16+](https://img.shields.io/badge/iOS-16%2B-blue.svg)](https://developer.apple.com/ios/)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue.svg)](https://developer.apple.com/macos/)

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

| Element | Syntax | Status |
|---------|--------|--------|
| Headings | `# H1` through `###### H6` | Supported |
| Bold | `**text**` or `__text__` | Supported |
| Italic | `*text*` or `_text_` | Supported |
| Strikethrough | `~~text~~` | Supported |
| Inline code | `` `code` `` | Supported |
| Code blocks | ` ``` ` fenced blocks | Supported |
| Block quotes | `> quote` | Supported |
| Ordered lists | `1. item` | Supported |
| Unordered lists | `- item` or `* item` | Supported |
| Tables | GFM pipe tables | Supported |
| Links | `[text](url)` | Styled (not clickable) |
| Images | `![alt](url)` | Alt text only |
| Thematic breaks | `---` or `***` | Supported |
| Inline LaTeX | `$E=mc^2$` | Supported |
| Display LaTeX | `$$...$$` | Supported |

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ChrisGVE/MarkdownExtendedView.git", from: "1.0.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["MarkdownExtendedView"]
)
```

Or in Xcode: File > Add Package Dependencies and enter the repository URL.

## Usage

```swift
import SwiftUI
import MarkdownExtendedView

struct ContentView: View {
    var body: some View {
        ScrollView {
            MarkdownView("""
                # Hello World

                This is **bold** and this is *italic*.

                Inline equation: $E = mc^2$

                Display equation:
                $$\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}$$
            """)
            .padding()
        }
    }
}
```

### Theming

```swift
MarkdownView(content)
    .markdownTheme(.gitHub)
```

Available themes:
- `.default` - Clean, readable defaults that adapt to system appearance
- `.gitHub` - GitHub-style rendering with specific font sizes
- `.compact` - Reduced spacing for dense content

### Custom Theme

Create a custom theme by modifying any of the available properties:

```swift
var customTheme = MarkdownTheme.default

// Typography
customTheme.bodyFont = .system(size: 15)
customTheme.heading1Font = .system(size: 28, weight: .bold)
customTheme.codeFont = .system(.body, design: .monospaced)
customTheme.codeBlockFont = .system(.callout, design: .monospaced)

// Colors
customTheme.textColor = .primary
customTheme.secondaryTextColor = .secondary
customTheme.linkColor = .blue
customTheme.codeBackgroundColor = Color(white: 0.95)
customTheme.blockQuoteBorderColor = Color(white: 0.75)
customTheme.tableBorderColor = Color(white: 0.80)
customTheme.tableHeaderBackgroundColor = Color(white: 0.90)

// Spacing
customTheme.paragraphSpacing = 12
customTheme.listItemSpacing = 4
customTheme.indentation = 20
customTheme.codeBlockPadding = 12

MarkdownView(content)
    .markdownTheme(customTheme)
```

## LaTeX Support

MarkdownExtendedView uses [SwiftMath](https://github.com/mgriebling/SwiftMath) for native LaTeX rendering.

### Inline Math

Use single dollar signs for inline equations that flow with text:

```markdown
The famous equation $E = mc^2$ changed physics.
```

### Display Math

Use double dollar signs for centered, block-level equations:

```markdown
The quadratic formula:

$$x = \frac{-b \pm \sqrt{b^2-4ac}}{2a}$$
```

### Supported LaTeX Commands

SwiftMath supports a wide range of LaTeX math commands including:

- **Greek letters**: `\alpha`, `\beta`, `\gamma`, `\pi`, `\theta`, etc.
- **Operators**: `\sum`, `\prod`, `\int`, `\lim`, `\log`, `\sin`, `\cos`, etc.
- **Fractions**: `\frac{a}{b}`
- **Roots**: `\sqrt{x}`, `\sqrt[n]{x}`
- **Superscripts/subscripts**: `x^2`, `x_i`, `x_i^2`
- **Brackets**: `\left(`, `\right)`, `\{`, `\}`, `\langle`, `\rangle`
- **Matrices**: `\begin{matrix}...\end{matrix}`, `\begin{pmatrix}...\end{pmatrix}`
- **Accents**: `\hat{x}`, `\bar{x}`, `\vec{x}`, `\dot{x}`
- **Symbols**: `\infty`, `\partial`, `\nabla`, `\forall`, `\exists`

For a complete reference, see the [SwiftMath documentation](https://github.com/mgriebling/SwiftMath).

## Known Limitations

Current limitations that may be addressed in future versions:

| Feature | Status | Notes |
|---------|--------|-------|
| Clickable links | Not supported | Links are styled but not tappable |
| Image loading | Not supported | Shows alt text; no remote/local image loading |
| Syntax highlighting | Not supported | Code blocks render in monospace without coloring |
| Task lists | Not supported | `- [ ]` checkboxes not rendered |
| Footnotes | Not supported | `[^1]` syntax not processed |
| Nested lists | Partial | Deep nesting may have alignment issues |
| Autolinks | Not verified | Raw URLs may not auto-link |

## Requirements

- iOS 16.0+ / macOS 13.0+
- Swift 5.9+
- Xcode 15.0+

## Dependencies

- [swift-markdown](https://github.com/apple/swift-markdown) - Apple's Markdown parser (CommonMark + GFM)
- [SwiftMath](https://github.com/mgriebling/SwiftMath) - Native LaTeX rendering

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - Copyright (c) 2025 Christian C. Berclaz. See [LICENSE](LICENSE) for details.
