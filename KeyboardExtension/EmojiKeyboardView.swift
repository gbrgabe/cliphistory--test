import UIKit

protocol EmojiKeyboardViewDelegate: AnyObject {
    func emojiKeyboardView(_ view: EmojiKeyboardView, didSelectEmoji emoji: String)
    func emojiKeyboardViewDidRequestBackspace(_ view: EmojiKeyboardView)
    func emojiKeyboardViewDidRequestSwitchToLetters(_ view: EmojiKeyboardView)
}

/// Grade simples e fixa de emojis comuns, sem categorias — troca de modo via botão "ABC".
final class EmojiKeyboardView: UIView {
    weak var delegate: EmojiKeyboardViewDelegate?

    private static let emojis: [String] = [
        // Rostos
        "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😊", "😇",
        "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😋", "😛", "🤪",
        "🤗", "🤔", "😐", "😑", "🙄", "😴", "😷", "🤒", "🥵", "🥶",
        "😳", "🥺", "😢", "😭", "😡", "😠", "😱", "🤯", "🥳", "😎",
        // Gestos
        "👍", "👎", "👏", "🙌", "🙏", "💪", "👌", "✌️", "🤞", "🤝",
        "👋", "🤙", "👊", "✊", "👉", "👈", "☝️", "✋", "🖐️", "🤘",
        // Corações
        "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🤍", "💔", "💯",
        // Objetos do dia a dia
        "🔥", "✨", "🎉", "🎂", "🎁", "☕", "🍕", "🍔", "🍺", "🍷",
        "⚽", "🎵", "📱", "💻", "⏰", "🌟", "🌧️", "☀️"
    ]

    private let scrollView = UIScrollView()
    private let gridStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        buildGrid()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        backgroundColor = .clear

        let abcButton = makeTopBarButton(title: "ABC")
        abcButton.addTarget(self, action: #selector(handleABCTap), for: .touchUpInside)

        let backspaceButton = makeTopBarButton(title: "⌫")
        backspaceButton.addTarget(self, action: #selector(handleBackspaceTap), for: .touchUpInside)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        gridStack.axis = .vertical
        gridStack.spacing = 6
        gridStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(abcButton)
        addSubview(backspaceButton)
        addSubview(scrollView)
        scrollView.addSubview(gridStack)

        NSLayoutConstraint.activate([
            abcButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            abcButton.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            abcButton.widthAnchor.constraint(equalToConstant: 50),
            abcButton.heightAnchor.constraint(equalToConstant: 32),

            backspaceButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            backspaceButton.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            backspaceButton.widthAnchor.constraint(equalToConstant: 50),
            backspaceButton.heightAnchor.constraint(equalToConstant: 32),

            scrollView.topAnchor.constraint(equalTo: abcButton.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            gridStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            gridStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            gridStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            gridStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            gridStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func makeTopBarButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.setTitleColor(.label, for: .normal)
        button.backgroundColor = .systemGray3
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func buildGrid() {
        let columns = 8
        var index = 0
        while index < Self.emojis.count {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 4

            for _ in 0..<columns {
                guard index < Self.emojis.count else { break }
                let emoji = Self.emojis[index]
                let button = UIButton(type: .system)
                button.setTitle(emoji, for: .normal)
                button.titleLabel?.font = .systemFont(ofSize: 26)
                button.heightAnchor.constraint(equalToConstant: 38).isActive = true
                button.addTarget(self, action: #selector(handleEmojiTap(_:)), for: .touchUpInside)
                rowStack.addArrangedSubview(button)
                index += 1
            }
            gridStack.addArrangedSubview(rowStack)
        }
    }

    @objc private func handleEmojiTap(_ sender: UIButton) {
        guard let emoji = sender.title(for: .normal) else { return }
        delegate?.emojiKeyboardView(self, didSelectEmoji: emoji)
    }

    @objc private func handleBackspaceTap() {
        delegate?.emojiKeyboardViewDidRequestBackspace(self)
    }

    @objc private func handleABCTap() {
        delegate?.emojiKeyboardViewDidRequestSwitchToLetters(self)
    }
}
