import SwiftUI

enum HistoryPeriodFilter: String, CaseIterable, Identifiable {
    case today = "Hoje"
    case week = "Esta semana"
    case month = "Este mês"
    case all = "Tudo"

    var id: String { rawValue }
}

struct HistoryListView: View {
    @ObservedObject var store: ClipboardStore
    @State private var periodFilter: HistoryPeriodFilter = .all
    @State private var searchText = ""
    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                if !pinnedItems.isEmpty {
                    Section("Fixados") {
                        ForEach(pinnedItems) { item in
                            row(for: item)
                        }
                    }
                }

                Section(pinnedItems.isEmpty ? "Histórico" : "Outros") {
                    if otherItems.isEmpty && pinnedItems.isEmpty {
                        Text("Nenhum item copiado ainda.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(otherItems) { item in
                            row(for: item)
                        }
                    }
                }
            }
            .navigationTitle("ClipHistory")
            .searchable(text: $searchText, prompt: "Buscar no histórico")
            .safeAreaInset(edge: .top) {
                Picker("Período", selection: $periodFilter) {
                    ForEach(HistoryPeriodFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 4)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(store.items.isEmpty)
                }
            }
            .confirmationDialog(
                "Limpar todo o histórico? Itens fixados são mantidos.",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Limpar histórico", role: .destructive) {
                    store.clearHistory(keepPinned: true)
                }
                Button("Cancelar", role: .cancel) {}
            }
        }
    }

    private func row(for item: ClipItem) -> some View {
        HistoryRowView(item: item)
            .swipeActions(edge: .leading) {
                Button {
                    store.togglePin(id: item.id)
                } label: {
                    Label(item.isPinned ? "Desafixar" : "Fixar", systemImage: item.isPinned ? "pin.slash" : "pin")
                }
                .tint(.orange)
            }
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    store.delete(id: item.id)
                } label: {
                    Label("Apagar", systemImage: "trash")
                }
            }
    }

    private var filteredItems: [ClipItem] {
        let base: [ClipItem]
        switch periodFilter {
        case .today:
            base = store.items.filter { Calendar.current.isDateInToday($0.createdAt) }
        case .week:
            base = store.items.filter { Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .weekOfYear) }
        case .month:
            base = store.items.filter { Calendar.current.isDate($0.createdAt, equalTo: Date(), toGranularity: .month) }
        case .all:
            base = store.items
        }

        guard !searchText.isEmpty else { return base }
        return base.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    private var pinnedItems: [ClipItem] {
        filteredItems.filter(\.isPinned)
    }

    private var otherItems: [ClipItem] {
        filteredItems.filter { !$0.isPinned }
    }
}
