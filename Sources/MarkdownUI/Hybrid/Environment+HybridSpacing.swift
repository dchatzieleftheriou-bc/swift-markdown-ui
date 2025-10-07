import SwiftUI

private struct HybridTextRunSpacingKey: EnvironmentKey {
  static let defaultValue: CGFloat = 8
}

extension EnvironmentValues {
  var hybridTextRunSpacing: CGFloat {
    get { self[HybridTextRunSpacingKey.self] }
    set { self[HybridTextRunSpacingKey.self] = newValue }
  }
}

public extension View {
  /// Sets the vertical spacing (in points) applied around UIKit text runs
  /// rendered by `HybridMarkdown`.
  func markdownHybridTextRunSpacing(_ spacing: CGFloat) -> some View {
    self.environment(\.hybridTextRunSpacing, spacing)
  }
}


