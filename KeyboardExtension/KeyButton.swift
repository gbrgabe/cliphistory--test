import UIKit

/// Botão de uma tecla do teclado. Cuida sozinho da aparência (cantos
/// arredondados, sombra sutil, feedback de toque) e, quando a tecla tem
/// variantes de acento, do popup de long-press que aparece por cima dela.
final class KeyButton: UIButton {
    let keyDefinition: KeyDefinition

    /// View ancestral onde o popup de variantes deve ser inserido, para não
    /// ficar cortado pelos limites da UIStackView da própria linha.
    weak var overlayContainer: UIView?

    /// Chamado quando o usuário solta o dedo: com o caractere base (tap normal)
    /// ou com a variante selecionada (long-press + arrasto).
    var onCharacterResolved: ((String) -> Void)?

    private var variantsPopup: KeyVariantsPopup?

    init(keyDefinition: KeyDefinition) {
        self.keyDefinition = keyDefinition
        super.init(frame: .zero)
        configureAppearance()
        setupLongPressIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureAppearance() {
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 5
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowRadius = 0
        layer.masksToBounds = false

        setTitle(keyDefinition.displayText, for: .normal)
        titleLabel?.font = .systemFont(ofSize: keyDefinition.isFunctionKey ? 15 : 22)
        titleLabel?.adjustsFontSizeToFitWidth = true
        setTitleColor(.label, for: .normal)

        updateBackgroundColor(highlighted: false)

        addTarget(self, action: #selector(handleTouchDown), for: .touchDown)
        addTarget(self, action: #selector(handleTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
    }

    private func updateBackgroundColor(highlighted: Bool) {
        let base: UIColor = keyDefinition.isFunctionKey ? .systemGray3 : .secondarySystemBackground
        backgroundColor = highlighted ? base.withAlphaComponent(0.5) : base
    }

    @objc private func handleTouchDown() {
        updateBackgroundColor(highlighted: true)
    }

    @objc private func handleTouchUp() {
        updateBackgroundColor(highlighted: false)
    }

    /// Atualiza o estado visual (ex.: shift ativo) sem recriar o botão.
    func setHighlightedState(_ active: Bool) {
        backgroundColor = active ? UIColor.label.withAlphaComponent(0.25) : (keyDefinition.isFunctionKey ? .systemGray3 : .secondarySystemBackground)
    }

    func updateDisplayText(_ text: String) {
        setTitle(text, for: .normal)
    }

    // MARK: - Long-press para variantes de acento

    private func setupLongPressIfNeeded() {
        guard !keyDefinition.longPressVariants.isEmpty else { return }
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        recognizer.minimumPressDuration = 0.35
        addGestureRecognizer(recognizer)
    }

    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        guard let overlayContainer else { return }
        switch recognizer.state {
        case .began:
            // Evita que o touchUpInside padrão do UIButton dispare também.
            cancelTracking(with: nil)
            updateBackgroundColor(highlighted: false)
            let popup = KeyVariantsPopup(variants: keyDefinition.longPressVariants)
            overlayContainer.addSubview(popup)
            popup.position(above: self, in: overlayContainer)
            variantsPopup = popup
        case .changed:
            variantsPopup?.updateHighlight(atLocationInContainer: recognizer.location(in: overlayContainer))
        case .ended:
            let selected = variantsPopup?.highlightedVariant ?? keyDefinition.displayText
            variantsPopup?.removeFromSuperview()
            variantsPopup = nil
            onCharacterResolved?(selected)
        case .cancelled, .failed:
            variantsPopup?.removeFromSuperview()
            variantsPopup = nil
        default:
            break
        }
    }
}

/// Popup de variantes de acento (ex.: long-press em "a" mostra á à â ã).
private final class KeyVariantsPopup: UIView {
    private let variants: [String]
    private var labels: [UILabel] = []
    private(set) var highlightedVariant: String?

    private static let labelWidth: CGFloat = 38
    private static let height: CGFloat = 44

    init(variants: [String]) {
        self.variants = variants
        super.init(frame: .zero)

        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4)
        ])

        for variant in variants {
            let label = UILabel()
            label.text = variant
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 22)
            label.textColor = .label
            label.layer.cornerRadius = 4
            label.clipsToBounds = true
            stack.addArrangedSubview(label)
            labels.append(label)
        }

        highlightedVariant = variants.first
        labels.first?.backgroundColor = .systemGray3
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func position(above anchor: UIView, in container: UIView) {
        let width = CGFloat(variants.count) * Self.labelWidth + 8
        let anchorFrame = anchor.convert(anchor.bounds, to: container)
        let x = min(max(0, anchorFrame.midX - width / 2), container.bounds.width - width)
        let y = anchorFrame.minY - Self.height - 6
        frame = CGRect(x: x, y: max(0, y), width: width, height: Self.height)
    }

    func updateHighlight(atLocationInContainer location: CGPoint) {
        guard bounds.width > 0 else { return }
        let localPoint = convert(location, from: superview)
        let clampedX = max(0, min(bounds.width - 1, localPoint.x))
        let index = Int(clampedX / (bounds.width / CGFloat(variants.count)))
        let clampedIndex = max(0, min(variants.count - 1, index))
        highlightedVariant = variants[clampedIndex]
        for (i, label) in labels.enumerated() {
            label.backgroundColor = i == clampedIndex ? .systemGray3 : .clear
        }
    }
}
