import SwiftUI
import UIKit

enum ThemePreference: String, Codable, CaseIterable {
    case system
    case light
    case dark

    var label: String {
        switch self {
        case .system: return "Sistema"
        case .light: return "Claro"
        case .dark: return "Escuro"
        }
    }

    /// Usado pelo app principal (SwiftUI).
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Usado pela keyboard extension (UIKit).
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// Lê a preferência salva no App Group. Usada pelos dois targets.
    static func loadFromAppGroup() -> ThemePreference {
        guard
            let raw = AppGroupConstants.sharedDefaults?.string(forKey: AppGroupConstants.themePreferenceKey),
            let value = ThemePreference(rawValue: raw)
        else {
            return .system
        }
        return value
    }

    func saveToAppGroup() {
        AppGroupConstants.sharedDefaults?.set(rawValue, forKey: AppGroupConstants.themePreferenceKey)
    }
}
