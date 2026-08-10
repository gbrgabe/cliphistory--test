import SwiftUI

/// Lê/escreve a preferência de tema no App Group, para que tanto o app quanto
/// a keyboard extension enxerguem a mesma escolha.
final class ThemeManager: ObservableObject {
    @Published var preference: ThemePreference {
        didSet { preference.saveToAppGroup() }
    }

    init() {
        preference = ThemePreference.loadFromAppGroup()
    }
}
