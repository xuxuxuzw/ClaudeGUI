import SwiftUI
import SwiftTerm

// MARK: - Color Scheme

enum ColorScheme: String, CaseIterable {
    case basic = "Basic"
    case clearDark = "Clear Dark"
    case clearLight = "Clear Light"
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var current: ColorScheme {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "claudeGUI_colorScheme")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "claudeGUI_colorScheme") ?? ""
        self.current = ColorScheme(rawValue: saved) ?? .basic
    }

    func next() {
        let all = ColorScheme.allCases
        guard let idx = all.firstIndex(of: current) else { return }
        current = all[(idx + 1) % all.count]
    }
}

// MARK: - Unified theme colors

enum AppTheme {
    // Backgrounds
    static var bgDeep: SwiftUI.Color {
        switch ThemeManager.shared.current {
        case .basic:      return SwiftUI.Color(white: 0.08)
        case .clearDark:  return SwiftUI.Color(white: 0.06).opacity(0.92)
        case .clearLight: return SwiftUI.Color(red: 0.96, green: 0.97, blue: 0.98)
        }
    }
    static var bgBase: SwiftUI.Color {
        switch ThemeManager.shared.current {
        case .basic:      return SwiftUI.Color(white: 0.10)
        case .clearDark:  return SwiftUI.Color(white: 0.08).opacity(0.88)
        case .clearLight: return SwiftUI.Color(red: 0.98, green: 0.98, blue: 0.99)
        }
    }
    static var bgSurface: SwiftUI.Color {
        switch ThemeManager.shared.current {
        case .basic:      return SwiftUI.Color(white: 0.12)
        case .clearDark:  return SwiftUI.Color(white: 0.12).opacity(0.80)
        case .clearLight: return SwiftUI.Color.white
        }
    }
    static var bgElevated: SwiftUI.Color {
        switch ThemeManager.shared.current {
        case .basic:      return SwiftUI.Color(white: 0.15)
        case .clearDark:  return SwiftUI.Color(white: 0.16).opacity(0.75)
        case .clearLight: return SwiftUI.Color(red: 0.93, green: 0.94, blue: 0.96)
        }
    }

    // Borders
    static var borderSubtle: SwiftUI.Color {
        switch ThemeManager.shared.current {
        case .basic:      return SwiftUI.Color(white: 0.18)
        case .clearDark:  return SwiftUI.Color(white: 0.22).opacity(0.50)
        case .clearLight: return SwiftUI.Color(red: 0.88, green: 0.90, blue: 0.92)
        }
    }
    static var borderDefault: SwiftUI.Color {
        switch ThemeManager.shared.current {
        case .basic:      return SwiftUI.Color(white: 0.22)
        case .clearDark:  return SwiftUI.Color(white: 0.28).opacity(0.50)
        case .clearLight: return SwiftUI.Color(red: 0.82, green: 0.85, blue: 0.88)
        }
    }

    // Text
    static var textPrimary: SwiftUI.Color {
        switch ThemeManager.shared.current {
        case .basic:      return SwiftUI.Color(white: 0.92)
        case .clearDark:  return SwiftUI.Color(white: 0.95)
        case .clearLight: return SwiftUI.Color(red: 0.19, green: 0.24, blue: 0.27)
        }
    }
    static var textSecondary: SwiftUI.Color {
        switch ThemeManager.shared.current {
        case .basic:      return SwiftUI.Color(white: 0.55)
        case .clearDark:  return SwiftUI.Color(white: 0.60)
        case .clearLight: return SwiftUI.Color(red: 0.42, green: 0.48, blue: 0.53)
        }
    }
    static var textMuted: SwiftUI.Color {
        switch ThemeManager.shared.current {
        case .basic:      return SwiftUI.Color(white: 0.40)
        case .clearDark:  return SwiftUI.Color(white: 0.48)
        case .clearLight: return SwiftUI.Color(red: 0.56, green: 0.60, blue: 0.64)
        }
    }

    // Status colors
    static let statusWaiting = SwiftUI.Color.green
    static let statusWorking = SwiftUI.Color.orange
    static let statusCompleted = SwiftUI.Color.blue
    static let statusIdle = SwiftUI.Color.gray

    // Accent with subtle opacity for backgrounds
    static let accentBg = SwiftUI.Color.accentColor.opacity(0.10)
    static let accentBgHover = SwiftUI.Color.accentColor.opacity(0.15)

    // Divider
    static var divider: SwiftUI.Color {
        switch ThemeManager.shared.current {
        case .basic, .clearDark: return SwiftUI.Color.white.opacity(0.08)
        case .clearLight:        return SwiftUI.Color.black.opacity(0.08)
        }
    }

    // Hover
    static var hoverBg: SwiftUI.Color {
        switch ThemeManager.shared.current {
        case .basic, .clearDark: return SwiftUI.Color.white.opacity(0.05)
        case .clearLight:        return SwiftUI.Color.black.opacity(0.04)
        }
    }

    // MARK: - Terminal colors

    static var termBg: SwiftTerm.Color {
        switch ThemeManager.shared.current {
        case .basic:      return SwiftTerm.Color(red: 6554, green: 6554, blue: 7864)
        case .clearDark:  return SwiftTerm.Color(red: 5140, green: 5140, blue: 8192)
        case .clearLight: return SwiftTerm.Color(red: 65535, green: 65535, blue: 65535)
        }
    }

    static var termFg: SwiftTerm.Color {
        switch ThemeManager.shared.current {
        case .basic:      return SwiftTerm.Color(red: 58982, green: 58982, blue: 58982)
        case .clearDark:  return SwiftTerm.Color(red: 62258, green: 62258, blue: 64250)
        case .clearLight: return SwiftTerm.Color(red: 15038, green: 18498, blue: 20774)
        }
    }

    static var termContainerBg: NSColor {
        switch ThemeManager.shared.current {
        case .basic:      return NSColor(white: 0.08, alpha: 1.0)
        case .clearDark:  return NSColor(white: 0.06, alpha: 0.92)
        case .clearLight: return NSColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0)
        }
    }
}

/// Consistent corner radius values.
enum AppRadius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 6
    static let lg: CGFloat = 8
    static let xl: CGFloat = 10
}

/// Consistent spacing values.
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 24
}
