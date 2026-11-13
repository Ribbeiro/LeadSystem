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

O app funciona sozinho no aparelho (modo offline). Conectado à API da pasta `server/`, os pedidos do cliente chegam ao painel do admin, as mudanças de status viram notificação (inclusive com o app fechado), a senha é recuperada por código enviado por e-mail e as fotos dos produtos ficam no servidor.

Tudo roda **de graça, sem Docker e sem criar conta em nenhum serviço**.

### Modo demonstração (recomendado para testar e apresentar)

```powershell
cd server
npm install
npm run demo
```

O comando:

- sobe um **MongoDB local** (o binário oficial é baixado na primeira vez, cerca de 70 MB) com os dados salvos em `server/.data`;
- carrega os 24 produtos reais e as contas `leandro@email.com` / `Santi@2026` (admin) e `carlos@email.com` / `Cliente@2026` (cliente);
- envia os e-mails para uma **caixa de teste Ethereal**, gratuita e sem cadastro. O link para abrir o e-mail (com o código de senha) aparece no console e no próprio app;
- mostra os endereços para colar no app em **Perfil › Servidor e sincronização**: `http://10.0.2.2:3000` no emulador ou `http://IP-DO-COMPUTADOR:3000` no celular, na mesma rede Wi-Fi.

**Acesso de qualquer rede, com HTTPS:**

```powershell
npm run demo:tunnel
```

Abre um túnel gratuito da Cloudflare (`https://xxxx.trycloudflare.com`), sem conta. O endereço muda a cada execução e só funciona enquanto o computador estiver ligado, o que basta para a apresentação.

### Notificações com o app fechado

No Android, o app agenda uma verificação em segundo plano (WorkManager) que consulta a API a cada ~15 minutos e avisa sobre mudança de status, ou sobre pedido novo para o admin. Não usa Firebase. O intervalo mínimo do Android é 15 minutos; com o app aberto, a sincronização ocorre a cada 30 segundos.

### Frete

A API tem integração pronta com os Correios, mas a cotação oficial exige contrato pago. Sem ele, o app mostra uma **estimativa** PAC/SEDEX por região, sinalizada na tela. O endereço é preenchido pelo CEP (ViaCEP, gratuito).

### Outras formas de rodar (opcional)

- **MongoDB com Docker**: `docker compose up -d` e depois `npm run dev`, com o `.env` copiado de `.env.example`.
- **E-mail de verdade**: preencha `SMTP_*` no `.env`, por exemplo Gmail com "senha de app".
- **Hospedagem permanente gratuita**: Render (API) e MongoDB Atlas M0 (banco) aceitam este projeto sem alterações, mas exigem que você crie as contas.

### Testes

- API (MongoDB em memória): `npm test`
- Ponta a ponta, app + API: `node scripts/e2e-server.js 3999` e, em outro terminal, `E2E_API_URL=http://127.0.0.1:3999 flutter test test/e2e_api_test.dart`

## Vídeo da primeira entrega

O roteiro de até 15 minutos está em `docs/ROTEIRO_VIDEO.md`. Ele cobre o fluxo do cliente, o painel administrativo, a arquitetura e o estado atual da conexão com o banco.
