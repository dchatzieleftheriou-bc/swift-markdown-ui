import SwiftUI
#if os(iOS)
import UIKit

// UITextView that draws Markdown decorations
final class MarkdownDecoratedTextView: UITextView {
    var quoteBarUIColor: UIColor?
    var headingDividerUIColor: UIColor?
    var thematicBreakUIColor: UIColor?
    var thematicBreakThickness: CGFloat = 1.0
    var headingDividerEnabled: Bool = true
    // Inline code overlay configuration (bridged from environment)
    var inlineCodeOverlayEnabled: Bool = false
    var inlineCodeOverlayColor: UIColor?
    var inlineCodeOverlayPadding: CGFloat = 2
    var inlineCodeOverlayCornerRadius: CGFloat = 4
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let documentRange = self.textLayoutManager?.documentRange {
            self.textLayoutManager?.ensureLayout(for: documentRange)
        }
        self.drawMarkdownDecorations()
    }

    private func addQuoteBar(for fragmentUnion: CGRect, level: Int) {
        let insetLeft = self.textContainerInset.left
        let perLevelOffset: CGFloat = 12
        let barWidth: CGFloat = 3
        let barX = insetLeft + 6 + CGFloat(level - 1) * perLevelOffset
        let bar = CALayer()
        bar.name = "markdownQuoteBar-\(level)"
        bar.backgroundColor = (quoteBarUIColor ?? UIColor.tertiaryLabel).cgColor
        bar.frame = CGRect(x: barX, y: fragmentUnion.minY, width: barWidth, height: fragmentUnion.height)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        let contentLayer = (self.subviews.first)?.layer ?? self.layer
        contentLayer.addSublayer(bar)
        CATransaction.commit()
    }

    // Draws quote bars and heading dividers using TextKit 2 layout information.
    private func drawMarkdownDecorations() {
        guard let layoutManager = self.textLayoutManager else { return }

        let contentLayer = (self.subviews.first)?.layer ?? self.layer
        contentLayer.sublayers?.removeAll(where: { layer in
            guard let name = layer.name else { return false }
            return name.hasPrefix("markdownQuoteBar") || name.hasPrefix("markdownHeadingDivider") || name.hasPrefix("markdownThematicBreak") || name.hasPrefix("markdownInlineCode")
        })

        let docRange = layoutManager.documentRange
        let docStart = docRange.location
        var activeLevels: Set<Int> = []
        var unions: [Int: CGRect] = [:]

        layoutManager.enumerateTextLayoutFragments(from: docStart, options: []) { fragment in
            let startOffset = layoutManager.offset(from: docStart, to: fragment.rangeInElement.location)
            guard startOffset < self.attributedText.length else { return true }
            let depth = self.attributedText.attribute(NSAttributedString.Key("markdownQuoteLevel"), at: startOffset, effectiveRange: nil) as? Int ?? 0

            let newLevels: Set<Int> = depth > 0 ? Set(1...depth) : []

            for level in activeLevels where !newLevels.contains(level) {
                if let rect = unions[level], !rect.isNull { self.addQuoteBar(for: rect, level: level) }
                unions[level] = .null
            }

            for level in newLevels {
                if let rect = unions[level] {
                    unions[level] = rect.union(fragment.layoutFragmentFrame)
                } else {
                    unions[level] = fragment.layoutFragmentFrame
                }
            }

            activeLevels = newLevels
            return true
        }

        for (level, rect) in unions.sorted(by: { $0.key < $1.key }) {
            if !rect.isNull { self.addQuoteBar(for: rect, level: level) }
        }

        let full = NSRange(location: 0, length: self.attributedText.length)
        if headingDividerEnabled {  
            self.attributedText.enumerateAttribute(NSAttributedString.Key("markdownHeadingLevel"), in: full, options: []) { value, range, _ in
                guard let level = value as? Int, (level == 1 || level == 2), range.length > 0 else { return }
                guard let startPos = position(from: beginningOfDocument, offset: range.location),
                    let endPos = position(from: beginningOfDocument, offset: range.location + range.length),
                    let txtRange = textRange(from: startPos, to: endPos) else { return }
                let selRects = selectionRects(for: txtRange)
                var union = CGRect.null
                for sr in selRects where !sr.rect.isEmpty { union = union.union(sr.rect) }
                guard !union.isNull else { return }

                let leftInset = self.textContainerInset.left
                let rightInset = self.textContainerInset.right
                let contentWidth = max(1, self.bounds.width - leftInset - rightInset)

                let divider = CALayer()
                divider.name = "markdownHeadingDivider-\(level)"
                divider.backgroundColor = (headingDividerUIColor ?? UIColor.separator).cgColor
                let height: CGFloat = 1.0 / max(UIScreen.main.scale, 1)
                let gap: CGFloat = 8
                divider.frame = CGRect(x: leftInset, y: union.maxY + gap, width: max(1, contentWidth), height: height)
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                contentLayer.addSublayer(divider)
                CATransaction.commit()
            }
        }

        // Inline code rounded overlays per visual line
        if inlineCodeOverlayEnabled {
            self.attributedText.enumerateAttribute(NSAttributedString.Key("markdownCodeInline"), in: full, options: []) { value, nsRange, _ in
                guard let isCode = value as? Bool, isCode, nsRange.length > 0 else { return }
                if let lm = self.textLayoutManager {
                    let docStart = lm.documentRange.location
                    if let start = lm.location(docStart, offsetBy: nsRange.location),
                       let end = lm.location(docStart, offsetBy: nsRange.location + nsRange.length),
                        let tr = NSTextRange(location: start, end: end) {
                        var idx = 0
                        lm.enumerateTextSegments(in: tr, type: .standard, options: []) { _, rect, _, _ in
                            guard !rect.isEmpty else { return true }
                            let inflated = rect.insetBy(dx: -self.inlineCodeOverlayPadding, dy: -self.inlineCodeOverlayPadding * 0.4)
                            let layer = CALayer()
                            layer.name = "markdownInlineCode-\(nsRange.location)-\(idx)"
                            idx += 1
                            var color = self.inlineCodeOverlayColor
                            if color == nil {
                                let keyColor = self.attributedText.attribute(NSAttributedString.Key("markdownInlineCodeBackground"), at: nsRange.location, effectiveRange: nil) as? UIColor
                                color = keyColor ?? (self.attributedText.attribute(NSAttributedString.Key.backgroundColor, at: nsRange.location, effectiveRange: nil) as? UIColor)
                            }
                            layer.backgroundColor = (color ?? UIColor.tertiarySystemFill).cgColor
                            layer.cornerRadius = self.inlineCodeOverlayCornerRadius
                            layer.frame = inflated
                            CATransaction.begin()
                            CATransaction.setDisableActions(true)
                            contentLayer.addSublayer(layer)
                            CATransaction.commit()
                            return true
                        }
                    }
                }
            }
        }

        self.attributedText.enumerateAttribute(NSAttributedString.Key("markdownThematicBreak"), in: full, options: []) { value, range, _ in
            guard let isBreak = value as? Bool, isBreak else { return }

            let breakIndex = range.location
            var union = CGRect.null
            layoutManager.enumerateTextLayoutFragments(from: docStart, options: []) { fragment in
                let fragStart = layoutManager.offset(from: docStart, to: fragment.rangeInElement.location)
                let fragEnd = layoutManager.offset(from: docStart, to: fragment.rangeInElement.endLocation)
                if breakIndex >= fragStart && breakIndex < fragEnd {
                    union = union.union(fragment.layoutFragmentFrame)
                    return false
                }
                return true
            }

            guard !union.isNull else { return }

            let leftInset = self.textContainerInset.left
            let rightInset = self.textContainerInset.right
            let contentWidth = max(1, self.bounds.width - leftInset - rightInset)
            let thickness = max(1.0 / max(UIScreen.main.scale, 1), thematicBreakThickness)

            let hr = CALayer()
            hr.name = "markdownThematicBreak-\(union.minY)"
            hr.backgroundColor = (thematicBreakUIColor ?? UIColor.separator).cgColor
            hr.frame = CGRect(x: leftInset, y: union.midY, width: contentWidth, height: thickness)

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            contentLayer.addSublayer(hr)
            CATransaction.commit()
        }
    }
}

#endif

