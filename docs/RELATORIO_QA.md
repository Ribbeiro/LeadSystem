# Relatório de correções e QA — LeadSystem SantiGrill

Branch: `fix/crashes-e-catalogo` · Data: 11/11/2026

Resultado final: `flutter analyze` sem nenhum aviso e `flutter test` com 99 testes passando. Antes, eram 8 testes e só a tela inicial era verificada.

## 1. Bugs encontrados e corrigidos

| # | Onde | Sintoma | Causa | Correção |
|---|---|---|---|---|
| 1 | Detalhe do produto | **Crash**: a tela ficava em branco ou vermelha ao abrir um produto | `ListTile` com `trailing` de texto longo nas especificações. O Flutter abortava o layout ("Trailing widget consumes the entire tile width") | As especificações viraram linhas chave/valor flexíveis |
| 2 | Home, Catálogo, Login, Pedidos, Painel admin, Orçamento, Notificações, Formulário de produto, Diálogo de senha, Pedido confirmado | Faixas amarelas e pretas de overflow; conteúdo cortado em celulares pequenos ou com fonte ampliada | `Row`/`Column` com texto de largura fixa, sem `Expanded`/`Flexible`, e telas sem rolagem | `Expanded`/`Flexible`/`Wrap`, `ellipsis` e rolagem. Validado em 320×568 e 430×932 |
| 3 | Pedido confirmado | A previsão de entrega era sempre "12 a 14 de setembro" | Texto fixo no código | Calculada a partir da data do pedido |
| 4 | Card e detalhe do produto | Produto sem estoque aparecia como "Em estoque" e podia ir ao carrinho | Rótulo fixo | Mostra "Esgotado" e desabilita a compra |
| 5 | Busca | Ao buscar pela Home, o catálogo filtrava, mas o campo ficava vazio e sem botão de limpar | O campo do catálogo só lia a busca uma vez (a tela fica viva no `IndexedStack`) | Sincroniza o campo sempre que a busca muda |
| 6 | Pedidos (privacidade) | Um cliente via os pedidos de todos os outros | O pedido não guardava o dono | O pedido registra o e-mail do cliente; a aba Pedidos lista só os do usuário conectado |
| 7 | Painel admin › Editar produto | Editar um produto criava uma **cópia** em vez de atualizar | `upsertProduct` convertia o id para maiúsculas (ids reais são minúsculos) | Mantém o id original |
| 8 | Finalizar compra | Cupom aplicado continuava valendo após mudanças no carrinho | Sem revalidação ao finalizar | Revalida o cupom em `placeOrder` |
| 9 | Inicialização | O aviso "dados restaurados" nunca aparecia | A mensagem era apagada na primeira gravação | Aviso único exibido ao abrir o app |
| 10 | Checkout | "Cartão até 6x sem juros" | Texto inventado | O site informa **12x com juros de 1,99% a.m.** |
| 11 | Checkout | O preço à vista no Pix do site não era aplicado | Inexistente | Desconto Pix por produto, conforme o site, aplicado no total e no pedido |
| 12 | Ajuda | Atendente "Mariana · Online · responde em 2 min" e FAQ com dados inventados | Conteúdo fictício | O chat se identifica como assistente automático; FAQ e políticas vêm do site |
| 13 | Login | Falha no `flutter pub get` nesta máquina | `pubspec` exigia Dart 3.13.3, e o instalado é 3.13.2 | Restrição ajustada para `^3.9.0` |
| 14 | Senhas | O hash não usava sal por usuário | O e-mail era ignorado no hash | Sal pelo e-mail; contas antigas continuam entrando |

## 2. Funcionalidades adicionadas

- **Catálogo real**: 24 produtos, 6 categorias, preços, preço no Pix, parcelamento, voltagens, medidas, garantia, vídeo e link para o site. Tudo é lido de `assets/data/santigrill.json`, sem nenhum preço no código.
- **Fotos reais**: 69 imagens otimizadas (≤ 800 px, < 150 KB), com galeria deslizante, animação Hero, cache no tamanho exibido e placeholder.
- **Identidade visual**: logo oficial, vermelho `#d10d0d` do CSS do site e fonte Open Sans embutida.
- **Fale com a SantiGrill**: botões de WhatsApp com mensagem pronta, ligação, e-mail, mapa e Facebook; horário, endereço, CNPJ e políticas de pagamento, entrega, garantia, trocas e segurança.
- **Escolha de voltagem** (127V/220V), gravada no carrinho e no pedido.
- **"Dúvidas no WhatsApp"** na página do produto, já com o nome do produto na mensagem.
- **Busca melhor**: ignora acentos e aceita vários termos.
- **Migração automática**: aparelhos com o catálogo antigo recebem o novo sem travar; carrinho e favoritos inválidos são limpos.
- Avaliações, selos e números inventados foram removidos.

## 3. Checklist de testes

| Área | Teste | Resultado |
|---|---|---|
| Telas | As 35 telas abrem sem exceção em 320×568 e 430×932 (`screens_smoke_test`) | ✅ 70/70 |
| Catálogo | 24 produtos com id único, preço > 0, categoria válida | ✅ |
| Catálogo | Todas as imagens existem e têm < 150 KB; logo presente | ✅ |
| Catálogo | Dados da empresa, WhatsApp internacional, políticas e FAQ | ✅ |
| Carrinho | Limite ao estoque, cupom válido/inválido, recálculo ao alterar/remover | ✅ |
| Carrinho | Produto esgotado não entra | ✅ |
| Pagamento | Desconto Pix igual ao do site; cartão sem desconto | ✅ |
| Pedido | Cria pedido, baixa estoque, grava foto e voltagem; carrinho vazio é bloqueado | ✅ |
| Busca | Sem acento, vários termos, categoria + ordenação por preço | ✅ |
| Conta | Login válido/inválido, cadastro, redefinição de senha | ✅ |
| Privacidade | Cliente vê só os próprios pedidos; admin vê todos | ✅ |
| Admin | Orçamento respondido, status com linha do tempo, categoria com produtos não é removida | ✅ |
| Persistência | Sessão, carrinho, voltagem e favoritos sobrevivem ao reinício | ✅ |
| Persistência | Dados antigos migrados; dados corrompidos restaurados com aviso | ✅ |
| Visual | Capturas em `docs/screenshots/` revisadas (início, catálogo, produto, carrinho, checkout, pedidos, ajuda, contato) | ✅ |
| Sem internet | O app funciona offline. WhatsApp, mapa, vídeo e site mostram um aviso se não abrirem | ✅ por código; não testado em aparelho |
| Aparelho real | Rodar no emulador ou celular Android | ⚠️ Não executado: o emulador `Pixel_7` não inicia nesta máquina |

Para regenerar as capturas:

```
flutter test tool/screenshots_test.dart --update-goldens
```

## 4. Comparação com os requisitos (RF01–RF18)

| Requisito | Situação |
|---|---|
| RF01 Cadastro, RF02 Login, RF04 Consulta, RF05 Detalhe, RF06 Carrinho, RF07 Cupons, RF08 Compra, RF09 Orçamento, RF10 Histórico, RF12–RF17 Administração | Atendidos localmente |
| RF03 Recuperação de senha | Parcial: redefine no aparelho, sem envio de código por e-mail (depende do servidor) |
| RF11 Chat | Parcial: respostas automáticas no app, mais o atalho para o WhatsApp real. Chat em tempo real depende do servidor |
| RF14 Excluir usuário | Parcial: bloquear/alterar perfil existe; excluir não |
| RF18 E-mails automáticos | Não atendido (depende de servidor de e-mail) |

## 5. Segunda etapa: funcionalidades novas (12/11/2026)

| # | Funcionalidade | Situação | Como foi verificado |
|---|---|---|---|
| 1 | Notificações de status do pedido | ✅ Notificação do sistema ao sincronizar (status, resposta de orçamento, novo pedido para o admin). Com o app fechado, falta push remoto (Firebase) | `sync_test`, `e2e_api_test` |
| 2 | Pedido e orçamento pelo WhatsApp | ✅ Botão com resumo pronto (itens, voltagem, total, endereço) | `features_test` |
| 3 | Modo escuro | ✅ Sistema, claro ou escuro, em Perfil › Aparência | Todas as telas testadas no escuro; capturas 09 e 10 |
| 4 | Frete real pelos Correios | ✅ Integração com a API oficial pronta, mas **exige contrato** (credenciais no `.env`). Sem contrato: estimativa PAC/SEDEX por região, sinalizada. Endereço preenchido pelo CEP (ViaCEP) | `api.test.js`, `sync_test` |
| 5 | API Node/MongoDB e sincronização | ✅ JWT, pedidos com preço e estoque validados no servidor, fila offline com reenvio sem duplicar | 17 testes da API e teste de ponta a ponta app + API |
| 6 | Foto de produto (câmera/galeria) | ✅ Upload para a API; offline, a foto fica no aparelho | `api.test.js` (upload); seleção não testada em aparelho |
| 7 | Senha por código no e-mail | ✅ Código de 6 dígitos, 15 min, 5 tentativas (completa o RF03). Envio real exige SMTP no `.env` | `api.test.js`, `sync_test` |

Também entraram: excluir conta de usuário (RF14), selo de pedido pendente/recusado com reenvio e "puxar para atualizar".

Bugs encontrados nesta etapa: o checkout offline notificava o estado durante a construção da tela; sincronizações simultâneas descartavam a segunda chamada; o merge de orçamentos apagava orçamentos ainda não enviados; o estado podia ser notificado após o descarte; e o APK de release não tinha a permissão de INTERNET. Todos corrigidos e cobertos por teste.

## 6. Sem depender da SantiGrill (alternativas gratuitas)

| Antes dependia de | Solução gratuita adotada | Limitação |
|---|---|---|
| Firebase (push) | Verificação em segundo plano do Android (WorkManager) a cada ~15 min | Intervalo mínimo de 15 min; no iOS, só com o app aberto |
| Contrato dos Correios | Estimativa PAC/SEDEX por região, sinalizada; integração oficial pronta para o futuro | Valor aproximado |
| Conta de e-mail (SMTP) | Caixa de teste Ethereal (sem cadastro), com link no app | E-mails não chegam a caixas reais |
| Hospedagem com HTTPS | `npm run demo` (MongoDB local, sem Docker) + `npm run demo:tunnel` (Cloudflare, sem conta) | O computador precisa ficar ligado; o endereço muda a cada execução |

Verificado nesta máquina: `npm run demo` subiu o MongoDB local, e o e-mail de recuperação foi entregue na caixa Ethereal com o código. O túnel não foi aberto daqui, porque a exposição pública precisa da sua autorização. Basta rodar `npm run demo:tunnel`.

## 7. Pendências da primeira etapa (atualizadas)

1. ~~**Frete**~~: resolvido na segunda etapa. API dos Correios integrada (depende de contrato); sem contrato, estimativa PAC/SEDEX sinalizada.
2. **Estoque**: o site não publica estoque. O app começa com 10 unidades por produto, ajustáveis no painel.
3. **Cupom `PRIMEIRACOMPRA`** e o banner "10% na primeira compra" são da demonstração: o site informa "nenhum cupom disponível". Confirmar com a SantiGrill ou trocar.
4. **Horário de atendimento** diverge no site: 7:30–17:30 no rodapé e 8:00–16:30 na página de trocas. Usei o do rodapé.
5. **Endereço** sem número no site (Rua Caiapós, Santo André). A página "Sobre a empresa" está vazia no site.
6. **Logo** só existe em JPG com fundo vermelho. Uma versão com fundo transparente melhoraria telas claras.
7. **Endereços e chat** ainda são compartilhados entre contas do mesmo aparelho (pedidos já foram isolados).
8. ~~**Sincronização entre aparelhos**~~: resolvido na segunda etapa (API Node/MongoDB).
9. ~~**Fotos de produtos novos**~~: resolvido na segunda etapa (câmera/galeria com upload).
