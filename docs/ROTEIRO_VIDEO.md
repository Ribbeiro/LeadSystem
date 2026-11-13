# Roteiro completo do vídeo — primeira entrega do projeto de extensão

## LeadSystem — SantiGrill

- **Duração planejada:** 14 minutos e 50 segundos
- **Limite da atividade:** 15 minutos
- **Formato sugerido:** gravação contínua da tela do celular, sem edição e com explicação falada
- **Apresentador:** um integrante do grupo pode conduzir todo o vídeo

O roteiro foi escrito de acordo com o estado atual do projeto. Durante todo o vídeo, deve aparecer somente o LeadSystem funcionando no celular. A explicação técnica será falada enquanto o apresentador navega pelo aplicativo; não é necessário mostrar VS Code, código-fonte, banco de dados ou editar a gravação.

## Preparação antes de gravar

1. Carregue o celular e ative o modo **Não perturbe** para evitar notificações pessoais.
2. Deixe o LeadSystem instalado e teste sua abertura antes da gravação.
3. Confirme que há pelo menos um produto com estoque disponível.
4. Use a conta de cliente preparada para agilizar a demonstração:
   - e-mail: `carlos@email.com`
   - senha: `Cliente@2026`
5. Use um endereço fictício e não mostre dados pessoais reais.
6. Para demonstrar o cupom, use `PRIMEIRACOMPRA`.
7. Para o painel administrativo, use a conta acadêmica de demonstração:
   - e-mail: `leandro@email.com`
   - senha: `Santi@2026`
8. Antes de começar, deixe a tela inicial do aplicativo aberta e feche outros aplicativos.
9. Faça um ensaio cronometrado. O roteiro usa 14 minutos e 50 segundos; fale de forma objetiva para não ultrapassar o limite.
10. Depois de enviar o vídeo, teste o link em uma janela anônima para confirmar que o professor possui acesso.

## Sequência resumida

| Tempo | Parte | O que mostrar |
|---|---|---|
| 00:00–00:35 | Abertura | Grupo, empresa e nome do projeto |
| 00:35–01:10 | Problema e objetivo | Necessidade atendida pelo LeadSystem |
| 01:10–01:50 | Visão geral | Início, navegação e categorias |
| 01:50–03:25 | Acesso | Validações do login, cadastro e recuperação |
| 03:25–04:35 | Catálogo | Busca, produto, favorito e validação do CEP |
| 04:35–05:30 | Orçamento | Campo obrigatório, envio e protocolo |
| 05:30–07:45 | Compra | Carrinho, cupom, pagamento, validações e pedido |
| 07:45–08:30 | Pós-venda | Histórico e acompanhamento do pedido |
| 08:30–10:15 | Perfil | Endereço, notificações, conta e segurança |
| 10:15–10:55 | Atendimento | Busca, mensagem vazia e resposta automática |
| 10:55–14:25 | Administração | Gestão, formulários obrigatórios e status |
| 14:25–14:50 | Encerramento | Estado atual e benefícios do aplicativo |

---

## 1. Abertura — 00:00 a 00:35

### Mostrar

- Tela inicial do LeadSystem aberta no celular.
- Manter a tela inicial visível enquanto os integrantes são apresentados oralmente.

### Fala sugerida

> Olá, somos o grupo responsável pelo projeto de extensão LeadSystem, desenvolvido para a SantiGrill. Nesta primeira entrega mostraremos o aplicativo funcionando, suas principais telas, os campos obrigatórios, as validações e o resultado de cada operação. O projeto foi desenvolvido em Flutter para Android e também está preparado para iOS.

Não gaste tempo lendo números de matrícula se eles já estiverem escritos na tela. Diga apenas os nomes dos integrantes de maneira objetiva.

## 2. Problema e objetivo — 00:35 a 01:10

### Mostrar

- Ainda na tela inicial, deslizar lentamente pelos destaques, categorias e produtos.

### Fala sugerida

> A proposta surgiu da necessidade de reunir em um único sistema o catálogo, o processo de compra, as solicitações de orçamento, o atendimento ao cliente e as rotinas administrativas da empresa. O LeadSystem permite que o cliente encontre produtos, calcule a entrega, compre ou solicite um orçamento. Ao mesmo tempo, oferece à administração recursos para controlar produtos, estoque, pedidos, usuários, cupons e campanhas.

## 3. Visão geral da aplicação — 01:10 a 01:50

### Ações na tela

1. Mostrar o banner promocional da página inicial.
2. Deslizar pelas categorias.
3. Tocar em uma categoria e mostrar que o catálogo é filtrado.
4. Apontar a navegação inferior: **Início**, **Catálogo**, **Pedidos**, **Ajuda** e **Perfil**.

### Fala sugerida

> Esta é a área inicial do cliente. Ela apresenta campanhas, atalhos de categorias e produtos do catálogo. A navegação inferior mantém as principais áreas sempre acessíveis. Ao selecionar uma categoria, o sistema direciona o usuário ao catálogo já filtrado, reduzindo o número de passos necessários para encontrar um produto.

## 4. Login, cadastro e recuperação — 01:50 a 03:25

### Ações na tela

1. Abrir **Perfil** e entrar na área de acesso.
2. Com **E-mail** e **Senha** vazios, tocar em **Entrar**. Mostrar `Digite um e-mail válido` e `A senha deve ter ao menos 8 caracteres`.
3. Digitar um e-mail sem `@` ou uma senha curta para mostrar que formatos inválidos também são recusados.
4. Abrir **Criar conta**. Inicialmente, mostrar que o botão permanece desabilitado até aceitar a Política de Privacidade.
5. Marcar o aceite e tocar em **Criar conta** com os campos vazios. Mostrar as mensagens de nome e sobrenome, e-mail completo, telefone com DDD e senha forte.
6. Explicar que a senha exige no mínimo 8 caracteres, uma letra maiúscula e um número. Voltar sem criar outra conta.
7. Abrir **Esqueci minha senha**, tentar atualizar sem dados e mostrar as validações de e-mail e nova senha. Cancelar.
8. Entrar com `carlos@email.com` e `Cliente@2026` para continuar o fluxo como cliente.

### Fala sugerida

> O aplicativo possui cadastro, autenticação, sessão persistente e recuperação de senha. Ao tentar continuar sem preencher os campos, o sistema não envia dados incompletos: destaca cada caixa com problema e explica como corrigi-la. No cadastro, nome e sobrenome, e-mail completo, telefone com DDD, senha forte e aceite da Política de Privacidade são obrigatórios. Depois da validação, entraremos com uma conta de cliente já preparada.

### Dica de tempo

Não cadastre um usuário completo durante a gravação. Mostrar os erros, explicar as regras e entrar com a conta preparada demonstra tanto a prevenção de erros quanto o fluxo de sucesso.

## 5. Catálogo e detalhes do produto — 03:25 a 04:35

### Ações na tela

1. Abrir **Catálogo**.
2. Pesquisar uma palavra presente no nome de um produto.
3. Usar um filtro de categoria e alterar a ordenação.
4. Abrir um produto.
5. Mostrar imagem, descrição, preço, avaliação, especificações e estoque.
6. Marcar o produto como favorito.
7. Tentar calcular a entrega com o CEP vazio ou incompleto. Mostrar a mensagem `Digite os 8 números do CEP`.
8. Informar um CEP válido, com 8 números, e mostrar a estimativa de entrega.
9. Adicionar o produto ao carrinho.

### Fala sugerida

> O catálogo permite pesquisar, filtrar e ordenar os produtos. Na página de detalhes, o cliente encontra preço, especificações e disponibilidade em estoque. Também pode salvar o item nos favoritos. O CEP é obrigatório para calcular a entrega; se estiver incompleto, o aplicativo informa que são necessários oito números. Com um CEP válido, o prazo e o custo estimados são exibidos. O carrinho também impede quantidades superiores ao estoque.

Não diga que o CEP consulta uma transportadora ou serviço externo. Nesta versão, ele é validado e usado em uma estimativa local de prazo e custo.

## 6. Solicitação de orçamento — 04:35 a 05:30

### Ações na tela

1. Na página do produto, abrir **Solicitar orçamento**.
2. Como o cliente está autenticado, mostrar que nome, telefone e e-mail já aparecem preenchidos.
3. Tocar em **Enviar** sem preencher **Detalhes da solicitação** e mostrar a mensagem que solicita quantidade e necessidade do orçamento.
4. Explicar que nome, telefone e e-mail também são validados caso estejam ausentes ou incorretos.
5. Preencher os detalhes com pelo menos 10 caracteres, por exemplo `Preciso de 20 unidades para um evento`, e enviar.
6. Mostrar a confirmação e o número de protocolo.

### Fala sugerida

> Para compras personalizadas ou em maior quantidade, o cliente pode solicitar um orçamento. Nome, telefone, e-mail e uma descrição com a quantidade e a necessidade são obrigatórios. Como estamos autenticados, os dados de contato são reaproveitados, mas continuam sendo validados. Após o envio correto, o sistema gera um protocolo persistente, que aparece no histórico do cliente e no painel administrativo.

Guarde o número do protocolo visualmente, pois ele poderá ser mostrado novamente na administração.

## 7. Carrinho e finalização da compra — 05:30 a 07:45

### Ações na tela

1. Abrir o carrinho.
2. Alterar a quantidade de um item.
3. Se houver outro produto, mostrar mais de um item no carrinho.
4. Aplicar o cupom `PRIMEIRACOMPRA`.
5. Mostrar subtotal, desconto, entrega e total.
6. Tocar em **Finalizar compra**.
7. Mostrar o endereço previamente salvo e explicar que rua, número, bairro, CEP, cidade e UF são obrigatórios.
8. Desmarcar **Confirmo os dados do pedido e aceito os termos** e mostrar que o botão de finalizar fica desabilitado.
9. Selecionar **Cartão**, deixar seus campos vazios e tentar finalizar após aceitar os termos. Mostrar as validações de número, nome no cartão e CVV.
10. Explicar que o número deve possuir ao menos 13 dígitos e o CVV ao menos 3.
11. Para agilizar, voltar para **Pix**, manter o endereço válido, aceitar os termos e finalizar.
12. Mostrar a tela de sucesso e o número do pedido.

### Fala sugerida

> No carrinho, o usuário pode alterar quantidades ou remover produtos. O total é recalculado automaticamente e o sistema impede quantidades superiores ao estoque. Um cupom inexistente é recusado; o cupom PRIMEIRACOMPRA aplica o desconto e atualiza o resumo. No checkout, os dados de endereço são obrigatórios. Ao escolher cartão, número, nome do titular e CVV passam a ser obrigatórios. Sem aceitar os termos, o botão permanece desabilitado. Após corrigir os campos e escolher Pix, o sistema cria o pedido, registra os itens, reduz o estoque e mostra a confirmação.

Se quiser demonstrar a prevenção de erros, tente aumentar rapidamente uma quantidade até o limite do estoque e mostre o aviso. Não insista nessa etapa se o tempo estiver apertado.

## 8. Histórico e acompanhamento — 07:45 a 08:30

### Ações na tela

1. Abrir **Meus pedidos**.
2. Localizar o pedido recém-criado.
3. Abrir seus detalhes.
4. Tocar em **Acompanhar pedido**.
5. Mostrar a linha do tempo, o endereço e o estado atual.

### Fala sugerida

> O pedido criado fica disponível no histórico mesmo após fechar e abrir o aplicativo. Nos detalhes, o cliente consulta os produtos, valores, forma de pagamento e endereço. A área de acompanhamento apresenta uma linha do tempo com as etapas do pedido. Quando a administração altera o status, essa informação é refletida no acompanhamento local.

Se houver tempo, feche e abra o aplicativo antes desta parte para comprovar que o pedido continua salvo. Faça isso somente se tiver ensaiado e souber que a reabertura será rápida.

## 9. Perfil, endereço e segurança — 08:30 a 10:15

### Ações na tela

1. Abrir **Perfil**.
2. Mostrar **Favoritos** e confirmar que o item marcado anteriormente aparece na lista.
3. Abrir **Endereços**, tocar em adicionar e tentar salvar tudo vazio. Mostrar que identificação, CEP, rua, número, bairro, cidade e UF são obrigatórios; somente complemento é opcional. Cancelar o cadastro para economizar tempo.
4. Abrir **Notificações** e mostrar as preferências que podem ser ativadas ou desativadas.
5. Abrir **Minha conta**. Explicar que nome e sobrenome e telefone com DDD são validados, enquanto o e-mail identifica a conta e não pode ser alterado nessa tela.
6. Abrir **Alterar senha**, tentar confirmar sem preencher e mostrar as mensagens de senha atual, nova senha forte e confirmação coincidente. Cancelar sem alterar a senha preparada para o vídeo.
7. Mostrar rapidamente a Política de Privacidade e retornar.

### Fala sugerida

> No perfil, o cliente administra favoritos, endereços, notificações e dados pessoais. O cadastro de endereço impede o salvamento se faltar identificação, CEP, rua, número, bairro, cidade ou UF; apenas o complemento é opcional. Na conta, nome completo e telefone são validados. Para trocar a senha, é necessário informar a senha atual, criar outra com oito caracteres, letra maiúscula e número, e repetir exatamente a nova senha.

## 10. Ajuda e atendimento — 10:15 a 10:55

### Ações na tela

1. Abrir **Ajuda** pela navegação inferior.
2. Pesquisar uma dúvida e abrir uma resposta frequente.
3. Pesquisar um texto inexistente e mostrar a orientação para enviar a dúvida ao atendimento.
4. Tentar enviar a caixa de mensagem vazia e mostrar que nenhuma mensagem em branco é criada.
5. Digitar `Como acompanho meu pedido?` e mostrar a resposta automática relacionada ao histórico de pedidos.
6. Tocar em **Abrir um chamado** e mostrar a confirmação.

### Fala sugerida

> A central de ajuda reúne perguntas frequentes pesquisáveis. Quando não existe uma resposta pronta, o aplicativo orienta o cliente a conversar com o atendimento. A caixa não permite registrar mensagens vazias. Ao enviar uma pergunta válida, o atendimento automático local identifica o assunto e retorna uma orientação. Também é possível abrir um chamado e acompanhar a resposta na própria conversa.

## 11. Painel administrativo — 10:55 a 14:25

### Preparação

1. Sair da conta do cliente.
2. Na tela de login, tocar em **Entrar com a conta administrativa** ou usar:
   - `leandro@email.com`
   - `Santi@2026`
3. Abrir **Perfil > Painel administrativo**.

### Ações na tela

1. Mostrar os indicadores de pedidos, orçamentos e estoque baixo.
2. Abrir **Novo produto** e tocar em salvar sem preencher. Mostrar as validações de SKU, nomes, categoria, descrição, preço, estoque, avaliação e quantidade de avaliações. Explicar que selo promocional e especificações são opcionais. Voltar sem cadastrar.
3. Abrir **Criar cupom** e tocar em salvar vazio. Mostrar que código, descrição, desconto e compra mínima são validados. Explicar que limite de usos e expiração são opcionais; se houver limite, deve ser positivo, e o desconto deve ficar entre 1% e 100%. Voltar.
4. Abrir **Nova campanha**, tentar salvar vazia e mostrar as validações de título e mensagem. Explicar que, quando as datas forem usadas, o fim não pode ser anterior ao início. Voltar.
5. Mostrar **Pedidos recentes**, abrir o pedido criado no vídeo, alterar o status e mostrar o registro no histórico.
6. Abrir **Categorias** e explicar que o nome deve possuir ao menos 3 caracteres e não pode ser repetido. Mostrar que categorias com produtos não podem ser excluídas antes da reclassificação.
7. Abrir **Usuários** e mostrar consulta, alteração de perfil de acesso e bloqueio.
8. Abrir **Orçamentos**, localizar o protocolo criado, selecionar um status final sem resposta e mostrar que o sistema exige uma resposta clara. Depois escrever uma resposta com ao menos 8 caracteres e salvar.
9. Mostrar rapidamente **Produtos e estoque**, **Relatórios** e os controles de ativação e quantidade.

### Fala sugerida

> O painel administrativo utiliza os mesmos dados gerados no fluxo do cliente. Os formulários também evitam cadastros incompletos: um produto exige identificação, descrição, categoria e valores coerentes; um cupom exige regras válidas; e uma campanha exige título e mensagem. A administração pode consultar pedidos, registrar mudanças de status, controlar produtos e estoque, organizar categorias, gerenciar usuários e responder orçamentos. Um orçamento não pode ser concluído como respondido, aprovado ou recusado sem uma resposta clara ao cliente.

### Prioridade se o tempo estiver acabando

Mostre, nesta ordem: validação de produto, pedido criado, validação da resposta ao orçamento e indicadores. Se faltar tempo, apenas abra e cite categorias, usuários, cupons, campanhas e relatórios.

## 12. Encerramento — 14:25 a 14:50

### Mostrar

- Retornar ao aplicativo e deixar o painel ou a tela inicial visível.

### Fala sugerida

> Nesta primeira entrega, apresentamos o LeadSystem funcionando no celular. Demonstramos autenticação, validação dos campos obrigatórios, catálogo, favoritos, cálculo de entrega, orçamento, carrinho, cupom, checkout, pedidos, acompanhamento, perfil, suporte e administração. Quando faltam dados ou o formato está incorreto, o aplicativo impede a operação e informa exatamente o que deve ser corrigido. Os dados desta versão permanecem salvos no aparelho, permitindo o funcionamento offline. O sistema contribui para organizar vendas, atendimento e gestão da SantiGrill em uma única experiência. Obrigado pela atenção.

## Plano de contingência durante a gravação

- Grave diretamente a tela do celular; o aplicativo instalado não depende de manter o VS Code aberto.
- Se o cadastro informar que o e-mail já existe, use a conta preparada em vez de tentar corrigir isso durante o vídeo.
- Se o preenchimento do checkout demorar, use Pix e um endereço já salvo.
- Se estiver próximo dos 15 minutos, corte o preenchimento completo de cadastro e a visita detalhada a categorias, usuários, campanhas e relatórios.
- Como a proposta é uma gravação contínua e sem edição, se ocorrer um erro grave, encerre e inicie uma nova gravação desde o começo.
- Não mostre senhas pessoais, endereços reais ou notificações particulares do celular.

## Checklist final da entrega

- [ ] O vídeo possui no máximo 15 minutos.
- [ ] O nome LeadSystem e a SantiGrill foram apresentados.
- [ ] Os integrantes foram identificados.
- [ ] A gravação mostra somente a tela do aplicativo e a explicação falada.
- [ ] A aplicação real apareceu funcionando.
- [ ] As principais funções do cliente foram demonstradas.
- [ ] O painel administrativo foi demonstrado.
- [ ] Foram mostrados campos vazios ou inválidos e suas mensagens de correção.
- [ ] Login, cadastro, CEP, orçamento, checkout, endereço e formulários administrativos tiveram suas regras explicadas.
- [ ] A persistência local foi explicada brevemente, sem sair do aplicativo.
- [ ] Nenhum dado pessoal ou segredo apareceu na gravação.
- [ ] O áudio está compreensível e a tela pode ser lida.
- [ ] O link foi testado em uma janela anônima e possui permissão de visualização.

## Consulta rápida dos campos e validações

Esta tabela serve para o ensaio. Não é necessário lê-la palavra por palavra no vídeo; mostre o erro na tela e explique a regra de forma natural.

| Tela | Campos obrigatórios e regras | O que ocorre quando estão incorretos |
|---|---|---|
| Login | E-mail com `@`; senha com pelo menos 8 caracteres | Os campos ficam destacados e o acesso não é enviado; credenciais não cadastradas exibem `E-mail ou senha incorretos` |
| Cadastro | Nome e sobrenome; e-mail com `@` e ponto; telefone com DDD; senha com 8 caracteres, maiúscula e número; aceite da privacidade | O botão depende do aceite e o formulário informa a correção de cada caixa |
| Recuperar senha | E-mail válido de uma conta existente; nova senha forte | A atualização é impedida e a regra inválida aparece abaixo do campo |
| Cálculo de entrega | CEP com exatamente 8 números | A estimativa não é calculada e aparece `Digite os 8 números do CEP` |
| Orçamento | Nome; telefone; e-mail; detalhes com pelo menos 10 caracteres | O protocolo não é criado até todos os dados serem válidos |
| Checkout — endereço | Rua com pelo menos 3 caracteres; número; bairro; CEP com 8 números; cidade; UF com 2 letras | O pedido não é criado e cada dado inválido é destacado |
| Checkout — cartão | Número com pelo menos 13 dígitos; nome com pelo menos 3 caracteres; CVV com pelo menos 3 dígitos | Os erros aparecem somente quando `Cartão` é selecionado |
| Checkout — termos | Confirmação dos dados e aceite dos termos | O botão **Finalizar pedido** permanece desabilitado |
| Novo endereço | Identificação; CEP; rua; número; bairro; cidade; UF | O endereço não é salvo; **Complemento** é o único campo opcional |
| Minha conta | Nome e sobrenome; telefone com 10 ou 11 dígitos | As alterações não são salvas; o e-mail fica bloqueado para edição |
| Alterar senha | Senha atual; nova senha forte e diferente; confirmação idêntica | A troca é recusada e o diálogo informa senha ausente, fraca, repetida ou diferente da confirmação |
| Atendimento | Mensagem com algum conteúdo | Mensagens vazias são ignoradas e não aparecem na conversa |
| Novo produto | SKU único com 3 caracteres; nome com 4; nome curto com 3; categoria; descrição com 12; preço maior que zero; estoque não negativo; avaliação entre 0 e 5; número de avaliações não negativo | O produto não é salvo e os campos inválidos mostram suas regras; selo e especificações podem ser opcionais |
| Novo cupom | Código com 3 caracteres; descrição com 5; desconto entre 1% e 100%; compra mínima não negativa | O cupom não é salvo; limite e expiração são opcionais, mas o limite preenchido deve ser positivo |
| Nova campanha | Título com 4 caracteres; mensagem com 12 | A campanha não é salva; datas são opcionais, mas a data final não pode ser anterior à inicial |
| Categoria | Nome único com pelo menos 3 caracteres | Um nome curto ou vazio não é salvo; categoria repetida ou em uso não pode ser criada/excluída indevidamente |
| Responder orçamento | Resposta com pelo menos 8 caracteres ao marcar como respondido, aprovado ou recusado | O novo status não é concluído e aparece uma solicitação de resposta clara |

## Frase curta para a descrição do vídeo

> Apresentação da primeira entrega do projeto de extensão LeadSystem — SantiGrill. A gravação demonstra o aplicativo funcionando no celular, as funcionalidades do cliente e da administração e as validações aplicadas aos campos obrigatórios.
