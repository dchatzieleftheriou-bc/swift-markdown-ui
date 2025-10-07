import SwiftUI

struct CodeBlockView: View {
    @Environment(\.theme.codeBlock) private var codeBlock
    @Environment(\.theme.hybridCodeBlock) private var hybridCodeBlock
    @Environment(\.codeSyntaxHighlighter) private var codeSyntaxHighlighter
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.textStyle) private var textStyle

    private let fenceInfo: String?
    private let content: String

    init(fenceInfo: String?, content: String) {
        self.fenceInfo = fenceInfo
        self.content = content.hasSuffix("\n") ? String(content.dropLast()) : content
    }

    @ViewBuilder
    var body: some View {
        if let attributed = attributed(), codeSyntaxHighlighter.preferAttributedWhenAvailable {
            self.hybridCodeBlock.makeBody(
                configuration: .init(
                    language: self.fenceInfo,
                    content: self.content,
                    label: .init(self.codeView(attributed: attributed))
                )
            )
        } else {
            self.codeBlock.makeBody(
                configuration: .init(
                    language: self.fenceInfo,
                    content: self.content,
                    label: .init(self.label)
                )
            )
        }
    }

    private func codeView(attributed: NSAttributedString) -> some View {
        UIKitCodeTextView(attributed: attributed)
            .textStyleFont()
            .textStyleForegroundColor()
    }

    private var label: some View {
        self.codeSyntaxHighlighter.highlightCode(self.content, language: self.fenceInfo)
            .textStyleFont()
            .textStyleForegroundColor()
    }

    private func attributed() -> NSAttributedString? {
        return codeSyntaxHighlighter.highlightCodeAttributed(self.content, language: self.fenceInfo)
    }
}
