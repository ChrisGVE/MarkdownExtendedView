// MarkdownRenderer.swift
// MarkdownExtendedView
//
// Copyright (c) 2025 Christian C. Berclaz
// Licensed under MIT License

import SwiftUI
import Markdown

/// Renders a parsed Markdown document to SwiftUI views.
struct MarkdownRenderer: View {

    let document: Document
    let theme: MarkdownTheme
    let baseURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: theme.paragraphSpacing) {
            ForEach(Array(document.children.enumerated()), id: \.offset) { _, child in
                renderBlock(child)
            }
        }
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
        ScrollView(.horizontal, showsIndicators: false) {
            Text(codeBlock.code.trimmingCharacters(in: .newlines))
                .font(theme.codeBlockFont)
                .foregroundColor(theme.textColor)
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

    @ViewBuilder
    private func renderOrderedList(_ list: OrderedList) -> some View {
        VStack(alignment: .leading, spacing: theme.listItemSpacing) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { index, item in
                renderListItem(item, bullet: "\(index + Int(list.startIndex)).")
            }
        }
    }

    @ViewBuilder
    private func renderUnorderedList(_ list: UnorderedList) -> some View {
        VStack(alignment: .leading, spacing: theme.listItemSpacing) {
            ForEach(Array(list.listItems.enumerated()), id: \.offset) { _, item in
                renderListItem(item, bullet: "•")
            }
        }
    }

    @ViewBuilder
    private func renderListItem(_ item: ListItem, bullet: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(bullet)
                .font(theme.bodyFont)
                .foregroundColor(theme.textColor)
                .frame(width: 20, alignment: .trailing)

            VStack(alignment: .leading, spacing: theme.listItemSpacing) {
                ForEach(Array(item.children.enumerated()), id: \.offset) { _, child in
                    renderBlock(child)
                }
            }
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

    @ViewBuilder
    private func renderInlineChildren(_ parent: any Markup) -> some View {
        let inlineText = buildInlineText(from: parent)
        inlineText
    }

    /// Builds a Text view from inline children, handling LaTeX segments.
    private func buildInlineText(from parent: any Markup) -> some View {
        let plainText = extractPlainText(from: parent)

        // Check if text contains LaTeX
        if LaTeXPreprocessor.containsLaTeX(plainText) {
            return AnyView(renderTextWithLaTeX(parent))
        } else {
            return AnyView(buildAttributedText(from: parent))
        }
    }

    /// Renders text that may contain inline LaTeX.
    @ViewBuilder
    private func renderTextWithLaTeX(_ parent: any Markup) -> some View {
        let plainText = extractPlainText(from: parent)
        let segments = LaTeXPreprocessor.extractSegments(from: plainText)

        // Use a flow layout to handle mixed text and LaTeX
        FlowLayout(spacing: 0) {
            ForEach(Array(segments.enumerated()), id: \.offset) { item in
                renderSegment(item.element)
            }
        }
    }

    /// Renders a single LaTeX segment.
    @ViewBuilder
    private func renderSegment(_ segment: LaTeXPreprocessor.Segment) -> some View {
        switch segment {
        case .text(let text):
            SwiftUI.Text(text)
                .font(theme.bodyFont)
                .foregroundColor(theme.textColor)

        case .latex(let latex, let isBlock):
            LaTeXView(latex: latex, isBlock: isBlock, theme: theme)
        }
    }

    /// Builds attributed text for inline content without LaTeX.
    private func buildAttributedText(from parent: any Markup) -> SwiftUI.Text {
        var result = SwiftUI.Text("")
        for child in parent.children {
            result = result + renderInlineElement(child)
        }
        return result
    }

    /// Renders a single inline element to Text.
    private func renderInlineElement(_ element: any Markup) -> SwiftUI.Text {
        switch element {
        case let text as Markdown.Text:
            return SwiftUI.Text(text.string)

        case let strong as Strong:
            let inner = buildTextFromChildren(strong)
            return inner.bold()

        case let emphasis as Emphasis:
            let inner = buildTextFromChildren(emphasis)
            return inner.italic()

        case let strikethrough as Strikethrough:
            let inner = buildTextFromChildren(strikethrough)
            return inner.strikethrough()

        case let code as InlineCode:
            return SwiftUI.Text(code.code)
                .font(theme.codeFont)

        case let link as Markdown.Link:
            let inner = buildTextFromChildren(link)
            return inner.foregroundColor(theme.linkColor)

        case _ as SoftBreak:
            return SwiftUI.Text(" ")

        case _ as LineBreak:
            return SwiftUI.Text("\n")

        case let image as Markdown.Image:
            // Display alt text for images (actual image loading would need AsyncImage)
            return SwiftUI.Text("[\(image.plainText)]")
                .foregroundColor(theme.secondaryTextColor)

        default:
            // For any other inline elements, try to extract plain text
            if let plainText = element as? any PlainTextConvertibleMarkup {
                return SwiftUI.Text(plainText.plainText)
            }
            return SwiftUI.Text("")
        }
    }

    /// Builds Text from children of a markup element.
    private func buildTextFromChildren(_ parent: any Markup) -> SwiftUI.Text {
        parent.children.reduce(SwiftUI.Text("")) { result, child in
            result + renderInlineElement(child)
        }
    }

    /// Extracts plain text from markup for LaTeX detection.
    private func extractPlainText(from markup: any Markup) -> String {
        if let plainText = markup as? any PlainTextConvertibleMarkup {
            return plainText.plainText
        }
        return markup.children.map { extractPlainText(from: $0) }.joined()
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
