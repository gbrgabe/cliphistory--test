import UIKit

/// Banner exibido dentro do próprio teclado quando o Full Access está desativado.
/// Extensões de teclado não podem apresentar UIAlertController — este banner substitui isso.
final class FullAccessBannerView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        backgroundColor = .systemYellow.withAlphaComponent(0.25)
        layer.cornerRadius = 8

        let label = UILabel()
        label.text = "Ative \"Acesso Total\" em Ajustes → Teclado → Teclados para usar o histórico de clipboard."
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
    }
}
