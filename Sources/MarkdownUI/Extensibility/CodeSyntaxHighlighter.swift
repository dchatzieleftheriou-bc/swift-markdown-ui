import SwiftUI

/// A type that provides syntax highlighting to code blocks in a Markdown view.
///
/// To configure the current code syntax highlighter for a view hierarchy, use the
/// `markdownCodeSyntaxHighlighter(_:)` modifier.
public protocol CodeSyntaxHighlighter {
    var preferAttributedWhenAvailable: Bool { get }
    /// Returns a text view configured with the syntax highlighted code.
    /// - Parameters:
    ///   - code: The code block.
    ///   - language: The language of the code block.
    func highlightCode(_ code: String, language: String?) -> Text

    /// Optional: Provide an NSAttributedString for UIKit-backed code blocks.
    /// Return nil to indicate no UIKit path; the caller should fall back to Text.
    func highlightCodeAttributed(_ code: String, language: String?) -> NSAttributedString?
}

/// A code syntax highlighter that returns unstyled code blocks.
public struct PlainTextCodeSyntaxHighlighter: CodeSyntaxHighlighter {
    public let preferAttributedWhenAvailable: Bool

    /// Creates a plain text code syntax highlighter.
    public init(useAttributed: Bool) {
        self.preferAttributedWhenAvailable = useAttributed
    }

    public func highlightCode(_ code: String, language: String?) -> Text {
        Text(code)
    }

    public func highlightCodeAttributed(_ code: String, language: String?) -> NSAttributedString? {
        NSAttributedString(string: code)
    }
}

extension CodeSyntaxHighlighter {
    public var preferAttributedWhenAvailable: Bool {
        false
    }
    public func highlightCodeAttributed(_ code: String, language: String?) -> NSAttributedString? { nil }
}

extension CodeSyntaxHighlighter where Self == PlainTextCodeSyntaxHighlighter {
    /// A code syntax highlighter that returns unstyled code blocks.
    public static var plainText: Self {
        PlainTextCodeSyntaxHighlighter(useAttributed: false)
    }
    public static func plainText(useAttributed: Bool) -> Self {
        PlainTextCodeSyntaxHighlighter(useAttributed: useAttributed)
    }
}
