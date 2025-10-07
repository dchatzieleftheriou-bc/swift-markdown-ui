import MarkdownUI
import Splash
import SwiftUI

struct SplashCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    private let syntaxHighlighter: SyntaxHighlighter<TextOutputFormat>
    private let attributedSyntalHiglighter: SyntaxHighlighter<AttributedStringOutputFormat>

    private var useAttributed: Bool = false

    var preferAttributedWhenAvailable: Bool {
        useAttributed
    }

    init(theme: Splash.Theme, useAttributed: Bool) {
        self.syntaxHighlighter = SyntaxHighlighter(format: TextOutputFormat(theme: theme))
        self.attributedSyntalHiglighter = SyntaxHighlighter(format: AttributedStringOutputFormat(theme: theme))
        self.useAttributed = useAttributed
    }

    func highlightCode(_ content: String, language: String?) -> Text {
        guard language != nil else {
            return Text(content)
        }

        return self.syntaxHighlighter.highlight(content)
    }

    func highlightCodeAttributed(_ code: String, language: String?) -> NSAttributedString? {
        guard language != nil else {
            return NSAttributedString(string: code)
        }
        return attributedSyntalHiglighter.highlight(code)
    }
}

extension CodeSyntaxHighlighter where Self == SplashCodeSyntaxHighlighter {
    static func splash(theme: Splash.Theme, useAttributed: Bool = false) -> Self {
        SplashCodeSyntaxHighlighter(theme: theme, useAttributed: useAttributed)
    }
}
