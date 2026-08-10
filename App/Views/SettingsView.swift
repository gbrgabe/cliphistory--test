import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Form {
            Section("Aparência") {
                Picker("Tema", selection: $themeManager.preference) {
                    ForEach(ThemePreference.allCases, id: \.self) { preference in
                        Text(preference.label).tag(preference)
                    }
                }
                .pickerStyle(.inline)
            }

            Section {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Abrir Ajustes do iOS", systemImage: "gearshape")
                }
            } footer: {
                Text("Use Ajustes → Teclado → Teclados para ativar o ClipHistory e o Acesso Total.")
            }
        }
        .navigationTitle("Configurações")
    }
}
