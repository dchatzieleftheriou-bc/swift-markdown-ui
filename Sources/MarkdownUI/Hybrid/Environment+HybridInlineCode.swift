import SwiftUI

public struct HybridInlineCodeOverlay: Hashable {
  public var enabled: Bool
  public var color: Color?
  public var padding: CGFloat
  public var cornerRadius: CGFloat

  public init(
    enabled: Bool = true,
    color: Color? = nil,
    padding: CGFloat = 2,
    cornerRadius: CGFloat = 4
  ) {
    self.enabled = enabled
    self.color = color
    self.padding = padding
    self.cornerRadius = cornerRadius
  }
}

private struct HybridInlineCodeOverlayKey: EnvironmentKey {
  static let defaultValue = HybridInlineCodeOverlay()
}

extension EnvironmentValues {
  var hybridInlineCodeOverlay: HybridInlineCodeOverlay {
    get { self[HybridInlineCodeOverlayKey.self] }
    set { self[HybridInlineCodeOverlayKey.self] = newValue }
  }
}

public extension View {
  /// Configures a rounded overlay for inline code runs rendered via the hybrid UIKit text view.
  /// - Parameters:
  ///   - enabled: When true, draws rounded background layers and skips NSAttributedString background fills.
  ///   - color: Optional override color for the overlay. If nil, uses the run's background color if present.
  ///   - padding: Uniform padding around the code run.
  ///   - cornerRadius: Corner radius for the overlay.
  func markdownHybridInlineCodeOverlay(
    enabled: Bool,
    color: Color? = nil,
    padding: CGFloat = 2,
    cornerRadius: CGFloat = 4
  ) -> some View {
    self.environment(\.hybridInlineCodeOverlay, .init(enabled: enabled, color: color, padding: padding, cornerRadius: cornerRadius))
  }
}


