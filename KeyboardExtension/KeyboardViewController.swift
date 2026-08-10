import UIKit

final class KeyboardViewController: UIInputViewController {
    private let keyboardLayoutView = KeyboardLayoutView()
    private let emojiKeyboardView = EmojiKeyboardView()
    private let fullAccessBanner = FullAccessBannerView()
    private var historyPopupView: HistoryPopupView?

    private let store = ClipboardStore.shared

    private static let keyboardHeight: CGFloat = 260

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeightConstraint()
        setupKeyboardLayoutView()
        setupEmojiKeyboardView()
        setupFullAccessBanner()
        wireNextKeyboardButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
        updateFullAccessBanner()
        store.load()
        store.checkPasteboardForChanges(hasFullAccess: hasFullAccess)
    }

    // MARK: - Setup

    private func setupHeightConstraint() {
        // Prioridade 999 (não .required) para não conflitar com as constraints de altura
        // que o próprio sistema instala na input view do teclado.
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: Self.keyboardHeight)
        heightConstraint.priority = UILayoutPriority(999)
        heightConstraint.isActive = true
    }

    private func setupKeyboardLayoutView() {
        keyboardLayoutView.delegate = self
        keyboardLayoutView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardLayoutView)
        NSLayoutConstraint.activate([
            keyboardLayoutView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardLayoutView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardLayoutView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardLayoutView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmojiKeyboardView() {
        emojiKeyboardView.delegate = self
        emojiKeyboardView.translatesAutoresizingMaskIntoConstraints = false
        emojiKeyboardView.isHidden = true
        view.addSubview(emojiKeyboardView)
        NSLayoutConstraint.activate([
            emojiKeyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            emojiKeyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emojiKeyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emojiKeyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupFullAccessBanner() {
        fullAccessBanner.translatesAutoresizingMaskIntoConstraints = false
        fullAccessBanner.isHidden = true
        view.addSubview(fullAccessBanner)
        NSLayoutConstraint.activate([
            fullAccessBanner.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            fullAccessBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            fullAccessBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6)
        ])
    }

    /// A tecla de globo é recriada a cada rebuild() do KeyboardLayoutView (troca de modo),
    /// então religamos o alvo toda vez que uma nova instância é criada.
    private func wireNextKeyboardButton() {
        keyboardLayoutView.onNextKeyboardButtonCreated = { [weak self] button in
            guard let self else { return }
            button.addTarget(self, action: #selector(self.handleInputModeList(from:with:)), for: .allTouchEvents)
        }
    }

    private func updateFullAccessBanner() {
        fullAccessBanner.isHidden = hasFullAccess
    }

    private func applyTheme() {
        // Reavaliado a cada aparição: o usuário pode ter trocado o tema nos Ajustes
        // do app entre um uso do teclado e outro.
        let preference = ThemePreference.loadFromAppGroup()
        view.overrideUserInterfaceStyle = preference.userInterfaceStyle
    }

    // MARK: - Alternância letras / emoji

    private func showEmojiKeyboard() {
        emojiKeyboardView.isHidden = false
        keyboardLayoutView.isHidden = true
    }

    private func showLetterKeyboard() {
        emojiKeyboardView.isHidden = true
        keyboardLayoutView.isHidden = false
    }

    // MARK: - Popup de histórico

    private func showHistoryPopup() {
        guard historyPopupView == nil else { return }
        let popup = HistoryPopupView()
        popup.delegate = self
        popup.translatesAutoresizingMaskIntoConstraints = false
        popup.update(items: store.items)
        view.addSubview(popup)
        NSLayoutConstraint.activate([
            popup.topAnchor.constraint(equalTo: view.topAnchor, constant: 4),
            popup.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            popup.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            popup.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -4)
        ])
        historyPopupView = popup
    }

    private func hideHistoryPopup() {
        historyPopupView?.removeFromSuperview()
        historyPopupView = nil
    }
}

// MARK: - KeyboardLayoutViewDelegate

extension KeyboardViewController: KeyboardLayoutViewDelegate {
    func keyboardLayoutView(_ view: KeyboardLayoutView, didInsertCharacter character: String) {
        textDocumentProxy.insertText(character)
    }

    func keyboardLayoutViewDidRequestBackspace(_ view: KeyboardLayoutView) {
        textDocumentProxy.deleteBackward()
    }

    func keyboardLayoutViewDidRequestSpace(_ view: KeyboardLayoutView) {
        textDocumentProxy.insertText(" ")
    }

    func keyboardLayoutViewDidRequestNewline(_ view: KeyboardLayoutView) {
        textDocumentProxy.insertText("\n")
    }

    func keyboardLayoutViewDidRequestEmojiMode(_ view: KeyboardLayoutView) {
        showEmojiKeyboard()
    }

    func keyboardLayoutViewDidLongPressShift(_ view: KeyboardLayoutView) {
        showHistoryPopup()
    }

    func keyboardLayoutViewDidRegisterKeyPress(_ view: KeyboardLayoutView) {
        store.checkPasteboardForChanges(hasFullAccess: hasFullAccess)
    }
}

// MARK: - EmojiKeyboardViewDelegate

extension KeyboardViewController: EmojiKeyboardViewDelegate {
    func emojiKeyboardView(_ view: EmojiKeyboardView, didSelectEmoji emoji: String) {
        store.checkPasteboardForChanges(hasFullAccess: hasFullAccess)
        textDocumentProxy.insertText(emoji)
    }

    func emojiKeyboardViewDidRequestBackspace(_ view: EmojiKeyboardView) {
        store.checkPasteboardForChanges(hasFullAccess: hasFullAccess)
        textDocumentProxy.deleteBackward()
    }

    func emojiKeyboardViewDidRequestSwitchToLetters(_ view: EmojiKeyboardView) {
        showLetterKeyboard()
    }
}

// MARK: - HistoryPopupViewDelegate

extension KeyboardViewController: HistoryPopupViewDelegate {
    func historyPopupView(_ view: HistoryPopupView, didSelectItem item: ClipItem) {
        textDocumentProxy.insertText(item.text)
        hideHistoryPopup()
    }

    func historyPopupViewDidRequestClose(_ view: HistoryPopupView) {
        hideHistoryPopup()
    }
}
