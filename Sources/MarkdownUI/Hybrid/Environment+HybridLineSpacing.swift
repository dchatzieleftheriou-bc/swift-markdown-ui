import SwiftUI

private struct HybridLineSpacingKey: EnvironmentKey {
  static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
  var hybridLineSpacing: CGFloat? {
    get { self[HybridLineSpacingKey.self] }
    set { self[HybridLineSpacingKey.self] = newValue }
  }
}

public extension View {
  /// Sets the line spacing (distance in points between baselines) for text runs
  /// rendered by the UIKit bridge.
  func markdownHybridLineSpacing(_ spacing: CGFloat?) -> some View {
    environment(\.hybridLineSpacing, spacing)
  }
}
