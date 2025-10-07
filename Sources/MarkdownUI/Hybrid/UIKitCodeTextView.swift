import SwiftUI
#if os(iOS)
import UIKit

struct UIKitCodeTextView: UIViewRepresentable {
    let attributed: NSAttributedString

    @Environment(\.hybridCodeBlockMinHeight) private var minHeight
    @Environment(\.hybridCodeBlockMaxHeight) private var maxHeight
    @Environment(\.theme) private var theme
    @Environment(\.textStyle) private var inheritedTextStyle

    final class Coordinator: NSObject, UIScrollViewDelegate, UITextViewDelegate {
        weak var textView: UITextView?
    }
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.alwaysBounceVertical = false
        scrollView.contentInsetAdjustmentBehavior = .never

        let tv = UITextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.isScrollEnabled = true
            
        tv.showsVerticalScrollIndicator = true
        tv.showsHorizontalScrollIndicator = false
        tv.alwaysBounceVertical = true
        tv.alwaysBounceHorizontal = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.textContainer.widthTracksTextView = true
        tv.textContainer.lineBreakMode = .byClipping
        tv.adjustsFontForContentSizeCategory = true
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.setContentCompressionResistancePriority(.required, for: .vertical)
        tv.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tv.setContentHuggingPriority(.required, for: .vertical)
        tv.delegate = context.coordinator

        scrollView.addSubview(tv)
        context.coordinator.textView = tv

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let tv = context.coordinator.textView else { return }
        tv.attributedText = self.processedAttributed()
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        tv.textContainer.widthTracksTextView = true
        tv.textContainer.lineBreakMode = .byClipping

        let attributed = tv.attributedText ?? NSAttributedString()
        let maxLineWidth = self.measureMaxLineWidth(attributed: attributed)

        let availableWidth = max(scrollView.bounds.width, 1)
        let contentWidth = max(availableWidth, maxLineWidth)
        let height = self.measureHeight(for: availableWidth, attributed: attributed)
        let clampedHeight = min(max(height, minHeight), maxHeight)

        tv.frame = CGRect(x: 0, y: 0, width: contentWidth, height: clampedHeight)
        scrollView.contentSize = CGSize(width: contentWidth, height: clampedHeight)

        scrollView.setNeedsLayout()
        scrollView.layoutIfNeeded()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIScrollView, context: Context) -> CGSize? {
        let width = max(1, proposal.width ?? uiView.superview?.bounds.width ?? uiView.bounds.width)
        let attributed = self.processedAttributed()
        let height = self.measureHeight(for: width, attributed: attributed)
        let clamped = min(max(height, minHeight), maxHeight)
        return CGSize(width: width, height: ceil(clamped))
    }

    // MARK: - Typography processing

    private func processedAttributed() -> NSAttributedString {
        var baseAttributes = AttributeContainer()
        self.theme.text._collectAttributes(in: &baseAttributes)
        self.inheritedTextStyle._collectAttributes(in: &baseAttributes)

        let out = NSMutableAttributedString(attributedString: self.attributed)

        // Derive base font and color from AttributeContainer
        let baseFont: UIFont = (baseAttributes.fontProperties.map { UIFont.withProperties($0) })
            ?? .monospacedSystemFont(ofSize: FontProperties.defaultSize, weight: .regular)
        let baseColor: UIColor = (baseAttributes.foregroundColor.map { UIColor($0) }) ?? .label
        let baseKern: CGFloat? = baseAttributes.kern

        let full = NSRange(location: 0, length: out.length)
        out.enumerateAttributes(in: full, options: []) { attrs, range, _ in
            var newAttrs = attrs
            if newAttrs[.font] == nil { newAttrs[.font] = baseFont }
            if newAttrs[.foregroundColor] == nil { newAttrs[.foregroundColor] = baseColor }
            if newAttrs[.kern] == nil, let k = baseKern { newAttrs[.kern] = k }

            if let ps = newAttrs[.paragraphStyle] as? NSParagraphStyle {
                let mps = ps.mutableCopy() as! NSMutableParagraphStyle
                mps.lineBreakMode = .byClipping
                newAttrs[.paragraphStyle] = mps
            } else {
                let ps = NSMutableParagraphStyle()
                ps.lineBreakMode = .byClipping
                newAttrs[.paragraphStyle] = ps
            }
            out.setAttributes(newAttrs, range: range)
        }

        return out
    }

    // MARK: - Measurement helpers (TextKit 2)

    private func measureMaxLineWidth(attributed: NSAttributedString) -> CGFloat {
        let storage = NSTextStorage(attributedString: attributed)
        let contentStorage = NSTextContentStorage()
        contentStorage.textStorage = storage
        let lm = NSTextLayoutManager()
        contentStorage.addTextLayoutManager(lm)
        let container = NSTextContainer(size: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        container.lineBreakMode = .byClipping
        lm.textContainer = container
        lm.ensureLayout(for: lm.documentRange)
        var maxWidth: CGFloat = 0
        lm.enumerateTextLayoutFragments(from: lm.documentRange.location, options: []) { frag in
            maxWidth = max(maxWidth, frag.layoutFragmentFrame.width)
            return true
        }
        return ceil(maxWidth)
    }

    private func measureHeight(for width: CGFloat, attributed: NSAttributedString) -> CGFloat {
        let storage = NSTextStorage(attributedString: attributed)
        let contentStorage = NSTextContentStorage()
        contentStorage.textStorage = storage
        let lm = NSTextLayoutManager()
        contentStorage.addTextLayoutManager(lm)
        let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        container.lineBreakMode = .byClipping
        lm.textContainer = container
        lm.ensureLayout(for: lm.documentRange)
        var maxY: CGFloat = 0
        lm.enumerateTextLayoutFragments(from: lm.documentRange.location, options: []) { frag in
            maxY = max(maxY, frag.layoutFragmentFrame.maxY)
            return true
        }
        return ceil(maxY)
    }
}
#endif


