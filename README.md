# LeadSystem - SantiGrill

Aplicativo acadêmico multiplataforma para catálogo, vendas, orçamentos e atendimento da SantiGrill. O mesmo projeto Flutter gera as versões Android e iOS.

## O que já funciona

- início com promoções, categorias e busca;
- catálogo pesquisável e filtrável;
- detalhes, favoritos, cálculo demonstrativo de frete e orçamento;
- carrinho com quantidades, remoção com desfazer e cupom `PRIMEIRACOMPRA`;
- checkout com endereço, pagamento, validação e confirmação;
- histórico e acompanhamento visual de pedidos;
- login, recuperação de senha e cadastro com validação inline;
- central de ajuda e chat demonstrativo;
- painel administrativo com indicadores e ações rápidas;
- API Node.js inicial, preparada para conexão com MongoDB.

Os dados do aplicativo estão em memória nesta primeira versão. Assim, todos os fluxos podem ser demonstrados mesmo sem internet ou banco configurado.

## Estrutura

```text
LeadSystem/
├── android/                 Projeto nativo Android
├── ios/                     Projeto nativo iOS
├── assets/images/           Imagens do catálogo
├── lib/
│   ├── core/                Tema e estado da aplicação
│   ├── models/              Modelos e catálogo demonstrativo
│   ├── screens/             Telas e fluxos
│   ├── widgets/             Componentes reutilizáveis
│   └── main.dart            Inicialização do app
├── server/                  API Node.js e configuração MongoDB
├── docs/                    Arquitetura e roteiro de apresentação
└── test/                    Testes Flutter
```

## Abrir no VS Code

Abra esta pasta como projeto no VS Code. Instale as extensões recomendadas de Dart e Flutter quando o editor solicitar.

O SDK usado nesta máquina está em:

```text
C:\Users\leand\Documents\Codex\tools\flutter
```

Se necessário, configure esse caminho em `Flutter: Change SDK` na paleta de comandos do VS Code.

## Executar no Android

Com um emulador aberto ou celular conectado:

```powershell
C:\Users\leand\Documents\Codex\tools\flutter\bin\flutter.bat pub get
C:\Users\leand\Documents\Codex\tools\flutter\bin\flutter.bat run
```

Para gerar um APK:

```powershell
C:\Users\leand\Documents\Codex\tools\flutter\bin\flutter.bat build apk --debug
```

## iOS

A pasta `ios` já faz parte do mesmo projeto. O código Dart e as funcionalidades são compartilhados. A compilação e a assinatura de uma versão iOS exigem um computador macOS com Xcode.

## API e MongoDB

Entre em `server`, copie `.env.example` para `.env`, ajuste `MONGODB_URI` e execute:

```powershell
npm install
npm run dev
```

Sem `MONGODB_URI`, a API pode operar com as respostas demonstrativas definidas em `server/src/server.js`.

## Vídeo da primeira entrega

O roteiro de até 15 minutos está em `docs/ROTEIRO_VIDEO.md`. Ele cobre o fluxo do cliente, o painel administrativo, a arquitetura e o estado atual da conexão com o banco.
