import SwiftUI

private struct HybridQuoteBarColorKey: EnvironmentKey {
    static let defaultValue: Color = Color.secondary
}

private struct HybridHeadingDividerColorKey: EnvironmentKey {
    static let defaultValue: Color = Color.secondary
}

private struct HybridHeadingDividerEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

private struct HybridThematicBreakColorKey: EnvironmentKey {
    static let defaultValue: Color = Color.secondary
}

private struct HybridThematicBreakThicknessKey: EnvironmentKey {
    static let defaultValue: CGFloat = 2.0
}

extension EnvironmentValues {
    var hybridQuoteBarColor: Color {
        get { self[HybridQuoteBarColorKey.self] }
        set { self[HybridQuoteBarColorKey.self] = newValue }
    }
    var hybridHeadingDividerColor: Color {
        get { self[HybridHeadingDividerColorKey.self] }
        set { self[HybridHeadingDividerColorKey.self] = newValue }
    }
    var hybridHeadingDividerEnabled: Bool {
        get { self[HybridHeadingDividerEnabledKey.self] }
        set { self[HybridHeadingDividerEnabledKey.self] = newValue }
    }
    var hybridThematicBreakColor: Color {
        get { self[HybridThematicBreakColorKey.self] }
        set { self[HybridThematicBreakColorKey.self] = newValue }
    }
    var hybridThematicBreakThickness: CGFloat {
        get { self[HybridThematicBreakThicknessKey.self] }
        set { self[HybridThematicBreakThicknessKey.self] = newValue }
    }
}

public extension View {
    func markdownHybridQuoteBarColor(_ color: Color) -> some View {
        environment(\.hybridQuoteBarColor, color)
    }
    func markdownHybridHeadingDividerColor(_ color: Color) -> some View {
        environment(\.hybridHeadingDividerColor, color)
    }
    func markdownHybridHeadingDividerEnabled(_ enabled: Bool) -> some View {
        environment(\.hybridHeadingDividerEnabled, enabled)
    }
    func markdownHybridThematicBreakColor(_ color: Color) -> some View {
        environment(\.hybridThematicBreakColor, color)
    }
    func markdownHybridThematicBreakThickness(_ thickness: CGFloat) -> some View {
        environment(\.hybridThematicBreakThickness, thickness)
    }
}


