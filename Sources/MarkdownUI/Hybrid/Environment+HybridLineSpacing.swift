import SwiftUI

private struct HybridLineSpacingKey: EnvironmentKey {
  static let defaultValue: CGFloat? = nil
}

private struct HybridLineHeightKey: EnvironmentKey {
  static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
  var hybridLineSpacing: CGFloat? {
    get { self[HybridLineSpacingKey.self] }
    set { self[HybridLineSpacingKey.self] = newValue }
  }
  var hybridLineHeight: CGFloat? {
    get { self[HybridLineHeightKey.self] }
    set { self[HybridLineHeightKey.self] = newValue }
  }
}

public extension View {
  /// Sets the line spacing (distance in points between baselines) for text runs
  /// rendered by the UIKit bridge.
  func markdownHybridLineSpacing(_ spacing: CGFloat?) -> some View {
    environment(\.hybridLineSpacing, spacing)
  }

  /// Sets a fixed line height (in points) for text runs rendered by the UIKit bridge.
  /// If provided, this takes precedence over line spacing.
  func markdownHybridLineHeight(_ height: CGFloat?) -> some View {
    environment(\.hybridLineHeight, height)
  }
}
