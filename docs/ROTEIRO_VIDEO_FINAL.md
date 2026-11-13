# Roteiro do vídeo — entrega final

## LeadSystem — SantiGrill

- **Duração planejada:** cerca de 11 minutos (limite de 15)
- **Onde gravar:** emulador Android **Pixel 7** no PC, gravado com **Win + Alt + R**, já com o microfone
- **Apresentador:** Leandro
- **Objetivo:** mostrar o aplicativo funcionando com o servidor e **comparar com a demonstração de 18/10/2026**

Durante o roteiro, os quadros **Novidade desde outubro** marcam os pontos que a atividade pede para comparar. Fale essas frases com calma: são a parte mais importante do vídeo.

---

## Preparação (antes de apertar o gravar)

1. **Ligar o emulador** (terminal 1):

   ```bash
   flutter emulators --launch Pixel_7
   ```

2. **Subir o servidor de demonstração** (terminal 2, deixe aberto durante todo o vídeo):

   ```bash
   cd server && npm run demo
   ```

   Espere aparecer o endereço da API. Na primeira vez, ele baixa o MongoDB local (cerca de 70 MB).

3. **Rodar o app no emulador** (terminal 3):

   ```bash
   flutter run -d emulator-5554
   ```

4. No app, abra **Perfil > Servidor e sincronização**, informe `http://10.0.2.2:3000` e toque em **Testar e conectar**. Precisa aparecer **Conectado**.
5. Deixe o emulador com a **tela inicial** aberta e o tema claro.
6. No Windows, ative o **Não perturbe** e feche janelas com dados pessoais.
7. Tenha à mão:
   - cliente de demonstração: `carlos@email.com` / `Cliente@2026`;
   - administrador: botão **Entrar com a conta administrativa** (`leandro@email.com` / `Santi@2026`);
   - conta nova para o vídeo: **Ana Teste**, `ana.teste@email.com`, telefone `(11) 99999-0000`, senha `Senha@2026` e depois `Nova@2026`;
   - CEP público para o endereço: `01001000` (Praça da Sé), número `100`;
   - cupom: `PRIMEIRACOMPRA`.
8. Faça **um ensaio completo** antes. Se a Ana já tiver sido cadastrada no ensaio, use outro e-mail, por exemplo `ana.teste2@email.com`.

---

## Sequência resumida

| Tempo | Parte | Destaque |
|---|---|---|
| 00:00–00:30 | Abertura | Grupo, empresa e objetivo do vídeo |
| 00:30–01:00 | Servidor conectado | **Novo:** API com MongoDB |
| 01:00–02:00 | Cadastro | Validações e conta criada no servidor |
| 02:00–03:00 | Senha por código | **Novo:** código de 6 dígitos por e-mail |
| 03:00–04:10 | Catálogo e produto | **Novo:** catálogo real, Pix, voltagem, PAC e SEDEX |
| 04:10–05:00 | Orçamento | Protocolo e envio pelo WhatsApp |
| 05:00–06:30 | Compra | Cupom, CEP que preenche o endereço, pedido |
| 06:30–07:10 | Meus pedidos | **Novo:** cada cliente vê só os seus |
| 07:10–07:50 | Atendimento e aparência | **Novo:** Fale com a SantiGrill e modo escuro |
| 07:50–09:40 | Painel administrativo | Etapa do pedido, resposta ao orçamento, produto com foto |
| 09:40–10:20 | De volta ao cliente | Linha do tempo atualizada pela empresa |
| 10:20–11:00 | Encerramento | Comparação com outubro e próximos passos |

O bloco **Sem internet** (opcional, cerca de 1 minuto) pode entrar depois de **Meus pedidos**, se o ensaio couber em 13 minutos.

---

## 1. Abertura — 00:00 a 00:30

**Mostrar:** a tela inicial do app no emulador.

**Fala:**

> Olá, eu sou o Leandro e este é o vídeo da entrega final do LeadSystem, projeto de extensão do grupo formado por mim, João Pedro Ribeiro e Kaio Gabriel Mendes Lopes, para a SantiGrill, fabricante de churrasqueiras e grills giratórios de Santo André. Na primeira demonstração, em outubro, o aplicativo guardava tudo só no celular. Agora ele funciona com um servidor e com os dados reais da empresa, e é isso que vou mostrar, comparando com a versão anterior.

## 2. Servidor conectado — 00:30 a 01:00

**Ações:**

1. Abrir **Perfil > Servidor e sincronização**.
2. Mostrar **Conectado** e a última sincronização.

**Fala:**

> Este aplicativo está ligado a uma API em Node.js com banco MongoDB, que roda aqui no computador em modo de demonstração, só com ferramentas gratuitas. O servidor é a fonte oficial de preços, estoque, pedidos e orçamentos.

> **Novidade desde outubro:** em outubro não havia servidor; cada celular tinha seus próprios dados.

## 3. Cadastro — 01:00 a 02:00

**Ações:**

1. Voltar ao **Perfil**, abrir o acesso e tocar em **Ainda não tem conta? Criar conta**.
2. Tocar em **Criar conta** com os campos vazios e mostrar as mensagens.
3. Digitar a senha `senha123` e mostrar que ela é recusada.
4. Preencher a Ana com a senha `Senha@2026`, marcar o aceite da política e criar a conta.

**Fala:**

> O cadastro exige nome e sobrenome, e-mail válido, telefone com DDD e senha com oito caracteres, uma letra maiúscula e um número. Sem o aceite da política de privacidade, a conta não é criada. Com o servidor conectado, a conta é criada no banco de dados, e não só no aparelho.

## 4. Recuperação de senha por código — 02:00 a 03:00

**Ações:**

1. Sair da conta (**Perfil > Sair**).
2. No login, tocar em **Esqueci minha senha**, informar o e-mail da Ana e tocar em **Enviar código**.
3. Mostrar o aviso: *“Se o e-mail estiver cadastrado, enviaremos um código em instantes.”*
4. Tocar em **Abrir e-mail de teste**. O e-mail abre no navegador do emulador; mostrar o código de 6 dígitos.
5. Voltar ao app, digitar o código e a nova senha `Nova@2026` e tocar em **Atualizar senha**.
6. Entrar com a nova senha.

**Fala:**

> Para recuperar a senha, o servidor envia um código de seis dígitos para o e-mail. Ele vale por quinze minutos e é invalidado depois de cinco tentativas erradas. A resposta é sempre a mesma, exista ou não a conta, para não revelar quem está cadastrado. Na demonstração, os e-mails vão para uma caixa de testes gratuita.

> **Novidade desde outubro:** antes, a senha era trocada no próprio aparelho, sem confirmar a identidade.

## 5. Catálogo e produto — 03:00 a 04:10

**Ações:**

1. Abrir **Catálogo** e buscar `grelha`; trocar a categoria e a ordenação.
2. Abrir um **grill giratório elétrico** (tem escolha de voltagem).
3. Mostrar as fotos, o preço, o **preço no Pix** e o parcelamento, e escolher **127V** ou **220V**.
4. Rolar até **Calcule o frete**, digitar `0978-000` e mostrar que o cálculo não é feito; depois `01001000` e tocar em **Calcular**.
5. Mostrar os botões **Ver vídeo**, **Ver no site** e **Dúvidas no WhatsApp** (não precisa abrir).

**Fala:**

> O catálogo agora tem os 24 produtos reais do site da SantiGrill, com fotos, preços, preço no Pix, especificações e medidas publicados pela empresa. A busca ignora acentos e maiúsculas. O frete precisa de um CEP com oito dígitos; com o servidor, ele é cotado pela API, como estimativa para PAC e SEDEX, porque o contrato com os Correios é pago.

> **Novidade desde outubro:** os produtos eram de exemplo; agora são os da loja da empresa.

## 6. Orçamento — 04:10 a 05:00

**Ações:**

1. No mesmo produto, tocar em **Solicitar orçamento**. Os dados da Ana já vêm preenchidos.
2. Escrever só `quero` nos detalhes e tocar em **Enviar orçamento**; mostrar a mensagem.
3. Escrever `10 unidades para um evento em dezembro` e enviar.
4. Mostrar a confirmação com o **protocolo** e o botão **Enviar no WhatsApp**. Tocar em **Ver orçamento**.

**Fala:**

> O orçamento era o principal problema da empresa: hoje ele acontece todo no WhatsApp, sem registro. No LeadSystem, cada pedido de orçamento ganha um protocolo e um status, e chega ao painel da empresa. O WhatsApp continua disponível, mas agora a conversa já começa com o protocolo.

## 7. Compra — 05:00 a 06:30

**Ações:**

1. Voltar ao produto e adicionar ao carrinho; adicionar outro produto pelo catálogo.
2. Abrir o carrinho, aplicar `PRIMEIRACOMPRA` e mostrar subtotal, desconto, frete e total.
3. Tocar em **Ir para pagamento**.
4. No endereço, digitar o CEP `01001000`: rua, bairro, cidade e UF são preenchidos automaticamente. Completar o número `100`.
5. Escolher **SEDEX** e depois **Pix**; mostrar o desconto à vista no resumo.
6. Aceitar os termos e tocar em **Finalizar pedido**.
7. Mostrar **Pedido realizado!** com o número do pedido.

**Fala:**

> O carrinho limita a quantidade ao estoque e aplica o cupom só se ele estiver válido. O endereço é preenchido pelo CEP usando o serviço gratuito ViaCEP. No Pix, entra o preço à vista publicado pela empresa. Quando o pedido chega ao servidor, a API refaz todos os cálculos com os preços do banco e baixa o estoque, mesmo que dois clientes comprem ao mesmo tempo. O pagamento é só registrado: não há cobrança real nesta versão.

## 8. Meus pedidos — 06:30 a 07:10

**Ações:**

1. Tocar em **Acompanhar pedido** e mostrar a linha do tempo com **Pedido recebido**.
2. Abrir a aba **Pedidos** e mostrar o pedido e o orçamento da Ana.

**Fala:**

> Em Pedidos, a Ana vê só os pedidos e orçamentos dela, e o servidor também só devolve os dela.

> **Novidade desde outubro:** antes, contas diferentes no mesmo celular viam os mesmos pedidos.

## 8.1 Sem internet (opcional) — cerca de 1 minuto

**Ações:**

1. No terminal 2, parar o servidor com **Ctrl + C** (pode mostrar o terminal rapidamente).
2. No app, fazer um pedido pequeno com Pix. Ele aparece com o aviso **Aguardando envio ao servidor**.
3. Subir o servidor de novo com `npm run demo`.
4. Em **Perfil > Servidor e sincronização**, tocar em **Sincronizar agora** e mostrar que o pedido foi enviado.

**Fala:**

> Se a internet cair, o aplicativo continua funcionando: o pedido fica numa fila no aparelho e é enviado sozinho quando a conexão volta, uma única vez, sem duplicar.

## 9. Atendimento e aparência — 07:10 a 07:50

**Ações:**

1. Abrir **Perfil > Fale com a SantiGrill** e mostrar WhatsApp, telefones, endereço e horário.
2. Abrir **Ajuda**, enviar `Qual o prazo de entrega?` e mostrar a resposta automática.
3. Abrir **Perfil > Aparência**, escolher **Escuro** e voltar à tela inicial; depois voltar para **Claro**.

**Fala:**

> A tela Fale com a SantiGrill reúne os contatos oficiais da empresa. A ajuda traz as políticas publicadas no site e um assistente automático; para falar com uma pessoa, o cliente segue pelo WhatsApp. O aplicativo também tem modo escuro, e passou por uma auditoria de acessibilidade: botões com área de toque adequada e rótulos para leitores de tela.

## 10. Painel administrativo — 07:50 a 09:40

**Ações:**

1. **Perfil > Sair**. No login, tocar em **Entrar com a conta administrativa**.
2. **Perfil > Abrir painel administrativo**: mostrar pedidos pendentes, orçamentos novos e estoque baixo.
3. Abrir o pedido da Ana em **Pedidos recentes**, escolher **Em preparação**, escrever `Separando os produtos` e tocar em **Atualizar pedido**. Mostrar o novo evento no histórico.
4. Abrir **Orçamentos**, o protocolo da Ana, escolher **Respondido**, escrever `Podemos atender: entrega em 5 dias úteis.` e tocar em **Salvar e responder**.
5. Abrir **Produtos > Novo produto**, tocar em **Cadastrar produto** vazio e mostrar as validações; mostrar o campo de foto (câmera ou galeria) e voltar sem salvar.

**Fala:**

> O administrador vê o resumo da loja. Ao mudar a etapa de um pedido, o evento entra na linha do tempo e o cliente recebe e-mail e notificação. Para responder um orçamento, a resposta é obrigatória. No cadastro de produtos, nada é salvo sem SKU, nome, descrição, preço e estoque válidos, e a foto pode vir da câmera do celular.

## 11. De volta ao cliente — 09:40 a 10:20

**Ações:**

1. **Perfil > Sair** e entrar de novo como Ana (`Nova@2026`).
2. Abrir **Pedidos** e o pedido: mostrar **Em preparação** com a observação.
3. Abrir o orçamento e mostrar a resposta da empresa.
4. Se aparecer uma notificação na barra do emulador, mostrar; se não, siga sem comentar.

**Fala:**

> De volta à conta da Ana, o pedido já mostra a etapa registrada pela empresa, e o orçamento tem a resposta. Tudo passou pelo servidor: é o mesmo que aconteceria com o cliente e a empresa em celulares diferentes.

## 12. Encerramento — 10:20 a 11:00

**Mostrar:** a tela inicial.

**Fala:**

> Comparando com outubro: o aplicativo saiu de dados só no celular para um servidor com MongoDB, ganhou o catálogo real da SantiGrill, recuperação de senha por e-mail, pedidos separados por cliente, notificações, contato pelo WhatsApp e modo escuro, e passou de 8 para 171 testes automatizados, além de 17 testes na API. Ainda faltam pagamento real, frete por contrato com os Correios e a validação com a empresa e com clientes, que faremos na demonstração de 1º de dezembro. Obrigado.

---

## Plano de contingência

- **“Já existe uma conta com este e-mail”:** use `ana.teste2@email.com` (ou outro número no final).
- **O e-mail de teste não abre:** mostre o aviso de envio e siga para o login com o Carlos; fale do código sem mostrá-lo.
- **O CEP não preenche o endereço:** o emulador está sem internet; preencha à mão e siga.
- **O servidor caiu:** o app continua em modo offline; termine o roteiro e explique a fila de sincronização.
- **Algo deu muito errado:** pare e grave de novo do começo; é melhor do que editar.
- **Não mostre** senhas pessoais, e-mails reais nem notificações do seu computador.

## Checklist da entrega

- [ ] O vídeo tem no máximo 15 minutos.
- [ ] O grupo, a SantiGrill e o objetivo foram apresentados.
- [ ] O servidor aparece conectado no começo.
- [ ] As comparações com outubro foram faladas (servidor, senha, catálogo, pedidos por cliente, testes).
- [ ] O cliente e o painel administrativo foram mostrados.
- [ ] Os limites foram ditos (pagamento simulado, frete estimado, validação com a empresa pendente).
- [ ] O áudio está claro e a tela do emulador está legível.
- [ ] O link do vídeo foi testado numa janela anônima, com permissão de visualização.

## Texto para a descrição do vídeo

> Entrega final do projeto de extensão LeadSystem — SantiGrill (USCS, 2026). Demonstração do aplicativo em Flutter conectado à API em Node.js com MongoDB, com comparação com a versão apresentada em outubro de 2026. Código-fonte: https://github.com/Ribbeiro/LeadSystem
