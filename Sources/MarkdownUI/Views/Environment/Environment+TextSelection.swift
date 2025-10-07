import SwiftUI

public extension View {
  /// Enables multi-line text selection for Markdown inlines on supported platforms.
  ///
  /// On iOS this switches inline rendering to a selectable UIKit-backed text view
  /// when possible. Other platforms ignore this setting.
  /// - Parameter enabled: Whether selection should be enabled.
  func markdownTextSelection(_ enabled: Bool = true) -> some View {
    self.environment(\.markdownTextSelection, enabled)
  }
}

private struct MarkdownTextSelectionKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

extension EnvironmentValues {
  var markdownTextSelection: Bool {
    get { self[MarkdownTextSelectionKey.self] }
    set { self[MarkdownTextSelectionKey.self] = newValue }
  }
}



