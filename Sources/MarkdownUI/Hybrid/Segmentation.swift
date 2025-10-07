import Foundation

enum Segment: Hashable {
    case textRun([BlockNode])
    case swiftUIBlock(BlockNode)
}

extension Array where Element == BlockNode {
    func makeHybridSegments() -> [Segment] {
        var segments: [Segment] = []
        var buffer: [BlockNode] = []

        func flush() {
            if !buffer.isEmpty {
                segments.append(.textRun(buffer))
                buffer.removeAll()
            }
        }

        for block in self {
            switch block {
            case .paragraph(let inlines):
                let hasInlineImage = inlines.contains { if case .image = $0 { return true } else { return false } }
                if hasInlineImage {
                    flush()
                    segments.append(.swiftUIBlock(block))
                } else {
                    buffer.append(block)
                }
            case .heading, .blockquote, .bulletedList, .numberedList, .taskList, .thematicBreak:
                buffer.append(block)
            case .codeBlock, .table, .htmlBlock:
                flush()
                segments.append(.swiftUIBlock(block))
            }
        }

        flush()
        return segments
    }
}
