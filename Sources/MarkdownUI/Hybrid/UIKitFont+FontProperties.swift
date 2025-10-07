import SwiftUI
import CoreText
#if os(iOS)
import UIKit

extension UIFont {
  static func withProperties(_ p: FontProperties) -> UIFont {
    let size = round(p.size * p.scale)

    func weight(_ w: Font.Weight) -> UIFont.Weight {
      switch w {
      case .ultraLight: return .ultraLight
      case .thin: return .thin
      case .light: return .light
      case .regular: return .regular
      case .medium: return .medium
      case .semibold: return .semibold
      case .bold: return .bold
      case .heavy: return .heavy
      case .black: return .black
      default: return .regular
      }
    }

    var base: UIFont
    switch p.family {
    case .system:
      if p.familyVariant == .monospaced {
        base = .monospacedSystemFont(ofSize: size, weight: weight(p.weight))
      } else {
        base = .systemFont(ofSize: size, weight: weight(p.weight))
      }
    case .custom(let name):
      base = UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: weight(p.weight))
    }

    var descriptor = base.fontDescriptor
    var traits: UIFontDescriptor.SymbolicTraits = []
    if p.style == .italic { traits.insert(.traitItalic) }
    if !traits.isEmpty, let desc = descriptor.withSymbolicTraits(traits) { descriptor = desc }

    var featureSettings: [[UIFontDescriptor.FeatureKey: Int]] = []
    switch p.capsVariant {
    case .smallCaps, .uppercaseSmallCaps, .lowercaseSmallCaps:
      featureSettings.append([
        .type: kLetterCaseType,
        .selector: kSmallCapsSelector
      ])
    case .normal:
      break
    }

    if !featureSettings.isEmpty {
      descriptor = descriptor.addingAttributes([
        UIFontDescriptor.AttributeName.featureSettings: featureSettings
      ])
    }

    base = UIFont(descriptor: descriptor, size: size)

    return base
  }
}

#endif


