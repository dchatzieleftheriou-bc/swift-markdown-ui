import SwiftUI

#if os(iOS)
import UIKit

struct UIKitTextRunView: UIViewRepresentable {
    var blocks: [BlockNode]

    @Environment(\.baseURL) private var baseURL
    @Environment(\.softBreakMode) private var softBreak
    @Environment(\.theme) private var theme
    @Environment(\.textStyle) private var inheritedTextStyle
    @Environment(\.openURL) private var openURL
    @Environment(\.hybridHeadingMetrics) private var headingMetrics
    @Environment(\.hybridQuoteBarColor) private var environmentQuoteBarColor
    @Environment(\.hybridHeadingDividerColor) private var environmentHeadingDividerColor
    @Environment(\.hybridHeadingDividerEnabled) private var environmentHeadingDividerEnabled
    @Environment(\.hybridLineSpacing) private var hybridLineSpacing
    @Environment(\.hybridThematicBreakColor) private var hybridThematicBreakColor
    @Environment(\.hybridThematicBreakThickness) private var hybridThematicBreakThickness

    final class Coordinator: NSObject, UITextViewDelegate {
        var openURL: OpenURLAction?
        var currentText: NSAttributedString?
        var cachedHeight: CGFloat?
        var lastWidth: CGFloat = 0

        init(_ openURL: OpenURLAction?) { self.openURL = openURL }
        func textView(_ tv: UITextView, shouldInteractWith URL: URL, in: NSRange, interaction: UITextItemInteraction) -> Bool {
            self.openURL?(URL)
            return true
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(openURL) }

    func makeUIView(context: Context) -> UITextView {
        let tv = MarkdownDecoratedTextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.textContainer.widthTracksTextView = true
        tv.textContainer.lineBreakMode = .byWordWrapping
        tv.adjustsFontForContentSizeCategory = true
        tv.linkTextAttributes = [:]
        tv.delegate = context.coordinator
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentCompressionResistancePriority(.required, for: .vertical)
        tv.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.required, for: .vertical)

        tv.quoteBarUIColor = UIColor(environmentQuoteBarColor)
        tv.headingDividerUIColor = UIColor(environmentHeadingDividerColor)
        tv.headingDividerEnabled = environmentHeadingDividerEnabled
        tv.thematicBreakUIColor = UIColor(hybridThematicBreakColor)
        tv.thematicBreakThickness = hybridThematicBreakThickness
        
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let rendered = self.renderNSAttributed()
        // Skip resetting text if identical to avoid redundant layout and sizing
        if let current = context.coordinator.currentText, current.isEqual(to: rendered) {
            // no-op
        } else {
            context.coordinator.currentText = rendered
            context.coordinator.cachedHeight = nil
            uiView.attributedText = rendered
        }
        uiView.adjustsFontForContentSizeCategory = true
        uiView.textContainerInset = .zero
        uiView.textContainer.lineFragmentPadding = 0
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let proposed = proposal.width ?? uiView.superview?.bounds.width ?? uiView.bounds.width
        let width = max(1, proposed)
        let attributed = context.coordinator.currentText ?? self.renderNSAttributed()

        // Use cached height when width and content have not changed
        if let cached = context.coordinator.cachedHeight,
           context.coordinator.lastWidth == width,
           let current = context.coordinator.currentText,
           current.isEqual(to: attributed) {
            return CGSize(width: width, height: cached)
        }

        let height = self.measureHeight(for: width, view: uiView, attributed: attributed)
        context.coordinator.cachedHeight = height
        context.coordinator.lastWidth = width
        context.coordinator.currentText = attributed
        return CGSize(width: width, height: height)
    }

    private func measureHeight(for width: CGFloat, view: UITextView, attributed: NSAttributedString) -> CGFloat {
        let storage = NSTextStorage(attributedString: attributed)
        let contentStorage = NSTextContentStorage()
        contentStorage.textStorage = storage
        let layoutManager = NSTextLayoutManager()
        contentStorage.addTextLayoutManager(layoutManager)

        let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        container.maximumNumberOfLines = 0
        container.lineBreakMode = .byWordWrapping
        layoutManager.textContainer = container
        layoutManager.ensureLayout(for: layoutManager.documentRange)

        var maxY: CGFloat = 0
        layoutManager.enumerateTextLayoutFragments(from: layoutManager.documentRange.location, options: []) { fragment in
            maxY = max(maxY, fragment.layoutFragmentFrame.maxY)
            return true
        }
        return ceil(maxY)
    }

    private func renderAttributed() -> AttributedString {
        var baseAttributes = AttributeContainer()
        self.theme.text._collectAttributes(in: &baseAttributes)
        self.inheritedTextStyle._collectAttributes(in: &baseAttributes)

        let inlineStyles = InlineTextStyles(
            code: self.theme.code,
            emphasis: self.theme.emphasis,
            strong: self.theme.strong,
            strikethrough: self.theme.strikethrough,
            link: self.theme.link
        )

        func renderBlocks(_ blocks: [BlockNode], indentLevel: Int) -> AttributedString {
            var out = AttributedString()
            for (idx, block) in blocks.enumerated() {
                switch block {
                case .paragraph(let inlines):
                    var attrs = baseAttributes
                    if indentLevel > 0 { attrs.markdownIndentLevel = indentLevel }
                    out += inlines.reduce(into: AttributedString()) { acc, node in
                        acc += node.hybridRenderAttributedString(
                            baseURL: self.baseURL,
                            textStyles: inlineStyles,
                            softBreakMode: self.softBreak,
                            attributes: attrs
                        )
                    }
                case .heading(let level, let inlines):
                    var headingAttrs = baseAttributes
                    if let metrics = headingMetrics[level] {
                        FontSize(.em(metrics.sizeScale))._collectAttributes(in: &headingAttrs)
                        if let w = metrics.weight { FontWeight(w)._collectAttributes(in: &headingAttrs) }
                        if let c = metrics.foregroundColor { ForegroundColor(c)._collectAttributes(in: &headingAttrs) }
                        if let before = metrics.paragraphSpacingBefore { headingAttrs.markdownParagraphSpacingBefore = before }
                        if let after = metrics.paragraphSpacingAfter { headingAttrs.markdownParagraphSpacingAfter = after }
                    }
                    // Mark heading level so overlay can add optional divider (configured by Theme)
                    headingAttrs.markdownHeadingLevel = level
                    out += inlines.reduce(into: AttributedString()) { acc, node in
                        acc += node.hybridRenderAttributedString(
                            baseURL: self.baseURL,
                            textStyles: inlineStyles,
                            softBreakMode: self.softBreak,
                            attributes: headingAttrs
                        )
                    }
                    out += AttributedString("", attributes: headingAttrs)
                case .blockquote(let children):
                    let quoted = renderBlocks(children, indentLevel: indentLevel + 1)
                    var marked = quoted
                    let level = indentLevel + 1
                    for run in marked.runs {
                        let current = run.markdownQuoteLevel ?? 0
                        if current < level {
                            marked[run.range].markdownQuoteLevel = level
                        }
                    }
                    out += marked
                case .bulletedList(let isTight, let items):
                    for (i, item) in items.enumerated() {
                        var attrs = baseAttributes
                        attrs.markdownIndentLevel = indentLevel + 1
                        var line = AttributedString("• ", attributes: attrs)
                        // Paragraph content of the item
                        for child in item.children {
                            switch child {
                            case .paragraph(let inlines):
                                line += inlines.reduce(into: AttributedString()) { acc, node in
                                    acc += node.hybridRenderAttributedString(
                                        baseURL: self.baseURL,
                                        textStyles: inlineStyles,
                                        softBreakMode: self.softBreak,
                                        attributes: attrs
                                    )
                                }
                            case .bulletedList, .numberedList, .taskList:
                                // Nested list: new line before rendering nested content
                                line += AttributedString("\n", attributes: baseAttributes)
                                line += renderBlocks([child], indentLevel: indentLevel + 1)
                            default:
                                break
                            }
                        }
                        out += line
                        if i < items.count - 1 || !isTight { out += AttributedString("\n", attributes: baseAttributes) }
                    }
                case .numberedList(let isTight, let start, let items):
                    for (offset, item) in items.enumerated() {
                        var attrs = baseAttributes
                        attrs.markdownIndentLevel = indentLevel + 1
                        var line = AttributedString("\(start + offset). ", attributes: attrs)
                        for child in item.children {
                            switch child {
                            case .paragraph(let inlines):
                                line += inlines.reduce(into: AttributedString()) { acc, node in
                                    acc += node.hybridRenderAttributedString(
                                        baseURL: self.baseURL,
                                        textStyles: inlineStyles,
                                        softBreakMode: self.softBreak,
                                        attributes: attrs
                                    )
                                }
                            case .bulletedList, .numberedList, .taskList:
                                line += AttributedString("\n", attributes: baseAttributes)
                                line += renderBlocks([child], indentLevel: indentLevel + 1)
                            default:
                                break
                            }
                        }
                        out += line
                        if offset < items.count - 1 || !isTight { out += AttributedString("\n", attributes: baseAttributes) }
                    }
                case .taskList(let isTight, let items):
                    for (i, item) in items.enumerated() {
                        var attrs = baseAttributes
                        attrs.markdownIndentLevel = indentLevel + 1
                        var line = AttributedString(item.isCompleted ? "[x] " : "[ ] ", attributes: attrs)
                        for child in item.children {
                            switch child {
                            case .paragraph(let inlines):
                                line += inlines.reduce(into: AttributedString()) { acc, node in
                                    acc += node.hybridRenderAttributedString(
                                        baseURL: self.baseURL,
                                        textStyles: inlineStyles,
                                        softBreakMode: self.softBreak,
                                        attributes: attrs
                                    )
                                }
                            case .bulletedList, .numberedList, .taskList:
                                line += AttributedString("\n", attributes: baseAttributes)
                                line += renderBlocks([child], indentLevel: indentLevel + 1)
                            default:
                                break
                            }
                        }
                        out += line
                        if i < items.count - 1 || !isTight { out += AttributedString("\n", attributes: baseAttributes) }
                    }
                case .thematicBreak:
                    var attrs = baseAttributes
                    attrs.markdownThematicBreak = true
                    // zero-width placeholder
                    out += AttributedString("\u{200B}", attributes: attrs)
                default:
                    break
                }

                if idx < blocks.count - 1 {
                    out += AttributedString("\n\n", attributes: baseAttributes)
                }
            }
            return out
        }

        return renderBlocks(self.blocks, indentLevel: 0)
    }

    private func renderNSAttributed() -> NSAttributedString {
        let combined = self.renderAttributed()

        var baseAttrs = AttributeContainer()
        self.theme.text._collectAttributes(in: &baseAttrs)
        let baseFont: UIFont = (baseAttrs.fontProperties.map { UIFont.withProperties($0) }) ?? .systemFont(ofSize: FontProperties.defaultSize)
        let baseColor: UIColor = (baseAttrs.foregroundColor.map { UIColor($0) }) ?? .label

        let output = NSMutableAttributedString()

        for run in combined.runs {
            let swiftSub = AttributedString(combined[run.range])
            let text = String(swiftSub.characters)

            var attrs: [NSAttributedString.Key: Any] = [:]

            // Font
            if let p = run.fontProperties {
                attrs[.font] = UIFont.withProperties(p)
            } else {
                attrs[.font] = baseFont
            }

            // Color
            if let c = run.foregroundColor {
                attrs[.foregroundColor] = UIColor(c)
            } else {
                attrs[.foregroundColor] = baseColor
            }

            // Background: only apply when explicitly marked as inline code
            if let isCode = run.markdownCodeInline, isCode, let bg = run.backgroundColor {
                attrs[.backgroundColor] = UIColor(bg)
            }

            // Link
            if let link = run.link { attrs[.link] = link }

            // Strikethrough
            if run.strikethroughStyle != nil {
                attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            }

            // Underline
            if run.underlineStyle != nil {
                attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }

            // Preserve semantic quote level for overlay drawing
            if let level = run.markdownQuoteLevel, level > 0 {
                attrs[NSAttributedString.Key("markdownQuoteLevel")] = level
            }

            // Preserve heading level for heading divider overlay (H1/H2)
            if let h = run.markdownHeadingLevel, h > 0 {
                attrs[NSAttributedString.Key("markdownHeadingLevel")] = h
            }

            // Mark thematic break so overlay can draw a rule
            if let isBreak = run.markdownThematicBreak, isBreak {
                attrs[NSAttributedString.Key("markdownThematicBreak")] = true
            }

            // Paragraph-level styling (indentation, spacing, line spacing)
            if let indent = run.markdownIndentLevel, indent > 0 {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                if let ls = hybridLineSpacing { paragraph.lineSpacing = ls }
                let indentWidth = CGFloat(16 * indent)
                paragraph.headIndent = indentWidth
                paragraph.firstLineHeadIndent = indentWidth
                if let before = run.markdownParagraphSpacingBefore { paragraph.paragraphSpacingBefore = before }
                if let after = run.markdownParagraphSpacingAfter { paragraph.paragraphSpacing = after }
                attrs[.paragraphStyle] = paragraph
            } else if hybridLineSpacing != nil || run.markdownParagraphSpacingBefore != nil || run.markdownParagraphSpacingAfter != nil {
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                if let ls = hybridLineSpacing { paragraph.lineSpacing = ls }
                if let before = run.markdownParagraphSpacingBefore { paragraph.paragraphSpacingBefore = before }
                if let after = run.markdownParagraphSpacingAfter { paragraph.paragraphSpacing = after }
                attrs[.paragraphStyle] = paragraph
            }

            // Kerning
            if let kern = run.kern { attrs[.kern] = kern }

            output.append(NSAttributedString(string: text, attributes: attrs))
        }

        return output
    }
}
#endif


