import Foundation

extension Sequence where Element == InlineNode {
  func renderAttributedString(
    baseURL: URL?,
    textStyles: InlineTextStyles,
    softBreakMode: SoftBreak.Mode,
    attributes: AttributeContainer
  ) -> AttributedString {
    var result = AttributedString()
    for inline in self {
      result += inline.renderAttributedString(
        baseURL: baseURL,
        textStyles: textStyles,
        softBreakMode: softBreakMode,
        attributes: attributes
      )
    }
    return result
  }
}






