import SwiftUI

private struct HybridCodeBlockMinHeightKey: EnvironmentKey {
  static let defaultValue: CGFloat = 44
}

private struct HybridCodeBlockMaxHeightKey: EnvironmentKey {
  static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
  var hybridCodeBlockMinHeight: CGFloat {
    get { self[HybridCodeBlockMinHeightKey.self] }
    set { self[HybridCodeBlockMinHeightKey.self] = newValue }
  }
  var hybridCodeBlockMaxHeight: CGFloat? {
    get { self[HybridCodeBlockMaxHeightKey.self] }
    set { self[HybridCodeBlockMaxHeightKey.self] = newValue }
  }
}

public extension View {
  func markdownHybridCodeBlockHeight(min: CGFloat, max: CGFloat?) -> some View {
    environment(\.hybridCodeBlockMinHeight, min)
      .environment(\.hybridCodeBlockMaxHeight, max)
  }
}


