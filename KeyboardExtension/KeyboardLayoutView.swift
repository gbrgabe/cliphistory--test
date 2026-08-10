import UIKit

protocol KeyboardLayoutViewDelegate: AnyObject {
    func keyboardLayoutView(_ view: KeyboardLayoutView, didInsertCharacter character: String)
    func keyboardLayoutViewDidRequestBackspace(_ view: KeyboardLayoutView)
    func keyboardLayoutViewDidRequestSpace(_ view: KeyboardLayoutView)
    func keyboardLayoutViewDidRequestNewline(_ view: KeyboardLayoutView)
    func keyboardLayoutViewDidRequestEmojiMode(_ view: KeyboardLayoutView)
    func keyboardLayoutViewDidLongPressShift(_ view: KeyboardLayoutView)
    /// Disparado em qualquer toque de tecla — usado para checar o clipboard a cada toque, por spec.
    func keyboardLayoutViewDidRegisterKeyPress(_ view: KeyboardLayoutView)
}

/// Monta e controla o teclado QWERTY pt-BR (letras/números/símbolos) via UIKit puro.
final class KeyboardLayoutView: UIView {
    weak var delegate: KeyboardLayoutViewDelegate?

    /// Chamado sempre que uma nova tecla de globo é criada (a view é reconstruída a cada
    /// troca de modo), para o KeyboardViewController religar handleInputModeList(from:with:).
    var onNextKeyboardButtonCreated: ((UIButton) -> Void)?

    private var mode: KeyboardMode = .letters
    private var shiftState: ShiftState = .uppercase
    private var lastShiftTapTime: TimeInterval = 0

    private let rowsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupRowsStack()
        rebuild()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupRowsStack() {
        rowsStack.axis = .vertical
        rowsStack.distribution = .fillEqually
        rowsStack.spacing = 8
        rowsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowsStack)
        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            rowsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            rowsStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            rowsStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ])
    }

    private func rebuild() {
        rowsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let rows = KeyboardLayout.rows(for: mode, shiftState: shiftState)
        for row in rows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fill
            rowStack.spacing = 6
            rowsStack.addArrangedSubview(rowStack)

            var buttons: [KeyButton] = []
            for keyDefinition in row {
                let button = KeyButton(keyDefinition: keyDefinition)
                button.overlayContainer = self
                wireActions(for: button)
                rowStack.addArrangedSubview(button)
                buttons.append(button)

                if case .nextKeyboard = keyDefinition.action {
                    onNextKeyboardButtonCreated?(button)
                }
            }
            applyRelativeWidths(to: buttons)
        }
    }

    /// Larguras proporcionais dentro da linha (ex.: barra de espaço bem mais larga que uma letra),
    /// usando a primeira tecla da linha como unidade de referência.
    private func applyRelativeWidths(to buttons: [KeyButton]) {
        guard let reference = buttons.first else { return }
        for button in buttons where button !== reference {
            let ratio = button.keyDefinition.widthMultiplier / reference.keyDefinition.widthMultiplier
            button.widthAnchor.constraint(equalTo: reference.widthAnchor, multiplier: ratio).isActive = true
        }
    }

    // MARK: - Wiring

    private func wireActions(for button: KeyButton) {
        button.onCharacterResolved = { [weak self] text in
            guard let self else { return }
            self.delegate?.keyboardLayoutViewDidRegisterKeyPress(self)
            self.insertCharacter(text)
        }
        button.addTarget(self, action: #selector(handleKeyTap(_:)), for: .touchUpInside)

        if case .shift = button.keyDefinition.action {
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleShiftLongPress(_:)))
            longPress.minimumPressDuration = 0.35
            button.addGestureRecognizer(longPress)
        }
    }

    @objc private func handleKeyTap(_ sender: KeyButton) {
        delegate?.keyboardLayoutViewDidRegisterKeyPress(self)

        switch sender.keyDefinition.action {
        case .character(let text):
            insertCharacter(text)
        case .backspace:
            delegate?.keyboardLayoutViewDidRequestBackspace(self)
        case .shift:
            handleShiftTap()
        case .switchToNumbers:
            mode = .numbers
            rebuild()
        case .switchToSymbols:
            mode = .symbols
            rebuild()
        case .switchToLetters:
            mode = .letters
            rebuild()
        case .switchToEmoji:
            delegate?.keyboardLayoutViewDidRequestEmojiMode(self)
        case .space:
            delegate?.keyboardLayoutViewDidRequestSpace(self)
        case .newline:
            delegate?.keyboardLayoutViewDidRequestNewline(self)
        case .nextKeyboard:
            break // tratado via handleInputModeList(from:with:) diretamente pelo KeyboardViewController
        }
    }

    private func insertCharacter(_ text: String) {
        delegate?.keyboardLayoutView(self, didInsertCharacter: text)
        // Como o teclado nativo: shift simples volta pra minúscula após uma letra (caps lock não).
        if shiftState == .uppercase {
            shiftState = .lowercase
            rebuild()
        }
    }

    // MARK: - Shift (tap / duplo-tap / long-press)

    private func handleShiftTap() {
        let now = Date().timeIntervalSince1970
        let isDoubleTap = (now - lastShiftTapTime) < 0.35
        lastShiftTapTime = now

        switch shiftState {
        case .lowercase:
            shiftState = isDoubleTap ? .capsLock : .uppercase
        case .uppercase:
            shiftState = isDoubleTap ? .capsLock : .lowercase
        case .capsLock:
            shiftState = .lowercase
        }
        rebuild()
    }

    @objc private func handleShiftLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard recognizer.state == .began, let button = recognizer.view as? KeyButton else { return }
        // Evita que o touchUpInside padrão também dispare o toggle de shift ao soltar.
        button.cancelTracking(with: nil)
        delegate?.keyboardLayoutViewDidLongPressShift(self)
    }
}
