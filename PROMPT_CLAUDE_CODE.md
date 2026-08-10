# Prompt para Claude Code — App "ClipHistory" (teclado + histórico de clipboard, iOS)

Contexto: sou o único usuário. É um app pessoal para meu iPhone, não vai pra App Store.
Não precisa de arquitetura escalável, testes extensivos, nem polimento de produto —
precisa ser **bonito visualmente** e **funcional**. Priorize simplicidade e código
que eu consiga entender/ajustar depois.

## O que o app faz

Um teclado customizado que substitui o teclado padrão do iOS no dia a dia. Ele
funciona normalmente como qualquer teclado (digitação normal), mas guarda um
histórico de tudo que copio (clipboard) e permite recuperar textos antigos com
um gesto rápido, sem precisar abrir outro app.

## Arquitetura (Xcode, 2 targets + código compartilhado)

1. **App principal** (`ClipHistory`) — SwiftUI. Tela de histórico com filtros,
   favoritos, apagar itens, configurações (tema), onboarding simples explicando
   como ativar o teclado.
2. **Keyboard Extension** (`ClipHistoryKeyboard`) — teclado QWERTY completo em
   pt-BR, feito do zero com UIKit (`UIInputViewController`).
3. **Shared** (código compartilhado entre os dois targets, sem target próprio,
   arquivos incluídos nos dois): modelos de dados e o `ClipboardStore` que lê/escreve
   o histórico.

Use **App Groups** para os dois targets compartilharem dados
(`group.com.SEUBUNDLE.cliphistory` — ajuste o identificador conforme o bundle ID
que você configurar). Persistência: arquivo JSON dentro do container do App Group
(não precisa de Core Data/SQLite para esse volume de dados).

Se tiver disponível, use **XcodeGen** (`project.yml`) para gerar o `.xcodeproj`
via linha de comando em vez de montar o projeto manualmente pela GUI do Xcode —
isso evita erros de configuração de targets/capabilities feitos à mão. Se XcodeGen
não estiver disponível no ambiente, documente os passos manuais necessários no
Xcode (adicionar target de Keyboard Extension, ativar App Groups nos dois targets
com o mesmo identificador, ativar "Full Access" como capability necessária pelo
usuário depois, nas Configurações do iOS).

## Teclado (Keyboard Extension) — requisitos

- **QWERTY completo em pt-BR**, com todos os estados: minúsculas, maiúsculas
  (shift), números, símbolos. Deve funcionar como teclado principal do dia a dia
  (não é uma barra de atalhos — é um teclado de verdade, porque será configurado
  como primeiro da lista em Ajustes → Teclado).
- **Sem autocorreção/sugestão de palavras (sem QuickType bar)** — está fora de
  escopo por decisão explícita (o motor de previsão da Apple é privado e não dá
  pra replicar fielmente; não vale o esforço de uma versão simplificada agora).
- Incluir **emojis** (pelo menos um teclado de emoji acessível, pode ser via
  botão dedicado ou troca de modo, como o padrão da Apple faz).
- Visual o mais próximo possível do teclado nativo da Apple (proporções, cores,
  espaçamento, feedback de toque) — sem tentar clonar pixel a pixel, mas deve
  "parecer" o teclado do sistema.
- **Botão de globo obrigatório** (`handleInputModeList(from:with:)`) para trocar
  de teclado — é exigência da Apple para teclados de terceiros.
- **Long-press na tecla Shift** abre o popup de histórico (view customizada
  dentro da própria extensão, cobrindo o teclado). Toque normal na Shift continua
  com o comportamento padrão (alternar maiúscula/minúscula/caps lock em duplo
  toque).
- **Captura de clipboard**: chamar a checagem de `UIPasteboard.general.changeCount`
  em `viewWillAppear` (a cada vez que o teclado aparece) e também a cada toque de
  tecla, comparando com o último `changeCount` salvo no App Group — se mudou, lê
  `UIPasteboard.general.string` e adiciona ao histórico (evitar duplicar se o
  texto for igual ao item mais recente já salvo).
- **Full Access obrigatório**: sem isso a extensão não lê o pasteboard. Verificar
  `self.hasFullAccess` e, se falso, mostrar um banner dentro do próprio teclado
  (extensões de teclado **não podem** apresentar `UIAlertController` — é uma
  limitação do iOS, não esquecer disso).
- Manter um **limite de itens não-fixados** no histórico (ex: 200) para não
  estourar o limite de memória da extensão (extensões de teclado têm teto de
  memória bem mais apertado que apps normais, algo em torno de 30-60MB antes do
  iOS matar o processo — evite guardar textos gigantes sem truncar, e evite
  manter tudo em memória de uma vez sem necessidade).
- Popup de histórico dentro do teclado: lista simples, mostrar preview de texto
  (algumas linhas, truncado), toque insere o texto via
  `textDocumentProxy.insertText(...)`, deve ter botão de fechar.

## App principal — requisitos

- **Tela de histórico**: lista de todos os itens copiados, mais recentes primeiro.
  Cada item mostra preview do texto e data/hora.
- **Filtros por período**: Hoje / Esta semana / Este mês / Tudo (segmented control
  ou similar).
- **Favoritar/fixar** itens — itens fixados aparecem destacados/separados no topo
  e **não contam para o limite de itens que pode ser apagado automaticamente**
  (ou seja: se algum dia implementar limpeza automática por limite de itens, os
  fixados são poupados).
- **Apagar itens** individualmente (swipe to delete) e opção de "limpar histórico"
  (mantendo fixados, com confirmação).
- **Busca** simples por texto dentro do histórico (nice to have, mas fácil de
  incluir já que os dados já estão em memória).
- **Configurações**: alternância de tema Claro / Escuro / Sistema (persistir a
  escolha, aplicar tanto no app quanto — na medida do possível — no teclado,
  considerando que teclados de terceiros normalmente seguem
  `UITraitCollection.userInterfaceStyle` do sistema; se o usuário escolher um
  tema fixo diferente do sistema, aplicar isso manualmente nas views tanto do
  app quanto do teclado usando o valor salvo no App Group).
- **Onboarding simples** (1-2 telas): explicar que precisa (1) adicionar o
  teclado em Ajustes → Teclado → Teclados, (2) ativar "Acesso Total" (Full
  Access), (3) opcionalmente arrastar para primeiro da lista se quiser que
  substitua o teclado padrão. Incluir botão com deep link
  `UIApplication.openSettingsURLString` para abrir os Ajustes do app diretamente
  (não existe deep link direto para a tela de Teclados — é limitação do iOS).

## Modelo de dados (referência)

```swift
struct ClipItem: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let createdAt: Date
    var isPinned: Bool = false
}
```

Persistência: array de `ClipItem` serializado em JSON, salvo em arquivo dentro de
`FileManager.default.containerURL(forSecurityApplicationGroupIdentifier:)`.
Leitura/escrita centralizadas numa classe única (`ClipboardStore`) usada pelos
dois targets, para não duplicar lógica de I/O.

## Estilo visual

- SwiftUI para o app principal, seguindo boas práticas de UI nativa iOS (não
  precisa reinventar padrões de navegação — usar `NavigationStack`, listas
  nativas, etc).
- Cuidado especial no visual do teclado (UIKit) para não parecer "quadrado
  demais" — usar cantos arredondados nas teclas, sombra sutil, espaçamento
  parecido com o teclado nativo da Apple.
- Suporte a Dark Mode em tudo (cores via Asset Catalog ou `Color` dinâmicas do
  SwiftUI / `UIColor` semânticas no UIKit, não cores fixas hardcoded).

## Limitações técnicas conhecidas (não tentar contornar, são do iOS)

- Não existe clipboard "histórico" nativo do iOS — só captura o que estava no
  pasteboard nos momentos em que o teclado é aberto. Texto copiado e nunca
  colado/nunca com o teclado aberto depois não é capturado — isso é esperado e
  não é bug.
- Teclados de terceiros não funcionam em campos de senha (`isSecureTextEntry`),
  o iOS força o teclado padrão nesses casos — não precisa tratar esse caso, é
  automático pelo sistema.
- Sem background execution: toda captura depende de o teclado estar em foco.

## Ordem sugerida de implementação

1. Estrutura do projeto (App + Keyboard Extension targets + App Group configurado)
2. `ClipItem` + `ClipboardStore` compartilhados
3. Teclado QWERTY funcional básico (sem histórico ainda) — validar que digita
   normalmente em qualquer app
4. Lógica de captura de clipboard (`viewWillAppear` + toques) e popup de
   histórico com long-press na Shift
5. App principal: lista + filtros + fixar + apagar
6. Configurações (tema) + onboarding
7. Polimento visual final
8. Configurar CI/CD (ver seção abaixo)

## Distribuição (sem Mac, 100% grátis, sem App Store)

Não tenho Mac. O plano de instalação é:

1. Repositório GitHub **público** (necessário para minutos ilimitados de runner
   macOS gratuito no GitHub Actions)
2. Um workflow do GitHub Actions (já teremos o `.yml` pronto — ver abaixo) que
   compila o projeto num runner macOS temporário, **sem assinatura de código**
   (`CODE_SIGNING_ALLOWED=NO`), e empacota um `.ipa` não assinado como artifact
   do workflow
3. Esse `.ipa` é baixado manualmente e assinado/instalado no iPhone via
   **AltServer** (Windows) — depois, via **SideStore**, que se renova sozinho a
   cada 7 dias sem depender de nenhum computador

**O que preciso que você (Claude Code) configure no projeto para isso funcionar:**

- Já uso os arquivos prontos abaixo, que devem ir na raiz do repositório
  exatamente nesses caminhos:
  - `.gitignore` (bloqueia certificados, perfis de provisionamento, `.env`, etc.
    — nunca deve haver segredo/credencial commitado)
  - `.github/workflows/build-unsigned-ipa.yml` (faz o build sem assinatura a
    cada push na branch `main`, ou disparo manual)
- No `.yml`, as variáveis `PROJECT_NAME` e `SCHEME_NAME` no topo do arquivo
  devem ser ajustadas para bater exatamente com o nome do `.xcodeproj` e do
  scheme que você criar — não deixe esses valores desalinhados, ou o build
  falha silenciosamente
- Certifique-se de que o **scheme está marcado como "Shared"** no Xcode
  (Product → Scheme → Manage Schemes → marcar "Shared"), senão o
  `xcodebuild` do runner não enxerga o scheme (schemes não compartilhados não
  vão pro Git por padrão)
- Não é necessário (e não deve ser feito) configurar nenhum certificado,
  provisioning profile, App Store Connect API key ou Apple ID dentro do
  workflow — a assinatura acontece depois, localmente, via AltServer/SideStore,
  fora do CI
- Adicionar um `README.md` simples explicando: como buildar localmente (se um
  dia eu tiver acesso a um Mac), e o link/instrução de onde baixar o `.ipa`
  gerado pelo Actions (aba Actions → run mais recente → Artifacts)
