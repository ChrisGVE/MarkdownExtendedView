// MarkdownRenderer.swift
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
import Markdown

/// Renders a parsed Markdown document to SwiftUI views.
struct MarkdownRenderer: View {

    let document: Document
    let theme: MarkdownTheme
    let baseURL: URL?

    @Environment(\.markdownFeatures) private var features
    @Environment(\.markdownLinkHandler) private var linkHandler

    var body: some View {
        VStack(alignment: .leading, spacing: theme.paragraphSpacing) {
            ForEach(Array(document.children.enumerated()), id: \.offset) { _, child in
                renderBlock(child)
            }
        }
    }

    /// Whether clickable links are enabled.
    private var linksEnabled: Bool {
        features.contains(.links)
    }

    /// Whether syntax highlighting is enabled.
    private var syntaxHighlightingEnabled: Bool {
        features.contains(.syntaxHighlighting)
    }

    /// Whether Mermaid diagram rendering is enabled.
    private var mermaidEnabled: Bool {
        features.contains(.mermaid)
    }

    // MARK: - Block Rendering

    private func renderBlock(_ markup: any Markup) -> AnyView {
        if let heading = markup as? Heading {
            return AnyView(renderHeading(heading))
        } else if let paragraph = markup as? Paragraph {
            return AnyView(renderParagraph(paragraph))
        } else if let codeBlock = markup as? CodeBlock {
            return AnyView(renderCodeBlock(codeBlock))
        } else if let blockQuote = markup as? BlockQuote {
            return AnyView(renderBlockQuote(blockQuote))
        } else if let orderedList = markup as? OrderedList {
            return AnyView(renderOrderedList(orderedList))
        } else if let unorderedList = markup as? UnorderedList {
            return AnyView(renderUnorderedList(unorderedList))
        } else if let table = markup as? Markdown.Table {
            return AnyView(renderTable(table))
        } else if markup is ThematicBreak {
            return AnyView(Divider().padding(.vertical, 8))
        } else if let htmlBlock = markup as? HTMLBlock {
            return AnyView(
                SwiftUI.Text(htmlBlock.rawHTML)
                    .font(theme.codeFont)
                    .foregroundColor(theme.secondaryTextColor)
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    // MARK: - Heading

    @ViewBuilder
    private func renderHeading(_ heading: Heading) -> some View {
        renderInlineChildren(heading)
            .font(theme.headingFont(level: heading.level))
            .foregroundColor(theme.textColor)
            .padding(.top, heading.level == 1 ? 16 : 8)
            .padding(.bottom, 4)
    }

    // MARK: - Paragraph

    @ViewBuilder
    private func renderParagraph(_ paragraph: Paragraph) -> some View {
        // Check if this paragraph contains only a display LaTeX block
        let plainText = paragraph.plainText
        if plainText.hasPrefix("$$") && plainText.hasSuffix("$$") {
            // This is a display LaTeX block
            let latex = String(plainText.dropFirst(2).dropLast(2)).trimmingCharacters(in: .whitespacesAndNewlines)
            LaTeXView(latex: latex, isBlock: true, theme: theme)
        } else {
            renderInlineChildren(paragraph)
                .font(theme.bodyFont)
                .foregroundColor(theme.textColor)
        }
    }

    // MARK: - Code Block

    @ViewBuilder
    private func renderCodeBlock(_ codeBlock: CodeBlock) -> some View {
        if codeBlock.language == "mermaid" {
            renderMermaidBlock(codeBlock)
        } else {
            renderRegularCodeBlock(codeBlock)
        }
    }

    @ViewBuilder
    private func renderMermaidBlock(_ codeBlock: CodeBlock) -> some View {
        if mermaidEnabled {
            MermaidView(code: codeBlock.code, theme: theme)
        } else {
            MermaidPlaceholderView(code: codeBlock.code, theme: theme)
        }
    }

    @ViewBuilder
    private func renderRegularCodeBlock(_ codeBlock: CodeBlock) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            if syntaxHighlightingEnabled && codeBlock.language != nil {
                HighlightedCodeView(
                    code: codeBlock.code,
                    language: codeBlock.language,
                    theme: theme
                )
            } else {
                Text(codeBlock.code.trimmingCharacters(in: .newlines))
                    .font(theme.codeBlockFont)
                    .foregroundColor(theme.textColor)
            }
        }
        .padding(theme.codeBlockPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.codeBackgroundColor)
        .cornerRadius(8)
    }

    // MARK: - Block Quote

    @ViewBuilder
    private func renderBlockQuote(_ blockQuote: BlockQuote) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(theme.blockQuoteBorderColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: theme.paragraphSpacing / 2) {
                ForEach(Array(blockQuote.children.enumerated()), id: \.offset) { _, child in
                    renderBlock(child)
                }
            }
            .padding(.leading, 12)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Lists

    /// Bullet styles for different nesting levels in unordered lists.
    private static let bulletStyles = ["•", "◦", "▪", "▸"]

    /// Returns the bullet character for a given nesting depth.
    private func bulletForDepth(_ depth: Int) -> String {
        Self.bulletStyles[depth % Self.bulletStyles.count]
    }

    @ViewBuilder
    private func renderOrderedList(_ list: OrderedList, depth: Int = 0) -> some View {
        VStack(alignment: .leading, spacing: theme.listItemSpacing) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { index, item in
                renderListItem(item, bullet: "\(index + Int(list.startIndex)).", depth: depth)
            }
        }
        .padding(.leading, depth > 0 ? theme.indentation : 0)
    }

    @ViewBuilder
    private func renderUnorderedList(_ list: UnorderedList, depth: Int = 0) -> some View {
        VStack(alignment: .leading, spacing: theme.listItemSpacing) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { _, item in
                if item.checkbox != nil {
                    renderTaskListItem(item, depth: depth)
                } else {
                    renderListItem(item, bullet: bulletForDepth(depth), depth: depth)
                }
            }
        }
        .padding(.leading, depth > 0 ? theme.indentation : 0)
    }

    @ViewBuilder
    private func renderListItem(_ item: ListItem, bullet: String, depth: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(bullet)
                .font(theme.bodyFont)
                .foregroundColor(theme.textColor)
                .frame(width: 20, alignment: .trailing)

            VStack(alignment: .leading, spacing: theme.listItemSpacing) {
                ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                    renderListChildBlock(child, depth: depth)
                }
            }
        }
    }

    @ViewBuilder
    private func renderTaskListItem(_ item: ListItem, depth: Int) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: item.checkbox?.isChecked == true ? "checkmark.square.fill" : "square")
                .font(theme.bodyFont)
                .foregroundColor(item.checkbox?.isChecked == true ? theme.linkColor : theme.secondaryTextColor)
                .frame(width: 20, alignment: .trailing)

            VStack(alignment: .leading, spacing: theme.listItemSpacing) {
                ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                    renderListChildBlock(child, depth: depth)
                }
            }
        }
    }

    /// Renders a child block within a list item, handling nested lists specially.
    private func renderListChildBlock(_ markup: any Markup, depth: Int) -> AnyView {
        if let nestedOrdered = markup as? OrderedList {
            return AnyView(renderOrderedList(nestedOrdered, depth: depth + 1))
        } else if let nestedUnordered = markup as? UnorderedList {
            return AnyView(renderUnorderedList(nestedUnordered, depth: depth + 1))
        } else {
            return renderBlock(markup)
        }
    }

    // MARK: - Table

    @ViewBuilder
    private func renderTable(_ table: Markdown.Table) -> some View {
        let cellArrays = extractTableCells(from: table)

        VStack(spacing: 0) {
            // Header row
            if !cellArrays.header.isEmpty {
                renderTableCellRow(cells: cellArrays.header, isHeader: true)
            }

            // Body rows
            ForEach(Array(cellArrays.body.enumerated()), id: \.offset) { _, rowCells in
                renderTableCellRow(cells: rowCells, isHeader: false)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(theme.tableBorderColor, lineWidth: 1)
        )
        .cornerRadius(4)
    }

    /// Extracts cells from a table into arrays for easier SwiftUI rendering.
    private func extractTableCells(from table: Markdown.Table) -> (header: [Markdown.Table.Cell], body: [[Markdown.Table.Cell]]) {
        let header: [Markdown.Table.Cell] = Array(table.head.cells)
        let body: [[Markdown.Table.Cell]] = table.body.rows.map { Array($0.cells) }
        return (header, body)
    }

    @ViewBuilder
    private func renderTableCellRow(cells: [Markdown.Table.Cell], isHeader: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                renderInlineChildren(cell)
                    .font(isHeader ? theme.bodyFont.bold() : theme.bodyFont)
                    .foregroundColor(theme.textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(isHeader ? theme.tableHeaderBackgroundColor : Color.clear)

                if index < cells.count - 1 {
                    Divider()
                }
            }
        }
        .overlay(
            Rectangle()
                .stroke(theme.tableBorderColor, lineWidth: 0.5)
        )
    }

    // MARK: - Inline Rendering

    /// Whether image loading is enabled.
    private var imagesEnabled: Bool {
        features.contains(.images)
    }

    /// Renders the inline children of `parent`, preserving styling across LaTeX,
    /// links, and images.
    @ViewBuilder
    private func renderInlineChildren(_ parent: any Markup) -> some View {
        let fragments = InlineFlattener.fragments(for: parent)
        renderInlineFragments(fragments)
    }

    /// Chooses between the fast single-`Text` path and the flow-layout path.
    ///
    /// The flow path is only needed when a real subview (LaTeX, an enabled image,
    /// or an enabled link) must sit inline; otherwise a single concatenated
    /// `Text` wraps naturally and is cheaper.
    @ViewBuilder
    private func renderInlineFragments(_ fragments: [InlineFragment]) -> some View {
        if needsFlowLayout(fragments) {
            renderFlow(fragments)
        } else {
            InlineTextRenderer.text(fragments, theme: theme)
        }
    }

    /// Whether any fragment requires a dedicated inline subview.
    private func needsFlowLayout(_ fragments: [InlineFragment]) -> Bool {
        fragments.contains { fragment in
            switch fragment {
            case .latex: return true
            case .image: return imagesEnabled
            case .link: return linksEnabled
            default: return false
            }
        }
    }

    /// Render-ready flow item: either coalesced text or a standalone subview.
    private enum FlowItem {
        case text(SwiftUI.Text)
        case latex(String, isBlock: Bool)
        case image(source: String?, alt: String)
        case link(destination: String?, content: [InlineFragment])
    }

    /// Renders fragments in a wrapping flow layout, coalescing adjacent text /
    /// break / disabled-feature fragments into single `Text` runs.
    @ViewBuilder
    private func renderFlow(_ fragments: [InlineFragment]) -> some View {
        let items = buildFlowItems(fragments)
        FlowLayout(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                renderFlowItem(item)
            }
        }
    }

    /// Coalesces fragments into flow items. Text, breaks, and disabled
    /// images/links merge into a running `Text`; LaTeX and enabled
    /// images/links break the run into their own items.
    private func buildFlowItems(_ fragments: [InlineFragment]) -> [FlowItem] {
        var items: [FlowItem] = []
        var pending: SwiftUI.Text?

        func flush() {
            if let pending { items.append(.text(pending)) }
            pending = nil
        }
        func append(_ text: SwiftUI.Text) {
            pending = pending.map { $0 + text } ?? text
        }

        for fragment in fragments {
            switch fragment {
            case .latex(let latex, let isBlock):
                flush()
                items.append(.latex(latex, isBlock: isBlock))
            case .image(let source, let alt):
                if imagesEnabled {
                    flush()
                    items.append(.image(source: source, alt: alt))
                } else {
                    append(InlineTextRenderer.text(for: fragment, theme: theme))
                }
            case .link(let destination, let content):
                if linksEnabled {
                    flush()
                    items.append(.link(destination: destination, content: content))
                } else {
                    append(InlineTextRenderer.text(for: fragment, theme: theme))
                }
            default:
                append(InlineTextRenderer.text(for: fragment, theme: theme))
            }
        }
        flush()
        return items
    }

    @ViewBuilder
    private func renderFlowItem(_ item: FlowItem) -> some View {
        switch item {
        case .text(let text):
            text
        case .latex(let latex, let isBlock):
            LaTeXView(latex: latex, isBlock: isBlock, theme: theme)
        case .image(let source, let alt):
            MarkdownImageView(source: source, altText: alt, theme: theme, baseURL: baseURL)
        case .link(let destination, let content):
            TappableLinkView(
                destination: destination,
                content: content,
                theme: theme,
                linkHandler: linkHandler,
                baseURL: baseURL
            )
        }
    }
}

// MARK: - Flow Layout

/// A simple flow layout for mixed text and views.
struct FlowLayout: Layout {
    var spacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)

        for (index, subview) in subviews.enumerated() {
            if index < result.positions.count {
                let position = result.positions[index]
                subview.place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
            }
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                // Move to next line
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))

            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalWidth = max(totalWidth, currentX)
        }

        totalHeight = currentY + lineHeight

        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}
