import Foundation
import UIKit

/// Único ponto de leitura/escrita do histórico de clipboard, usado tanto pelo
/// app principal quanto pela keyboard extension.
final class ClipboardStore: ObservableObject {
    static let shared = ClipboardStore()

    /// Limite de itens NÃO fixados guardados (itens fixados nunca são removidos por este limite).
    static let maxNonPinnedItems = 200

    /// Trunca textos muito grandes para não estourar o teto de memória da keyboard extension.
    static let maxTextLength = 5000

    @Published private(set) var items: [ClipItem] = []

    private let fileURL: URL?

    private init() {
        fileURL = AppGroupConstants.containerURL?.appendingPathComponent(AppGroupConstants.historyFileName)
        load()
    }

    // MARK: - Load / Save

    func load() {
        guard let fileURL, let data = try? Data(contentsOf: fileURL) else {
            items = []
            return
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([ClipItem].self, from: data) {
            items = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }

    private func save() {
        // fileURL pode ser nil se o App Group ainda não estiver corretamente
        // provisionado (ex: build não assinado antes de passar pelo AltServer).
        // Nesse caso o store continua funcionando só em memória, sem persistir.
        guard let fileURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(items) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Mutations

    @discardableResult
    func addIfNeeded(text: String) -> Bool {
        let trimmed = String(text.prefix(Self.maxTextLength))
        guard !trimmed.isEmpty else { return false }
        if let mostRecent = items.first, mostRecent.text == trimmed {
            return false
        }
        items.insert(ClipItem(text: trimmed), at: 0)
        enforceNonPinnedLimit()
        save()
        return true
    }

    func togglePin(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isPinned.toggle()
        save()
    }

    func delete(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func delete(ids: [UUID]) {
        let idSet = Set(ids)
        items.removeAll { idSet.contains($0.id) }
        save()
    }

    /// Apaga o histórico. Se `keepPinned` for true (padrão), itens fixados são preservados.
    func clearHistory(keepPinned: Bool = true) {
        if keepPinned {
            items.removeAll { !$0.isPinned }
        } else {
            items.removeAll()
        }
        save()
    }

    private func enforceNonPinnedLimit() {
        let pinned = items.filter { $0.isPinned }
        let nonPinned = items.filter { !$0.isPinned }
        guard nonPinned.count > Self.maxNonPinnedItems else { return }
        let trimmedNonPinned = Array(nonPinned.prefix(Self.maxNonPinnedItems))
        items = (pinned + trimmedNonPinned).sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Captura de clipboard (chamada pela keyboard extension)

    /// Compara o changeCount atual do pasteboard com o último já processado
    /// (guardado no App Group). Só lê o conteúdo do pasteboard quando muda e
    /// quando `hasFullAccess` é true — sem Full Access o iOS não libera o
    /// conteúdo real do pasteboard para a extensão.
    @discardableResult
    func checkPasteboardForChanges(hasFullAccess: Bool) -> Bool {
        guard hasFullAccess else { return false }

        let currentChangeCount = UIPasteboard.general.changeCount
        let lastChangeCount = AppGroupConstants.sharedDefaults?
            .object(forKey: AppGroupConstants.lastPasteboardChangeCountKey) as? Int

        guard currentChangeCount != lastChangeCount else { return false }
        AppGroupConstants.sharedDefaults?.set(currentChangeCount, forKey: AppGroupConstants.lastPasteboardChangeCountKey)

        guard let text = UIPasteboard.general.string, !text.isEmpty else { return false }
        return addIfNeeded(text: text)
    }
}
