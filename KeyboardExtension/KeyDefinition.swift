import CoreGraphics

enum KeyAction: Equatable {
    case character(String)
    case backspace
    case shift
    case switchToNumbers
    case switchToSymbols
    case switchToLetters
    case switchToEmoji
    case space
    case newline
    case nextKeyboard
}

struct KeyDefinition: Equatable {
    let action: KeyAction
    /// Texto exibido na tecla (pode diferir do texto inserido, ex.: "123", "⇧").
    let displayText: String
    /// Peso relativo de largura dentro da linha (tecla padrão = 1.0).
    let widthMultiplier: CGFloat
    /// Variantes acessíveis via long-press (ex.: vogal → acentos). Vazio = sem variantes.
    let longPressVariants: [String]
    /// Estilo visual: teclas de função (shift, backspace, 123...) usam fundo diferente das de caractere.
    let isFunctionKey: Bool

    init(
        action: KeyAction,
        displayText: String,
        widthMultiplier: CGFloat = 1.0,
        longPressVariants: [String] = [],
        isFunctionKey: Bool = false
    ) {
        self.action = action
        self.displayText = displayText
        self.widthMultiplier = widthMultiplier
        self.longPressVariants = longPressVariants
        self.isFunctionKey = isFunctionKey
    }
}
