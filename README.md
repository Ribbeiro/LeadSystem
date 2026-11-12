# LeadSystem - SantiGrill

Aplicativo acadêmico multiplataforma para catálogo, vendas, orçamentos e atendimento da SantiGrill. O mesmo projeto Flutter gera as versões Android e iOS.

## Conteúdo oficial

Produtos, preços, fotos, contatos e políticas foram extraídos de https://www.santigrill.com.br/ e ficam em `assets/data/santigrill.json` (resumo em `docs/MAPEAMENTO_SITE.md`). O app lê esse arquivo na inicialização; para atualizar o catálogo, basta substituir o JSON e as imagens em `assets/images/products/`.

Documentos: `docs/RELATORIO_QA.md` (bugs, testes e pendências), `docs/ROTEIRO_APRESENTACAO.md` (roteiro de 3 minutos) e `docs/screenshots/`.

## O que já funciona

- início com promoções, categorias e busca;
- catálogo pesquisável e filtrável;
- detalhes, favoritos, cálculo validado de frete e orçamentos persistentes;
- carrinho com quantidades, remoção com desfazer e cupom `PRIMEIRACOMPRA`;
- checkout com endereço, pagamento, validação e confirmação;
- histórico e acompanhamento visual de pedidos;
- login, recuperação de senha e cadastro com validação inline;
- central de ajuda pesquisável, abertura de chamado e respostas automáticas locais;
- perfil com endereços, notificações, dados pessoais e alteração de senha;
- painel administrativo com CRUD de produtos, estoque, categorias, cupons e campanhas, além da gestão de pedidos, usuários e orçamentos;
- API Node.js + MongoDB com autenticação JWT, pedidos, orçamentos, fotos, recuperação de senha por e-mail e frete;
- sincronização offline first, notificações, envio ao WhatsApp e modo escuro.

Os dados ficam salvos no aparelho com `shared_preferences` (o app funciona offline). Com a API configurada, as alterações entram numa fila e são sincronizadas com o MongoDB quando há conexão.

## Estrutura

```text
LeadSystem/
├── android/                 Projeto nativo Android
├── ios/                     Projeto nativo iOS
├── assets/images/           Imagens do catálogo
├── lib/
│   ├── core/                Tema e estado da aplicação
│   ├── models/              Modelos de domínio e catálogo persistente
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

## API e MongoDB (sincronização entre aparelhos)

O app funciona sozinho no aparelho (modo offline). Conectado à API da pasta `server/`, os pedidos do cliente chegam ao painel do admin, as mudanças de status viram notificação, a senha é recuperada por código enviado por e-mail e as fotos de produtos ficam no servidor.

1. Suba o MongoDB (Docker Desktop aberto):

   ```powershell
   cd server
   docker compose up -d
   ```

   Sem Docker, use um MongoDB Atlas gratuito e coloque a URL em `MONGODB_URI`.

2. Configure e inicie a API:

   ```powershell
   copy .env.example .env
   npm install
   npm run dev
   ```

   Na primeira execução, o banco recebe os 24 produtos de `assets/data/santigrill.json`, o cupom de demonstração e as contas `leandro@email.com` (admin) e `carlos@email.com` (cliente).

3. Conecte o app: **Perfil › Servidor e sincronização**, informe `http://10.0.2.2:3000` no emulador Android ou `http://IP-DO-COMPUTADOR:3000` no celular (mesma rede Wi-Fi). Também é possível compilar já apontando para a API:

   ```powershell
   flutter run --dart-define=API_URL=http://10.0.2.2:3000
   ```

Configurações opcionais no `.env`:

- **E-mail (SMTP_*)**: envia o código de recuperação de senha e os avisos de pedido. Sem SMTP, as mensagens aparecem no console da API.
- **Correios (CORREIOS_*)**: cotação oficial de frete. Exige contrato com os Correios; sem ele, o app mostra a estimativa por região, sinalizada como "estimativa".

Testes da API (MongoDB em memória, não precisa de Docker): `npm test`.
Teste de ponta a ponta app + API: `node scripts/e2e-server.js 3999` e, em outro terminal, `E2E_API_URL=http://127.0.0.1:3999 flutter test test/e2e_api_test.dart`.

## Vídeo da primeira entrega

O roteiro de até 15 minutos está em `docs/ROTEIRO_VIDEO.md`. Ele cobre o fluxo do cliente, o painel administrativo, a arquitetura e o estado atual da conexão com o banco.
