import Foundation

/// Identificadores e chaves compartilhadas entre o app principal e a keyboard extension.
/// Centralizado aqui para não haver strings duplicadas/desalinhadas entre os dois targets.
enum AppGroupConstants {
    static let appGroupIdentifier = "group.com.mae.cliphistory"

    /// Nome do arquivo JSON com o histórico, dentro do container do App Group.
    static let historyFileName = "clip_history.json"

    /// Chave no UserDefaults compartilhado com o último changeCount do pasteboard já processado.
    static let lastPasteboardChangeCountKey = "lastPasteboardChangeCount"

    /// Chave no UserDefaults compartilhado com a preferência de tema (ThemePreference.rawValue).
    static let themePreferenceKey = "themePreference"

    /// Chave no UserDefaults compartilhado indicando se o onboarding já foi concluído.
    static let onboardingCompletedKey = "onboardingCompleted"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
}
