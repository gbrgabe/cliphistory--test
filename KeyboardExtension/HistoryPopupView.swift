import UIKit

protocol HistoryPopupViewDelegate: AnyObject {
    func historyPopupView(_ view: HistoryPopupView, didSelectItem item: ClipItem)
    func historyPopupViewDidRequestClose(_ view: HistoryPopupView)
}

/// Overlay que cobre o teclado com a lista de itens copiados. Aberto via long-press no Shift.
final class HistoryPopupView: UIView {
    weak var delegate: HistoryPopupViewDelegate?

    private var items: [ClipItem] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()

    private static let cellReuseId = "ClipItemCell"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 10
        layer.masksToBounds = true

        titleLabel.text = "Histórico"
        titleLabel.font = .boldSystemFont(ofSize: 16)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        closeButton.setTitle("Fechar", for: .normal)
        closeButton.addTarget(self, action: #selector(handleCloseTap), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.separatorStyle = .singleLine

        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(tableView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func update(items: [ClipItem]) {
        // Fixados primeiro; dentro de cada grupo já vêm ordenados por data (mais recente primeiro).
        self.items = items.filter(\.isPinned) + items.filter { !$0.isPinned }
        tableView.reloadData()
    }

    @objc private func handleCloseTap() {
        delegate?.historyPopupViewDidRequestClose(self)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter
    }()
}

extension HistoryPopupView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.isEmpty ? 1 : items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseId)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: Self.cellReuseId)
        cell.backgroundColor = .clear

        guard !items.isEmpty else {
            cell.textLabel?.text = "Nenhum item copiado ainda."
            cell.textLabel?.textColor = .secondaryLabel
            cell.textLabel?.numberOfLines = 0
            cell.detailTextLabel?.text = nil
            cell.selectionStyle = .none
            return cell
        }

        let item = items[indexPath.row]
        cell.textLabel?.numberOfLines = 3
        cell.textLabel?.font = .systemFont(ofSize: 15)
        cell.textLabel?.textColor = .label
        cell.textLabel?.text = (item.isPinned ? "📌 " : "") + item.text
        cell.detailTextLabel?.font = .systemFont(ofSize: 11)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.text = Self.dateFormatter.string(from: item.createdAt)
        cell.selectionStyle = .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < items.count else { return }
        delegate?.historyPopupView(self, didSelectItem: items[indexPath.row])
    }
}
