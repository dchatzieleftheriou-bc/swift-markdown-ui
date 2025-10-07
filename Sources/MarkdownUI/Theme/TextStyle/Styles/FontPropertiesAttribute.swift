import Foundation

enum FontPropertiesAttribute: AttributedStringKey {
  typealias Value = FontProperties
  static let name = "fontProperties"
}

// Semantic indent level for list/blockquote lines in hybrid UIKit rendering
enum MarkdownIndentLevelAttribute: AttributedStringKey {
  typealias Value = Int
  static let name = "markdownIndentLevel"
}

// Marks text that belongs to a blockquote for UIKit overlay drawing
// Quote level for blockquotes (1 = top-level, 2 = nested, ...)
enum MarkdownQuoteLevelAttribute: AttributedStringKey {
  typealias Value = Int
  static let name = "markdownQuoteLevel"
}

// Paragraph spacing (points) to apply before/after a paragraph
enum MarkdownParagraphSpacingBeforeAttribute: AttributedStringKey {
  typealias Value = CGFloat
  static let name = "markdownParagraphSpacingBefore"
}

enum MarkdownParagraphSpacingAfterAttribute: AttributedStringKey {
  typealias Value = CGFloat
  static let name = "markdownParagraphSpacingAfter"
}

// Marks inline code runs so UIKit can selectively apply background colors
enum MarkdownCodeInlineAttribute: AttributedStringKey {
  typealias Value = Bool
  static let name = "markdownCodeInline"
}

// Heading level marker for UIKit overlay (dividers)
enum MarkdownHeadingLevelAttribute: AttributedStringKey {
  typealias Value = Int
  static let name = "markdownHeadingLevel"
}

// Thematic break marker for UIKit overlay rendering
enum MarkdownThematicBreakAttribute: AttributedStringKey {
  typealias Value = Bool
  static let name = "markdownThematicBreak"
}

extension AttributeScopes {
  var markdownUI: MarkdownUIAttributes.Type {
    MarkdownUIAttributes.self
  }

  struct MarkdownUIAttributes: AttributeScope {
    let swiftUI: SwiftUIAttributes
    let fontProperties: FontPropertiesAttribute
    let selectionEnabledForMarkdown: MarkdownSelectionAttribute
    let markdownIndentLevel: MarkdownIndentLevelAttribute
    let markdownQuoteLevel: MarkdownQuoteLevelAttribute
    let markdownParagraphSpacingBefore: MarkdownParagraphSpacingBeforeAttribute
    let markdownParagraphSpacingAfter: MarkdownParagraphSpacingAfterAttribute
    let markdownCodeInline: MarkdownCodeInlineAttribute
    let markdownHeadingLevel: MarkdownHeadingLevelAttribute
    let markdownThematicBreak: MarkdownThematicBreakAttribute
  }
}

extension AttributeDynamicLookup {
  subscript<T: AttributedStringKey>(
    dynamicMember keyPath: KeyPath<AttributeScopes.MarkdownUIAttributes, T>
  ) -> T {
    return self[T.self]
  }
}

extension AttributedString {
  func resolvingFonts() -> AttributedString {
    var output = self

    for run in output.runs {
      guard let fontProperties = run.fontProperties else {
        continue
      }
      output[run.range].font = .withProperties(fontProperties)
      output[run.range].fontProperties = nil
    }

    return output
  }
}
