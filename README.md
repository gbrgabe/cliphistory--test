# ClipHistory

App pessoal de iOS: um teclado customizado (QWERTY pt-BR, sem autocorreção) que
guarda um histórico do que você copia e deixa recuperar textos antigos com um
long-press na tecla Shift — sem abrir outro app. Inclui um app principal para
gerenciar esse histórico (filtros, busca, fixar, apagar) e configurar o tema.

Feito para uso pessoal, sem distribuição pela App Store. Ver `PROMPT_CLAUDE_CODE.md`
para o spec completo do projeto.

## Estrutura

- `App/` — app principal em SwiftUI (`ClipHistory`).
- `KeyboardExtension/` — teclado customizado em UIKit (`ClipHistoryKeyboard`).
- `Shared/` — modelos e `ClipboardStore`, compartilhados pelos dois targets via App Group.
- `project.yml` — definição do projeto para o [XcodeGen](https://github.com/yonaskolb/XcodeGen).

Não há `.xcodeproj` commitado — ele é gerado a partir do `project.yml`.

## Build local (se um dia tiver um Mac)

1. Instale o XcodeGen: `brew install xcodegen`
2. Na raiz do repositório, rode: `xcodegen generate`
3. Abra `ClipHistory.xcodeproj` no Xcode.
4. Selecione o scheme `ClipHistory` e rode num dispositivo físico (a extensão
   de teclado não funciona bem no simulador para testar digitação em outros apps).
5. Nos dois targets (`ClipHistory` e `ClipHistoryKeyboard`), confirme em
   *Signing & Capabilities* que o App Group `group.com.mae.cliphistory` está
   habilitado com uma conta de desenvolvedor sua (o identificador pode
   precisar ser ajustado se `com.mae.cliphistory` já estiver em uso por outra
   conta — ajuste em `project.yml` e nos dois arquivos `.entitlements`).

## Instalação sem Mac (via GitHub Actions + AltStore/SideStore)

Este repositório tem um workflow (`.github/workflows/build-unsigned-ipa.yml`)
que compila um `.ipa` **não assinado** num runner macOS gratuito do GitHub
Actions, a cada push na branch `main` (ou disparo manual pela aba Actions).

Para baixar o `.ipa` mais recente:

1. Vá na aba **Actions** deste repositório no GitHub.
2. Abra a execução (run) mais recente do workflow "Build unsigned IPA".
3. Baixe o artifact **ipa-nao-assinado** — ele contém `ClipHistory-unsigned.ipa`.
4. Instale esse `.ipa` no iPhone via **AltServer** (Windows/Mac) e depois
   configure o **SideStore** para renovação automática a cada 7 dias.
5. Depois de instalado: vá em **Ajustes → Teclado → Teclados → Adicionar Novo
   Teclado** e escolha ClipHistory. Ative **Acesso Total** — sem isso a leitura
   do clipboard não funciona (é uma exigência do próprio iOS).

## Limitações conhecidas

- Sem QuickType/autocorreção — fora de escopo por decisão explícita.
- O histórico só captura o que estava no clipboard nos momentos em que o
  teclado esteve aberto (não existe clipboard "histórico" nativo do iOS).
- Teclados de terceiros não funcionam em campos de senha — o iOS força o
  teclado padrão nesses casos automaticamente.
- Sem ícone de app definido (`AppIcon.appiconset` está vazio) — pode ser
  preenchido depois numa Mac.
