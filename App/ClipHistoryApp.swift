import SwiftUI

@main
struct ClipHistoryApp: App {
    @StateObject private var themeManager = ThemeManager()
    @ObservedObject private var store = ClipboardStore.shared
    @State private var onboardingCompleted = AppGroupConstants.sharedDefaults?.bool(forKey: AppGroupConstants.onboardingCompletedKey) ?? false

    var body: some Scene {
        WindowGroup {
            Group {
                if onboardingCompleted {
                    HistoryListView(store: store)
                } else {
                    OnboardingView {
                        AppGroupConstants.sharedDefaults?.set(true, forKey: AppGroupConstants.onboardingCompletedKey)
                        onboardingCompleted = true
                    }
                }
            }
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.preference.colorScheme)
        }
    }
}
