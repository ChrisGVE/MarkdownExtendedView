# Changelog

All notable changes to MarkdownExtendedView will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-01-11

### Changed

- Switched LaTeX dependency from SwiftMath to [ExtendedSwiftMath](https://github.com/ChrisGVE/ExtendedSwiftMath)
  - Drop-in replacement with planned extended symbol coverage
  - No API changes required

## [1.1.0] - 2025-01-01

### Added

- **Feature Flags System**: Privacy-first opt-in architecture using `MarkdownFeatures` OptionSet
  - `.links` - Enable clickable links
  - `.images` - Enable remote image loading
  - `.syntaxHighlighting` - Enable code block colorization
  - `.mermaid` - Enable Mermaid diagram rendering
  - `.footnotes` - Enable footnote processing
  - `.all` - Enable all features
  - `.none` - Default, all features disabled

- **Task Lists**: Checkbox rendering for `- [ ]` and `- [x]` syntax with SF Symbols

- **Clickable Links**:
  - iOS: Opens in SFSafariViewController (in-app browser)
  - macOS: Opens in default system browser
  - Custom handler support via `.onLinkTap()` modifier

- **Remote Images**: AsyncImage-based loading with loading spinner and error placeholders

- **Syntax Highlighting**: Tokenization-based colorization for 13+ languages
  - Supported: Swift, Python, JavaScript, TypeScript, Java, C, C++, Go, Rust, Ruby, Kotlin, PHP, C#
  - Customizable via `SyntaxColors` in theme

- **Nested Lists**: Improved depth tracking with rotating bullet styles (•, ◦, ▪, ▸)

- **Mermaid Diagrams**: WKWebView rendering with Mermaid.js CDN
  - Supports flowcharts, sequence diagrams, class diagrams, state diagrams, Gantt charts, pie charts

- **Footnotes**: Pre-processor for `[^id]` syntax
  - Renders as superscript numbers (¹, ², ³...)
  - Appends footnotes section at document end
  - Supports named footnotes and multi-line definitions

### Changed

- All network-dependent features are now disabled by default for privacy

## [1.0.2] - 2025-01-01

### Changed

- Updated license to proprietary

## [1.0.1] - 2025-01-01

### Fixed

- Minor bug fixes

## [1.0.0] - 2025-01-01

### Added

- Initial release
- GitHub Flavored Markdown parsing via swift-markdown
- LaTeX equation support via SwiftMath (inline `$...$` and display `$$...$$`)
- Theming system with default, gitHub, and compact themes
- Cross-platform support for iOS 16+ and macOS 13+
- Pure SwiftUI implementation

[1.2.0]: https://github.com/ChrisGVE/MarkdownExtendedView/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/ChrisGVE/MarkdownExtendedView/compare/1.0.2...1.1.0
[1.0.2]: https://github.com/ChrisGVE/MarkdownExtendedView/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/ChrisGVE/MarkdownExtendedView/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/ChrisGVE/MarkdownExtendedView/releases/tag/1.0.0
