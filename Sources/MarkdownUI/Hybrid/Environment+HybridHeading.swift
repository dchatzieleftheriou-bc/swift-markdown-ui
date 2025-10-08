import SwiftUI

public struct HybridHeadingMetrics: Hashable {
  public var sizeScale: CGFloat
  public var sizeInPoints: CGFloat?
  public var weight: Font.Weight?
  public var foregroundColor: Color?
  public var paragraphSpacingBefore: CGFloat?
  public var paragraphSpacingAfter: CGFloat?

  public init(sizeScale: CGFloat, weight: Font.Weight? = nil, foregroundColor: Color? = nil, paragraphSpacingBefore: CGFloat? = nil, paragraphSpacingAfter: CGFloat? = nil) {
    self.sizeScale = sizeScale
    self.sizeInPoints = nil
    self.weight = weight
    self.foregroundColor = foregroundColor
    self.paragraphSpacingBefore = paragraphSpacingBefore
    self.paragraphSpacingAfter = paragraphSpacingAfter
  }

  public init(points: CGFloat, weight: Font.Weight? = nil, foregroundColor: Color? = nil, paragraphSpacingBefore: CGFloat? = nil, paragraphSpacingAfter: CGFloat? = nil) {
    self.sizeScale = 1.0
    self.sizeInPoints = points
    self.weight = weight
    self.foregroundColor = foregroundColor
    self.paragraphSpacingBefore = paragraphSpacingBefore
    self.paragraphSpacingAfter = paragraphSpacingAfter
  }
}

private struct HybridHeadingMetricsKey: EnvironmentKey {
  static let defaultValue: [Int: HybridHeadingMetrics] = [
    1: .init(sizeScale: 2.0, weight: .semibold),
    2: .init(sizeScale: 1.5, weight: .semibold),
    3: .init(sizeScale: 1.25, weight: .semibold),
    4: .init(sizeScale: 1.0, weight: .semibold),
    5: .init(sizeScale: 0.875, weight: .semibold),
    6: .init(sizeScale: 0.85, weight: .semibold)
  ]
}

extension EnvironmentValues {
  var hybridHeadingMetrics: [Int: HybridHeadingMetrics] {
    get { self[HybridHeadingMetricsKey.self] }
    set { self[HybridHeadingMetricsKey.self] = newValue }
  }
}

public extension View {
  func markdownHybridHeadingStyle(_ metrics: [Int: HybridHeadingMetrics]) -> some View {
    self.environment(\.hybridHeadingMetrics, metrics)
  }
}


