import SwiftUI

struct OnboardingView: View {
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "keyboard")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            Text("Bem-vindo ao ClipHistory")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 16) {
                step(number: 1, text: "Vá em Ajustes → Teclado → Teclados → Adicionar Novo Teclado e escolha ClipHistory.")
                step(number: 2, text: "Toque no ClipHistory na lista e ative \"Acesso Total\" (necessário para o histórico de clipboard funcionar).")
                step(number: 3, text: "Opcional: arraste o ClipHistory para o topo da lista se quiser que ele seja o teclado padrão.")
            }
            .padding(.horizontal)

            Spacer()

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Abrir Ajustes do iOS")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            Button("Já configurei, continuar") {
                onFinish()
            }
            .padding(.bottom, 24)
        }
    }

    private func step(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.accentColor))
            Text(text)
                .font(.body)
        }
    }
}
