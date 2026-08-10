import Foundation

enum KeyboardMode {
    case letters
    case numbers
    case symbols
}

enum ShiftState {
    case lowercase
    case uppercase
    case capsLock

    var isUppercase: Bool { self != .lowercase }
}

/// Dados puros do layout QWERTY pt-BR. Sem nenhuma lógica de UI aqui.
enum KeyboardLayout {

    static func rows(for mode: KeyboardMode, shiftState: ShiftState) -> [[KeyDefinition]] {
        switch mode {
        case .letters:
            return letterRows(uppercase: shiftState.isUppercase)
        case .numbers:
            return numberRows
        case .symbols:
            return symbolRows
        }
    }

    // MARK: - Letras (pt-BR)

    private static func letterRows(uppercase: Bool) -> [[KeyDefinition]] {
        let row1Letters = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
        let row2Letters = ["a", "s", "d", "f", "g", "h", "j", "k", "l", "ç"]
        let row3Letters = ["z", "x", "c", "v", "b", "n", "m"]

        let accentVariants: [String: [String]] = [
            "a": ["á", "à", "â", "ã"],
            "e": ["é", "è", "ê"],
            "i": ["í", "ì", "î"],
            "o": ["ó", "ò", "ô", "õ"],
            "u": ["ú", "ù", "û"],
            "c": ["ç"]
        ]

        func character(_ letter: String) -> KeyDefinition {
            let display = uppercase ? letter.uppercased() : letter
            let variants = (accentVariants[letter] ?? []).map { uppercase ? $0.uppercased() : $0 }
            return KeyDefinition(action: .character(display), displayText: display, longPressVariants: variants)
        }

        let row1 = row1Letters.map(character)
        let row2 = row2Letters.map(character)

        let shiftKey = KeyDefinition(
            action: .shift,
            displayText: uppercase ? "⇧" : "⇧",
            widthMultiplier: 1.5,
            isFunctionKey: true
        )
        let backspaceKey = KeyDefinition(action: .backspace, displayText: "⌫", widthMultiplier: 1.5, isFunctionKey: true)
        let row3 = [shiftKey] + row3Letters.map(character) + [backspaceKey]

        let row4 = bottomRow(modeKey: KeyDefinition(
            action: .switchToNumbers,
            displayText: "123",
            widthMultiplier: 1.5,
            isFunctionKey: true
        ))

        return [row1, row2, row3, row4]
    }

    // MARK: - Números

    private static var numberRows: [[KeyDefinition]] {
        let row1 = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"].map {
            KeyDefinition(action: .character($0), displayText: $0)
        }
        let row2 = ["-", "/", ":", ";", "(", ")", "R$", "&", "@", "\""].map {
            KeyDefinition(action: .character($0), displayText: $0)
        }
        let symbolsSwitch = KeyDefinition(action: .switchToSymbols, displayText: "#+=", widthMultiplier: 1.5, isFunctionKey: true)
        let row3Middle = [".", ",", "?", "!", "'"].map { KeyDefinition(action: .character($0), displayText: $0) }
        let backspaceKey = KeyDefinition(action: .backspace, displayText: "⌫", widthMultiplier: 1.5, isFunctionKey: true)
        let row3 = [symbolsSwitch] + row3Middle + [backspaceKey]

        let row4 = bottomRow(modeKey: KeyDefinition(
            action: .switchToLetters,
            displayText: "ABC",
            widthMultiplier: 1.5,
            isFunctionKey: true
        ))

        return [row1, row2, row3, row4]
    }

    // MARK: - Símbolos

    private static var symbolRows: [[KeyDefinition]] {
        let row1 = ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="].map {
            KeyDefinition(action: .character($0), displayText: $0)
        }
        let row2 = ["_", "\\", "|", "~", "<", ">", "€", "£", "¥", "•"].map {
            KeyDefinition(action: .character($0), displayText: $0)
        }
        let numbersSwitch = KeyDefinition(action: .switchToNumbers, displayText: "123", widthMultiplier: 1.5, isFunctionKey: true)
        let row3Middle = [".", ",", "?", "!", "'"].map { KeyDefinition(action: .character($0), displayText: $0) }
        let backspaceKey = KeyDefinition(action: .backspace, displayText: "⌫", widthMultiplier: 1.5, isFunctionKey: true)
        let row3 = [numbersSwitch] + row3Middle + [backspaceKey]

        let row4 = bottomRow(modeKey: KeyDefinition(
            action: .switchToLetters,
            displayText: "ABC",
            widthMultiplier: 1.5,
            isFunctionKey: true
        ))

        return [row1, row2, row3, row4]
    }

    // MARK: - Linha inferior (comum a todos os modos)

    private static func bottomRow(modeKey: KeyDefinition) -> [KeyDefinition] {
        let emojiKey = KeyDefinition(action: .switchToEmoji, displayText: "😀", widthMultiplier: 1.0, isFunctionKey: true)
        let globeKey = KeyDefinition(action: .nextKeyboard, displayText: "🌐", widthMultiplier: 1.0, isFunctionKey: true)
        let spaceKey = KeyDefinition(action: .space, displayText: "espaço", widthMultiplier: 5.0, isFunctionKey: true)
        let returnKey = KeyDefinition(action: .newline, displayText: "retorno", widthMultiplier: 1.8, isFunctionKey: true)
        return [modeKey, emojiKey, globeKey, spaceKey, returnKey]
    }
}
