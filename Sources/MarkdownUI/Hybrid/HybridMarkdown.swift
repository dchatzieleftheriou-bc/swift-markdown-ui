import SwiftUI

public struct HybridMarkdown: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme.text) private var text

    private let content: MarkdownContent
    private let baseURL: URL?
    private let imageBaseURL: URL?

    public init(_ content: MarkdownContent, baseURL: URL? = nil, imageBaseURL: URL? = nil) {
        self.content = content
        self.baseURL = baseURL
        self.imageBaseURL = imageBaseURL ?? baseURL
    }

    public init(_ markdown: String, baseURL: URL? = nil, imageBaseURL: URL? = nil) {
        self.init(MarkdownContent(markdown), baseURL: baseURL, imageBaseURL: imageBaseURL)
    }

    public var body: some View {
        TextStyleAttributesReader { attributes in
            VStack(alignment: .leading, spacing: 0) {
                BlockSequence(segments) { _, segment in
                    switch segment {
                    case .textRun(let runBlocks):
                        HybridTextRun(blocks: runBlocks)
                    case .swiftUIBlock(let block):
                        block
                    }
                }
            }
            .foregroundColor(attributes.foregroundColor)
            .background(attributes.backgroundColor)
            .modifier(HybridScaledFontSizeModifier(attributes.fontProperties?.size))
        }
        .textStyle(self.text)
        .environment(\.baseURL, self.baseURL)
        .environment(\.imageBaseURL, self.imageBaseURL)
    }

    private var blocks: [BlockNode] {
        self.content.blocks.filterImagesMatching(colorScheme: self.colorScheme)
    }

    private var segments: [Segment] {
        blocks.makeHybridSegments()
    }
}

#if os(iOS)
private struct HybridTextRun: View {
    @Environment(\.hybridTextRunSpacing) private var spacing
    let blocks: [BlockNode]
    var top: CGFloat?
    var bottom: CGFloat?

    var body: some View {
        UIKitTextRunView(blocks: blocks)
            .preference(
                key: BlockMarginsPreference.self,
                value: BlockMargin(top: top ?? 0, bottom: bottom ?? spacing)
            )
            .fixedSize(horizontal: false, vertical: true)
    }
}
#endif
private struct HybridScaledFontSizeModifier: ViewModifier {
    @ScaledMetric private var size: CGFloat

    init(_ size: CGFloat?) {
        self._size = ScaledMetric(wrappedValue: size ?? FontProperties.defaultSize, relativeTo: .body)
    }

    func body(content: Content) -> some View {
        content.markdownTextStyle {
            FontSize(self.size)
        }
    }
}


